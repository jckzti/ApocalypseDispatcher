extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const SaveServiceScript = preload("res://scripts/autoload/SaveService.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const SimulationRunner = preload("res://scripts/sim/SimulationRunner.gd")
const CardSystem = preload("res://scripts/sim/CardSystem.gd")
const BusUnit = preload("res://scripts/sim/BusUnit.gd")
const EvacuationOrder = preload("res://scripts/sim/EvacuationOrder.gd")

const TEST_SAVE_PATH := "user://saves/test_roundtrip.json"
const TEST_INVALID_PATH := "user://saves/test_invalid.json"


func test_save_roundtrip_restores_relevant_state() -> void:
	var runtime = _create_runtime()
	var save_service = SaveServiceScript.new()

	var save_result = save_service.save_current_run(runtime["runner"], runtime["scenario_def"], {
		"selected_pickup_id": "bairro_vista",
		"selected_shelter_id": "ginasio_seguro",
		"focused_district_id": "bairro_vista",
	}, TEST_SAVE_PATH)
	assert_true(bool(save_result.get("ok", false)))

	var payload_result = save_service.load_run_payload(TEST_SAVE_PATH)
	assert_true(bool(payload_result.get("ok", false)))

	var rebuild = save_service.rebuild_runtime_from_save(Dictionary(payload_result.get("data", {})), runtime["content_db"])
	assert_true(bool(rebuild.get("ok", false)))

	var loaded_runner = rebuild["runner"]
	assert_eq(loaded_runner.state.elapsed_minutes, runtime["runner"].state.elapsed_minutes)
	assert_eq(String(loaded_runner.state.scenario_id), "campanha_tutorial_primeiras_rotas")
	assert_eq(loaded_runner.state.bus_units.size(), runtime["runner"].state.bus_units.size())
	assert_eq(loaded_runner.state.evacuation_orders.size(), runtime["runner"].state.evacuation_orders.size())
	assert_eq(int(loaded_runner.state.global_metrics.get("saved_population", 0)), int(runtime["runner"].state.global_metrics.get("saved_population", 0)))
	assert_eq(Array(rebuild["ui_state"].keys()).size(), 3)
	assert_true(Array(loaded_runner.state.active_modifiers).size() > 0)

	_cleanup_file(TEST_SAVE_PATH)
	runtime["content_db"].free()
	save_service.free()


func test_invalid_save_does_not_crash_loading() -> void:
	var save_service = SaveServiceScript.new()
	save_service.ensure_storage()
	var file := FileAccess.open(TEST_INVALID_PATH, FileAccess.WRITE)
	file.store_string("{ invalid json")
	file.close()

	var payload_result = save_service.load_run_payload(TEST_INVALID_PATH)
	assert_false(bool(payload_result.get("ok", false)))

	_cleanup_file(TEST_INVALID_PATH)
	save_service.free()


func test_save_roundtrip_restores_daily_challenge_context() -> void:
	var runtime = _create_daily_runtime("2026-04-20")
	var save_service = SaveServiceScript.new()

	var save_result = save_service.save_current_run(runtime["runner"], runtime["scenario_def"], {}, TEST_SAVE_PATH)
	assert_true(bool(save_result.get("ok", false)))

	var payload_result = save_service.load_run_payload(TEST_SAVE_PATH)
	assert_true(bool(payload_result.get("ok", false)))

	var rebuild = save_service.rebuild_runtime_from_save(Dictionary(payload_result.get("data", {})), runtime["content_db"])
	assert_true(bool(rebuild.get("ok", false)))
	assert_eq("desafio_diario", String(rebuild["scenario_def"].id))
	assert_eq("2026-04-20", String(rebuild["scenario_def"].metadata.get("daily_key", "")))
	assert_eq(
		int(runtime["scenario_def"].metadata.get("daily_seed", 0)),
		int(rebuild["scenario_def"].metadata.get("daily_seed", 0))
	)

	_cleanup_file(TEST_SAVE_PATH)
	runtime["content_db"].free()
	save_service.free()


func test_seed_leaderboard_keeps_best_run_per_seed_and_sorts_by_score() -> void:
	var save_service = SaveServiceScript.new()
	var content_db = ContentDbScript.new()
	assert_true(content_db.load_content("res://data"))

	var profile := save_service.get_default_profile(content_db)
	assert_true(bool(save_service.save_profile(profile, content_db).get("ok", false)))

	assert_true(bool(save_service.record_run_result({
		"scenario_id": "campanha_01_cidade_cinza",
		"scenario_name": "Campanha 01 - Cidade Cinza",
		"seed": 111,
		"score": 900,
		"grade": "C",
		"title": "Teste A",
		"end_reason": "command_center_lost",
		"elapsed_minutes": 220,
	}, content_db).get("ok", false)))
	assert_true(bool(save_service.record_run_result({
		"scenario_id": "campanha_01_cidade_cinza",
		"scenario_name": "Campanha 01 - Cidade Cinza",
		"seed": 111,
		"score": 980,
		"grade": "B",
		"title": "Teste B",
		"end_reason": "command_center_lost",
		"elapsed_minutes": 210,
	}, content_db).get("ok", false)))
	assert_true(bool(save_service.record_run_result({
		"scenario_id": "campanha_01_cidade_cinza",
		"scenario_name": "Campanha 01 - Cidade Cinza",
		"seed": 222,
		"score": 1250,
		"grade": "B",
		"title": "Teste C",
		"end_reason": "time_limit",
		"elapsed_minutes": 240,
	}, content_db).get("ok", false)))

	var leaderboard: Array = save_service.get_seed_leaderboard(content_db, "campanha_01_cidade_cinza", 5)
	assert_eq(2, leaderboard.size())
	assert_eq(222, int(Dictionary(leaderboard[0]).get("seed", 0)))
	assert_eq(1250, int(Dictionary(leaderboard[0]).get("score", 0)))
	assert_eq(111, int(Dictionary(leaderboard[1]).get("seed", 0)))
	assert_eq(980, int(Dictionary(leaderboard[1]).get("score", 0)))

	_cleanup_file(SaveServiceScript.PROFILE_PATH)
	content_db.free()
	save_service.free()


func test_daily_leaderboard_is_tracked_per_day() -> void:
	var save_service = SaveServiceScript.new()
	var content_db = ContentDbScript.new()
	assert_true(content_db.load_content("res://data"))

	var profile := save_service.get_default_profile(content_db)
	assert_true(bool(save_service.save_profile(profile, content_db).get("ok", false)))

	assert_true(bool(save_service.record_run_result({
		"scenario_id": "desafio_diario",
		"scenario_name": "Desafio Diario",
		"seed": 444,
		"daily_key": "2026-04-20",
		"score": 1200,
		"grade": "B",
		"title": "Teste Diario A",
		"end_reason": "time_limit",
		"elapsed_minutes": 260,
	}, content_db).get("ok", false)))
	assert_true(bool(save_service.record_run_result({
		"scenario_id": "desafio_diario",
		"scenario_name": "Desafio Diario",
		"seed": 444,
		"daily_key": "2026-04-20",
		"score": 1350,
		"grade": "B",
		"title": "Teste Diario B",
		"end_reason": "time_limit",
		"elapsed_minutes": 250,
	}, content_db).get("ok", false)))
	assert_true(bool(save_service.record_run_result({
		"scenario_id": "desafio_diario",
		"scenario_name": "Desafio Diario",
		"seed": 555,
		"daily_key": "2026-04-21",
		"score": 980,
		"grade": "C",
		"title": "Teste Diario C",
		"end_reason": "command_center_lost",
		"elapsed_minutes": 210,
	}, content_db).get("ok", false)))

	var day_one: Array = save_service.get_daily_leaderboard(content_db, "desafio_diario", "2026-04-20", 5)
	var day_two: Array = save_service.get_daily_leaderboard(content_db, "desafio_diario", "2026-04-21", 5)

	assert_eq(1, day_one.size())
	assert_eq(444, int(Dictionary(day_one[0]).get("seed", 0)))
	assert_eq(1350, int(Dictionary(day_one[0]).get("score", 0)))
	assert_eq(1, day_two.size())
	assert_eq(555, int(Dictionary(day_two[0]).get("seed", 0)))

	_cleanup_file(SaveServiceScript.PROFILE_PATH)
	content_db.free()
	save_service.free()


func _create_runtime() -> Dictionary:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)

	var scenario_def = content_db.get_runtime_scenario("campanha_tutorial_primeiras_rotas")
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = 20260420

	var state = GameState.create_initial(run_config)
	state.run_flags["allowed_event_ids"] = scenario_def.allowed_event_ids.duplicate(true)
	state.run_flags["current_scenario_id"] = scenario_def.id
	var graph = CityGraph.new(content_db.get_map(scenario_def.map_id).to_dictionary())
	graph.apply_to_game_state(state)

	for bus_data in scenario_def.starting_buses:
		var bus = BusUnit.new(bus_data)
		bus.current_district_id = "garagem_central"
		state.bus_units[bus.id] = bus

	var order = EvacuationOrder.new({
		"id": "order_01",
		"pickup_district_id": "bairro_vista",
		"dropoff_shelter_id": "ginasio_seguro",
		"assigned_bus_ids": ["bus_tutorial_01"],
		"priority_policy": "balanced",
	})
	state.evacuation_orders[order.id] = order
	state.bus_units["bus_tutorial_01"].assigned_order_id = order.id

	var modifier_stack = ModifierStack.new()
	var runner = SimulationRunner.new(run_config, state)
	runner.configure_runtime(graph, modifier_stack, null, null, null, null, content_db)

	var card_system = CardSystem.new(content_db, modifier_stack, runner.rng)
	card_system.choose_card(runner.state, "card_tutorial_clipboards")
	runner.advance(6)

	return {
		"content_db": content_db,
		"scenario_def": scenario_def,
		"runner": runner,
	}


func _create_daily_runtime(daily_key: String) -> Dictionary:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)

	var scenario_def = content_db.get_runtime_scenario("desafio_diario", {"daily_key": daily_key})
	assert_not_null(scenario_def)
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = int(scenario_def.metadata.get("daily_seed", 1))

	var state = GameState.create_initial(run_config)
	state.run_flags["allowed_event_ids"] = scenario_def.allowed_event_ids.duplicate(true)
	state.run_flags["current_scenario_id"] = scenario_def.id
	var graph = CityGraph.new(content_db.get_map(scenario_def.map_id).to_dictionary())
	graph.apply_to_game_state(state)

	for bus_data in scenario_def.starting_buses:
		var bus = BusUnit.new(bus_data)
		bus.current_district_id = "terminal_ferrovelho"
		state.bus_units[bus.id] = bus

	var modifier_stack = ModifierStack.new()
	var runner = SimulationRunner.new(run_config, state)
	runner.configure_runtime(graph, modifier_stack, null, null, null, null, content_db)
	runner.advance(3)

	return {
		"content_db": content_db,
		"scenario_def": scenario_def,
		"runner": runner,
	}


func _cleanup_file(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(absolute_path)
