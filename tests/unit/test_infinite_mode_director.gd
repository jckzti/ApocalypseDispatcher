extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const SimulationRunner = preload("res://scripts/sim/SimulationRunner.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")


func test_infinite_mode_spawns_new_population_and_unlocks_extraction() -> void:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)

	var scenario_def = content_db.get_runtime_scenario("infinito_colapso_total")
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = 909
	var state = GameState.create_initial(run_config)
	state.run_flags["allowed_event_ids"] = scenario_def.allowed_event_ids.duplicate(true)
	var graph = CityGraph.new(content_db.get_map(scenario_def.map_id).to_dictionary())
	graph.apply_to_game_state(state)

	var initial_population := _remaining_population(graph)
	var runner = SimulationRunner.new(run_config, state)
	runner.configure_runtime(graph, ModifierStack.new(), null, null, null, null, content_db)
	runner.advance(int(scenario_def.metadata.get("wave_interval_minutes", 15)))

	var infinite_state: Dictionary = Dictionary(runner.state.run_flags.get("infinite_mode", {}))
	assert_eq(int(infinite_state.get("wave", 0)), 1)
	assert_true(bool(infinite_state.get("extraction_unlocked", false)))
	assert_true(int(infinite_state.get("wave_score", 0)) > 0)
	assert_true(runner.state.crisis_level > 0)
	assert_true(_remaining_population(graph) > initial_population)

	content_db.free()


func _remaining_population(graph) -> int:
	var total := 0
	for district in graph.district_states.values():
		if district.is_shelter:
			continue
		total += district.total_population()
	return total
