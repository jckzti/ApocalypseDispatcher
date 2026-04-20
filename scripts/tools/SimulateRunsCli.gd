extends SceneTree

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const DailyChallengeService = preload("res://scripts/core/DailyChallengeService.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const SimulationRunner = preload("res://scripts/sim/SimulationRunner.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const BusUnit = preload("res://scripts/sim/BusUnit.gd")
const EvacuationOrder = preload("res://scripts/sim/EvacuationOrder.gd")
const RoutePlanner = preload("res://scripts/sim/RoutePlanner.gd")
const CardSystem = preload("res://scripts/sim/CardSystem.gd")
const ScoreSystem = preload("res://scripts/sim/ScoreSystem.gd")

const OUTPUT_DIR := "res://tmp/balance"

var _route_planner := RoutePlanner.new()


func _initialize() -> void:
	var scenario_id := _parse_arg("--scenario=", "campanha_01_cidade_cinza")
	var total_runs := int(_parse_arg("--runs=", "100"))
	var max_minutes := int(_parse_arg("--minutes=", "240"))
	var daily_key := _parse_optional_arg("--date=")
	var seed_start_arg := _parse_optional_arg("--seed-start=")
	var seed_start := 0 if seed_start_arg.is_empty() else int(seed_start_arg)
	var retire_at_wave := int(_parse_arg("--retire-at-wave=", "3"))

	var content_db = ContentDbScript.new()
	if not content_db.load_content("res://data"):
		for error_message in content_db.get_last_errors():
			printerr(error_message)
		content_db.free()
		quit(1)
		return

	var scenario_context := {}
	if not daily_key.is_empty():
		scenario_context["daily_key"] = daily_key
	var scenario_def = content_db.get_runtime_scenario(scenario_id, scenario_context)
	if scenario_def == null:
		printerr("Cenario nao encontrado: %s" % scenario_id)
		content_db.free()
		quit(1)
		return
	if seed_start <= 0:
		seed_start = DailyChallengeService.resolve_seed_for_scenario(scenario_def, 1000)

	var rows: Array = []
	var broken_seeds: Array = []
	for run_index in range(total_runs):
		var seed := seed_start + run_index
		var result := _simulate_single(content_db, scenario_def, seed, max_minutes, retire_at_wave)
		if not bool(result.get("ok", false)):
			broken_seeds.append(seed)
			continue
		rows.append(Dictionary(result.get("report", {})).duplicate(true))

	var summary := _build_summary(rows, scenario_def, total_runs, broken_seeds)
	var output_paths := _write_reports(scenario_id, rows, summary)

	print("Simulacao em lote concluida para %s." % scenario_def.name)
	print("Runs: %d | Sucesso: %d | Seeds quebradas: %d" % [total_runs, rows.size(), broken_seeds.size()])
	print("Score medio: %.2f | Salvos medios: %.2f | Mortos medios: %.2f" % [
		float(summary.get("average_score", 0.0)),
		float(summary.get("average_saved_population", 0.0)),
		float(summary.get("average_dead_population", 0.0)),
	])
	print("CSV: %s" % String(output_paths.get("csv", "")))
	print("JSON: %s" % String(output_paths.get("json", "")))

	content_db.free()
	quit(0)


func _simulate_single(content_db, scenario_def, seed: int, max_minutes: int, retire_at_wave: int) -> Dictionary:
	var runtime := _create_runtime(content_db, scenario_def, seed)
	var runner = runtime["runner"]
	var graph = runtime["graph"]
	var card_system = runtime["card_system"]
	var score_system = ScoreSystem.new()

	for _minute in range(max_minutes):
		_assign_orders_if_needed(runner, graph)
		_resolve_pending_event(runner, graph)
		_maybe_offer_cards(runner, scenario_def, card_system)
		_pick_card_if_available(runner, card_system)
		runner.advance(1)
		if _should_retire_infinite_run(runner.state, scenario_def, retire_at_wave):
			_retire_run(runner.state)
			break
		var end_state: Dictionary = score_system.evaluate_end_conditions(runner.state, scenario_def, graph)
		if bool(end_state.get("run_over", false)):
			break

	if _is_infinite_scenario(scenario_def) and not bool(runner.state.score_state.get("run_over", false)) and _can_retire_infinite_run(runner.state):
		_retire_run(runner.state)

	var report := score_system.evaluate_run(runner.state, scenario_def, graph, content_db)
	report["seed"] = seed
	return {"ok": true, "report": report}


func _create_runtime(content_db, scenario_def, seed: int) -> Dictionary:
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = seed
	var state = GameState.create_initial(run_config)
	state.run_flags["allowed_event_ids"] = scenario_def.allowed_event_ids.duplicate(true)
	state.run_flags["current_scenario_id"] = scenario_def.id

	var graph = CityGraph.new(content_db.get_map(scenario_def.map_id).to_dictionary())
	graph.apply_to_game_state(state)
	var modifier_stack = ModifierStack.new()
	var runner = SimulationRunner.new(run_config, state)
	runner.configure_runtime(graph, modifier_stack, null, null, null, null, content_db)
	for bus_data in scenario_def.starting_buses:
		var bus = BusUnit.new(bus_data)
		bus.current_district_id = _default_bus_start_district(graph)
		runner.state.bus_units[bus.id] = bus
	return {
		"runner": runner,
		"graph": graph,
		"card_system": CardSystem.new(content_db, modifier_stack, runner.rng),
	}


func _default_bus_start_district(graph) -> String:
	for district_id in graph.district_states.keys():
		var district = graph.get_district(String(district_id))
		if district != null and district.tags.has("terminal"):
			return district.id
	for district_id in graph.district_states.keys():
		var district = graph.get_district(String(district_id))
		if district != null and not district.is_shelter:
			return district.id
	return ""


func _assign_orders_if_needed(runner, graph) -> void:
	var bus_ids: Array = runner.state.bus_units.keys()
	bus_ids.sort()
	for bus_id in bus_ids:
		var bus = runner.state.bus_units[bus_id]
		if not bus.assigned_order_id.is_empty() and runner.state.evacuation_orders.has(bus.assigned_order_id):
			var active_order = runner.state.evacuation_orders[bus.assigned_order_id]
			if active_order.active:
				continue

		var pickup_id := _pick_target_district(graph)
		if pickup_id.is_empty():
			continue
		var shelter_id := _pick_best_shelter(graph, pickup_id)
		if shelter_id.is_empty():
			continue
		var order_id := "auto_%s" % bus.id
		var order = EvacuationOrder.new({
			"id": order_id,
			"pickup_district_id": pickup_id,
			"dropoff_shelter_id": shelter_id,
			"priority_policy": _priority_for_district(graph.get_district(pickup_id)),
			"assigned_bus_ids": [bus.id],
			"repeat": true,
			"min_load_percent": 0.35,
			"avoid_high_danger": false,
			"allow_dangerous_roads": true,
		})
		runner.state.evacuation_orders[order.id] = order
		bus.assigned_order_id = order.id


func _pick_target_district(graph) -> String:
	var best_id := ""
	var best_score: int = -1
	for district_id in graph.district_states.keys():
		var district = graph.get_district(String(district_id))
		if district == null or district.is_shelter or district.total_population() <= 0:
			continue
		var score: int = district.total_population() + int(district.danger * 8.0) + int(district.panic * 2.0)
		if score > best_score:
			best_score = score
			best_id = district.id
	return best_id


func _pick_best_shelter(graph, pickup_id: String) -> String:
	var best_shelter := ""
	var best_cost := INF
	for shelter_id in graph.get_shelter_ids():
		var route: Dictionary = _route_planner.find_route(graph, pickup_id, String(shelter_id), {
			"allow_dangerous_roads": true,
		})
		if not bool(route.get("reachable", false)):
			continue
		var cost: float = float(route.get("total_cost", INF))
		if cost < best_cost:
			best_cost = cost
			best_shelter = String(shelter_id)
	return best_shelter


func _priority_for_district(district) -> String:
	if district == null:
		return "balanced"
	if district.tags.has("medical"):
		return "medical_first"
	if int(district.population.get("children", 0)) >= 140:
		return "children_first"
	if int(district.population.get("essential_staff", 0)) >= 80:
		return "essential_staff_first"
	return "balanced"


func _resolve_pending_event(runner, graph) -> void:
	if runner.state.scheduled_events.is_empty() or runner.event_director == null:
		return
	var current_event: Dictionary = runner.state.scheduled_events[0]
	var options: Array = Array(current_event.get("options", []))
	for option in options:
		if not option is Dictionary:
			continue
		var result: Dictionary = runner.event_director.choose_option(
			runner.state,
			String(current_event.get("event_id", "")),
			String(option.get("id", "")),
			graph
		)
		if bool(result.get("ok", false)):
			return


func _maybe_offer_cards(runner, scenario_def, card_system) -> void:
	if card_system == null or scenario_def == null:
		return
	var milestones: Array = Array(scenario_def.metadata.get("card_offer_minutes", [])).duplicate(true)
	var triggered: Array = Array(runner.state.run_flags.get("card_offer_milestones_triggered", [])).duplicate(true)
	for raw_minute in milestones:
		var minute := int(raw_minute)
		if runner.state.elapsed_minutes < minute or triggered.has(minute):
			continue
		triggered.append(minute)
		runner.state.run_flags["card_offer_milestones_triggered"] = triggered
		if Array(runner.state.run_flags.get("current_card_offer", [])).is_empty():
			card_system.generate_offer(runner.state, scenario_def)

	var repeat_interval := int(scenario_def.metadata.get("card_offer_repeat_interval_minutes", 0))
	if repeat_interval <= 0:
		return
	var next_repeat := int(runner.state.run_flags.get("next_card_repeat_minute", 0))
	if next_repeat <= 0:
		var last_milestone := 0
		for raw_minute in milestones:
			last_milestone = maxi(last_milestone, int(raw_minute))
		next_repeat = (last_milestone + repeat_interval) if last_milestone > 0 else repeat_interval
	while runner.state.elapsed_minutes >= next_repeat:
		if Array(runner.state.run_flags.get("current_card_offer", [])).is_empty():
			card_system.generate_offer(runner.state, scenario_def)
		next_repeat += repeat_interval
	runner.state.run_flags["next_card_repeat_minute"] = next_repeat


func _pick_card_if_available(runner, card_system) -> void:
	var offer: Array = Array(runner.state.run_flags.get("current_card_offer", [])).duplicate(true)
	if offer.is_empty():
		return
	card_system.choose_card(runner.state, String(offer[0]))


func _build_summary(rows: Array, scenario_def, total_runs: int, broken_seeds: Array) -> Dictionary:
	var grade_counts: Dictionary = {}
	var end_reason_counts: Dictionary = {}
	var total_score := 0.0
	var total_saved := 0.0
	var total_dead := 0.0
	var total_minutes := 0.0
	var total_waves := 0.0
	for row in rows:
		if not row is Dictionary:
			continue
		total_score += float(row.get("score", 0))
		total_saved += float(row.get("saved_population", 0))
		total_dead += float(row.get("dead_population", 0))
		total_minutes += float(row.get("elapsed_minutes", 0))
		total_waves += float(row.get("wave_reached", 0))
		var grade := String(row.get("grade", ""))
		grade_counts[grade] = int(grade_counts.get(grade, 0)) + 1
		var end_reason := String(row.get("end_reason", ""))
		end_reason_counts[end_reason] = int(end_reason_counts.get(end_reason, 0)) + 1

	var divisor := maxf(1.0, float(rows.size()))
	return {
		"scenario_id": "" if scenario_def == null else String(scenario_def.id),
		"scenario_name": "" if scenario_def == null else String(scenario_def.name),
		"requested_runs": total_runs,
		"completed_runs": rows.size(),
		"broken_seeds": broken_seeds.duplicate(true),
		"average_score": total_score / divisor,
		"average_saved_population": total_saved / divisor,
		"average_dead_population": total_dead / divisor,
		"average_elapsed_minutes": total_minutes / divisor,
		"average_wave_reached": total_waves / divisor,
		"grade_counts": grade_counts,
		"end_reason_counts": end_reason_counts,
	}


func _write_reports(scenario_id: String, rows: Array, summary: Dictionary) -> Dictionary:
	var absolute_output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(absolute_output_dir)
	var stamp := str(Time.get_unix_time_from_system())
	var csv_path := "%s/%s_%s.csv" % [absolute_output_dir, scenario_id, stamp]
	var json_path := "%s/%s_%s.json" % [absolute_output_dir, scenario_id, stamp]

	var csv_file := FileAccess.open(csv_path, FileAccess.WRITE)
	if csv_file != null:
		csv_file.store_line("seed,score,grade,end_reason,elapsed_minutes,saved_population,dead_population,remaining_population,wave_reached")
		for row in rows:
			if not row is Dictionary:
				continue
			csv_file.store_line("%d,%d,%s,%s,%d,%d,%d,%d,%d" % [
				int(row.get("seed", 0)),
				int(row.get("score", 0)),
				String(row.get("grade", "")),
				String(row.get("end_reason", "")),
				int(row.get("elapsed_minutes", 0)),
				int(row.get("saved_population", 0)),
				int(row.get("dead_population", 0)),
				int(row.get("remaining_population", 0)),
				int(row.get("wave_reached", 0)),
			])
		csv_file.close()

	var json_file := FileAccess.open(json_path, FileAccess.WRITE)
	if json_file != null:
		json_file.store_string(JSON.stringify({
			"summary": summary,
			"rows": rows,
		}, "\t"))
		json_file.close()

	return {"csv": csv_path, "json": json_path}


func _parse_arg(prefix: String, fallback: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return fallback


func _parse_optional_arg(prefix: String) -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with(prefix):
			return arg.trim_prefix(prefix)
	return ""


func _is_infinite_scenario(scenario_def) -> bool:
	return scenario_def != null and bool(Dictionary(scenario_def.metadata).get("infinite_mode", false))


func _can_retire_infinite_run(state) -> bool:
	if state == null:
		return false
	var infinite_state: Variant = state.run_flags.get("infinite_mode", {})
	return infinite_state is Dictionary and bool(Dictionary(infinite_state).get("extraction_unlocked", false))


func _should_retire_infinite_run(state, scenario_def, retire_at_wave: int) -> bool:
	if not _is_infinite_scenario(scenario_def) or not _can_retire_infinite_run(state):
		return false
	var infinite_state: Dictionary = Dictionary(state.run_flags.get("infinite_mode", {}))
	return int(infinite_state.get("wave", 0)) >= retire_at_wave


func _retire_run(state) -> void:
	state.score_state["run_over"] = true
	state.score_state["end_reason"] = "player_retired"
