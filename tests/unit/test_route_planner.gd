extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const RoutePlanner = preload("res://scripts/sim/RoutePlanner.gd")


func test_dijkstra_finds_route_between_districts() -> void:
	var graph = _load_graph_from_data()
	var planner = RoutePlanner.new()
	var route = planner.find_route(graph, "centro", "terminal_oeste")

	assert_true(bool(route.get("reachable", false)))
	assert_eq(route["district_ids"], ["centro", "terminal_oeste"])
	assert_eq(route["road_ids"], ["road_centro_terminal"])


func test_blockade_changes_route() -> void:
	var graph = _load_graph_from_data()
	graph.get_road("road_centro_terminal").blockade = 95.0
	var planner = RoutePlanner.new()
	var route = planner.find_route(graph, "centro", "terminal_oeste")

	assert_true(bool(route.get("reachable", false)))
	assert_eq(route["road_ids"], ["road_centro_hospital", "road_hospital_terminal"])


func test_dangerous_road_increases_cost() -> void:
	var graph = _load_graph_from_data()
	var planner = RoutePlanner.new()
	var baseline = planner.find_route(graph, "centro", "terminal_oeste")

	graph.get_road("road_centro_terminal").danger = 95.0
	var dangerous = planner.find_route(graph, "centro", "terminal_oeste")

	assert_true(float(dangerous["total_cost"]) > float(baseline["total_cost"]))


func test_shelter_district_is_recognized() -> void:
	var graph = _load_graph_from_data()
	var shelter = graph.get_shelter("terminal_oeste")

	assert_not_null(shelter)
	assert_eq(shelter.district_id, "terminal_oeste")


func _load_graph_from_data():
	var content_db = ContentDbScript.new()
	var ok := content_db.load_content("res://data")
	assert_true(ok)
	var map_def = content_db.get_map("tiny_map")
	var graph = CityGraph.new(map_def.to_dictionary())
	content_db.free()
	return graph
