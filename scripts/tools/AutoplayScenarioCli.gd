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
const SaveServiceScript = preload("res://scripts/autoload/SaveService.gd")

var _route_planner := RoutePlanner.new()


func _initialize() -> void:
	var scenario_id := _parse_arg("--scenario=", "campanha_01_cidade_cinza")
	var max_minutes := int(_parse_arg("--minutes=", "240"))
	var daily_key := _parse_optional_arg("--date=")
	var seed_arg := _parse_optional_arg("--seed=")
	var seed := 0 if seed_arg.is_empty() else int(seed_arg)
	var retire_at := int(_parse_arg("--retire-at=", "-1"))
	var retire_at_wave := int(_parse_arg("--retire-at-wave=", "-1"))

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
	if seed <= 0:
		seed = DailyChallengeService.resolve_seed_for_scenario(scenario_def, 20260420)

	var runtime := _create_runtime(content_db, scenario_def, seed)
	var runner = runtime["runner"]
	var graph = runtime["graph"]
	var card_system = runtime["card_system"]
	var score_system = ScoreSystem.new()
	var save_service = SaveServiceScript.new()
	var qa_state := {
		"selected_pickup_id": "",
		"selected_shelter_id": "",
	}

	for _minute in range(max_minutes):
		_assign_orders_if_needed(runner, graph, scenario_def, qa_state)
		_resolve_pending_event(runner, graph)
		_maybe_offer_cards(runner, scenario_def, card_system)
		_pick_card_if_available(runner, card_system, scenario_def)
		_maybe_persist_manual_save(runner, scenario_def, save_service)
		runner.advance(1)
		if _should_retire_infinite_run(runner.state, scenario_def, retire_at, retire_at_wave):
			_retire_run(runner.state)
			break
		var end_state: Dictionary = score_system.evaluate_end_conditions(runner.state, scenario_def, graph)
		if bool(end_state.get("run_over", false)):
			break

	if _is_infinite_scenario(scenario_def) and not bool(runner.state.score_state.get("run_over", false)) and _can_retire_infinite_run(runner.state):
		_retire_run(runner.state)

	var report := score_system.evaluate_run(runner.state, scenario_def, graph, content_db)
	print("Autoplay finalizado para %s." % scenario_def.name)
	print("Tempo: %d | Score: %d | Nota: %s | Fim: %s" % [
		int(report.get("elapsed_minutes", 0)),
		int(report.get("score", 0)),
		String(report.get("grade", "")),
		String(report.get("end_reason", "")),
	])
	print("Salvos: %d | Mortos: %d | Restantes: %d" % [
		int(report.get("saved_population", 0)),
		int(report.get("dead_population", 0)),
		int(report.get("remaining_population", 0)),
	])
	if bool(report.get("daily_mode", false)):
		print("Desafio diario: %s | Base: %s" % [
			String(report.get("daily_key", "")),
			String(report.get("daily_source_scenario_name", "")),
		])
		var modifiers: Array = Array(report.get("daily_modifier_labels", [])).duplicate(true)
		if not modifiers.is_empty():
			print("Mutadores: %s" % " | ".join(modifiers))
	if int(report.get("wave_reached", 0)) > 0:
		print("Ondas: %d | Score de ondas: %d" % [
			int(report.get("wave_reached", 0)),
			int(report.get("wave_score", 0)),
		])

	var exit_code := 0
	if not scenario_def.tutorial_steps.is_empty():
		var tutorial_status := _evaluate_tutorial_steps(scenario_def, runner, qa_state)
		var pending_step_ids: Array = Array(tutorial_status.get("pending_step_ids", []))
		print("Tutorial QA: %d/%d passos concluidos." % [
			int(tutorial_status.get("completed_steps", 0)),
			int(tutorial_status.get("total_steps", 0)),
		])
		if not pending_step_ids.is_empty():
			exit_code = 1
			print("Passos pendentes: %s" % ", ".join(pending_step_ids))

	save_service.free()
	content_db.free()
	quit(exit_code)


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


func _assign_orders_if_needed(runner, graph, scenario_def = null, qa_state: Dictionary = {}) -> void:
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
		qa_state["selected_pickup_id"] = pickup_id
		qa_state["selected_shelter_id"] = shelter_id


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
	var best_option_id := ""
	var best_score := -INF
	for option in options:
		if not option is Dictionary:
			continue
		var option_requirements: Dictionary = Dictionary(option.get("requirements", {}))
		if not _requirements_met(option_requirements, runner.state):
			continue
		var score := _score_effect_map(Dictionary(option.get("effects", {})))
		if score > best_score:
			best_score = score
			best_option_id = String(option.get("id", ""))
	if best_option_id.is_empty():
		return
	runner.event_director.choose_option(
		runner.state,
		String(current_event.get("event_id", "")),
		best_option_id,
		graph
	)


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
	var generated_repeat_offer := false
	while runner.state.elapsed_minutes >= next_repeat:
		if not generated_repeat_offer and Array(runner.state.run_flags.get("current_card_offer", [])).is_empty():
			card_system.generate_offer(runner.state, scenario_def)
			generated_repeat_offer = true
		next_repeat += repeat_interval
	runner.state.run_flags["next_card_repeat_minute"] = next_repeat


