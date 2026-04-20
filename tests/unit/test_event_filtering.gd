extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const DeterministicRng = preload("res://scripts/core/DeterministicRng.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const EventDirector = preload("res://scripts/sim/EventDirector.gd")


func test_allowed_event_ids_filter_candidates() -> void:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)

	var scenario_def = content_db.get_runtime_scenario("campanha_tutorial_primeiras_rotas")
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = 7
	var state = GameState.create_initial(run_config)
	state.elapsed_minutes = 3
	state.run_flags["allowed_event_ids"] = ["event_tutorial_radio_call"]
	var graph = CityGraph.new(content_db.get_map(scenario_def.map_id).to_dictionary())
	graph.apply_to_game_state(state)

	var director = EventDirector.new(content_db, DeterministicRng.new(7))
	var queued = director.update(state, graph)

	assert_eq(String(queued.get("event_id", "")), "event_tutorial_radio_call")
	content_db.free()
