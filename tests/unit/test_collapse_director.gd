extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const CollapseDirector = preload("res://scripts/sim/CollapseDirector.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")


func test_district_danger_worsens_over_time() -> void:
	var runtime = _create_runtime()
	var district = runtime["graph"].get_district("centro")
	var initial_danger: float = district.danger
	var director = CollapseDirector.new()

	director.update(runtime["state"], runtime["graph"], 10)

	assert_true(district.danger > initial_danger)
	runtime["content_db"].free()


func test_collapse_affects_connected_roads() -> void:
	var runtime = _create_runtime()
	var district = runtime["graph"].get_district("centro")
	district.collapse = 90.0
	var road = runtime["graph"].get_road("road_centro_terminal")
	var initial_blockade: float = road.blockade
	var director = CollapseDirector.new()

	director.update(runtime["state"], runtime["graph"], 1)

	assert_true(road.blockade > initial_blockade or road.blocked_by_collapse)
	runtime["content_db"].free()


func test_modifier_stack_can_mitigate_collapse_pressure() -> void:
	var base_runtime = _create_runtime()
	var mitigated_runtime = _create_runtime()
	var base_director = CollapseDirector.new()
	var stack = ModifierStack.new()
	stack.add_modifier({"stat": "collapse_base_threat_rate", "op": "multiply", "value": 0.25})
	var mitigated_director = CollapseDirector.new(stack)

	base_director.update(base_runtime["state"], base_runtime["graph"], 10)
	mitigated_director.update(mitigated_runtime["state"], mitigated_runtime["graph"], 10)

	assert_true(mitigated_runtime["graph"].get_district("centro").danger < base_runtime["graph"].get_district("centro").danger)
	base_runtime["content_db"].free()
	mitigated_runtime["content_db"].free()


func _create_runtime() -> Dictionary:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)
	var scenario_def = content_db.get_runtime_scenario("campanha_tiny_map")
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	var state = GameState.create_initial(run_config)
	var graph = CityGraph.new(content_db.get_map("tiny_map").to_dictionary())
	graph.apply_to_game_state(state)
	return {
		"content_db": content_db,
		"state": state,
		"graph": graph,
	}