func _pick_card_if_available(runner, card_system, scenario_def = null) -> void:
	var offer: Array = Array(runner.state.run_flags.get("current_card_offer", [])).duplicate(true)
	if offer.is_empty():
		return
	var picked_id := String(offer[0])
	var best_score := -INF
	for offered_id in offer:
		var card_id := String(offered_id)
		var card_def = card_system.content_db.get_card(card_id)
		if card_def == null:
			continue
		var current_level := int(runner.state.owned_cards.get(card_id, 0))
		var next_level := current_level + 1
		var score := _score_effect_map(_resolve_card_effect_map(card_def, next_level))
		if current_level <= 0:
			score += 220.0
			if scenario_def != null and not scenario_def.tutorial_steps.is_empty():
				score += 120.0
		if score > best_score:
			best_score = score
			picked_id = card_id
	card_system.choose_card(runner.state, picked_id)


func _maybe_persist_manual_save(runner, scenario_def, save_service) -> void:
	if scenario_def == null or save_service == null:
		return
	if bool(runner.state.run_flags.get("manual_saved", false)):
		return
	var requires_manual_save := false
	for raw_step in scenario_def.tutorial_steps:
		var step: Dictionary = Dictionary(raw_step)
		var condition: Dictionary = Dictionary(step.get("condition", {}))
		if String(condition.get("type", "")) == "manual_save_exists":
			requires_manual_save = true
			break
	if not requires_manual_save:
		return
	if runner.state.event_history.size() < 1 and _count_owned_cards(runner.state) < 2 and runner.state.elapsed_minutes < 4:
		return
	var result: Dictionary = save_service.save_current_run(runner, scenario_def, {})
	if bool(result.get("ok", false)):
		runner.state.run_flags["manual_saved"] = true


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


func _should_retire_infinite_run(state, scenario_def, retire_at: int, retire_at_wave: int) -> bool:
	if not _is_infinite_scenario(scenario_def) or not _can_retire_infinite_run(state):
		return false
	if retire_at >= 0 and state.elapsed_minutes >= retire_at:
		return true
	if retire_at_wave >= 0:
		var infinite_state: Dictionary = Dictionary(state.run_flags.get("infinite_mode", {}))
		return int(infinite_state.get("wave", 0)) >= retire_at_wave
	return false


func _retire_run(state) -> void:
	state.score_state["run_over"] = true
	state.score_state["end_reason"] = "player_retired"


func _evaluate_tutorial_steps(scenario_def, runner, qa_state: Dictionary) -> Dictionary:
	var completed_steps := 0
	var pending_step_ids: Array = []
	for raw_step in scenario_def.tutorial_steps:
		var step: Dictionary = Dictionary(raw_step)
		if _is_tutorial_step_complete(step, runner, qa_state):
			completed_steps += 1
			continue
		pending_step_ids.append(String(step.get("id", "")))
	return {
		"completed_steps": completed_steps,
		"total_steps": scenario_def.tutorial_steps.size(),
		"pending_step_ids": pending_step_ids,
	}


func _is_tutorial_step_complete(step: Dictionary, runner, qa_state: Dictionary) -> bool:
	var condition: Dictionary = Dictionary(step.get("condition", {}))
	match String(condition.get("type", "")):
		"selected_pickup":
			return not String(qa_state.get("selected_pickup_id", "")).is_empty()
		"selected_shelter":
			return not String(qa_state.get("selected_shelter_id", "")).is_empty()
		"order_count_at_least":
			return runner.state.evacuation_orders.size() >= int(condition.get("value", 0))
		"elapsed_minutes_at_least":
			return runner.state.elapsed_minutes >= int(condition.get("value", 0))
		"owned_card_count_at_least":
			return _count_owned_cards(runner.state) >= int(condition.get("value", 0))
		"event_history_count_at_least":
			return runner.state.event_history.size() >= int(condition.get("value", 0))
		"manual_save_exists":
			return bool(runner.state.run_flags.get("manual_saved", false))
		"saved_population_at_least":
			return int(runner.state.global_metrics.get("saved_population", 0)) >= int(condition.get("value", 0))
		_:
			return false


func _count_owned_cards(state) -> int:
	if state == null:
		return 0
	var total := 0
	for level in state.owned_cards.values():
		if int(level) > 0:
			total += 1
	return total


func _requirements_met(requirements: Dictionary, state) -> bool:
	for requirement_key in requirements.keys():
		if float(state.global_resources.get(String(requirement_key), 0)) < float(requirements[requirement_key]):
			return false
	return true


func _resolve_card_effect_map(card_def, level: int) -> Dictionary:
	var effect_index := mini(level, card_def.effects_by_level.size()) - 1
	if effect_index < 0:
		return {}
	var raw_effect_map = card_def.effects_by_level[effect_index]
	if not raw_effect_map is Dictionary:
		return {}
	return Dictionary(raw_effect_map).duplicate(true)


func _score_effect_map(effect_map: Dictionary) -> float:
	var score := 0.0
	for effect_key in effect_map.keys():
		var key := String(effect_key)
		var value := float(effect_map[effect_key])
		match key:
			"boarding_rate_multiplier":
				score += value * 1000.0
			"district_panic_add", "panic_add":
				score += -value * 35.0
			"trust_add":
				score += value * 24.0
			"communication_add":
				score += value * 20.0
			"order_add":
				score += value * 8.0
			"fuel_add":
				score += value * 0.25
			"budget_add":
				score += value * 4.0
			"medical_supplies_add":
				score += value * 12.0
			"bus_fuel_consumption_multiplier":
				score += -value * 120.0
			"district_danger_add":
				score += -value * 30.0
			"attrition_multiplier":
				score += -value * 90.0
			"collapse_base_threat_rate_multiplier", "district_collapse_delta_multiplier":
				score += -value * 70.0
			"road_blockade_from_collapse_multiplier", "road_danger_from_collapse_multiplier":
				score += -value * 60.0
			_:
				if key.ends_with("_add"):
					score += value
	return score
