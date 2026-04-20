extends RefCounted
class_name RoutePlanner

const RoadState = preload("res://scripts/sim/RoadState.gd")


func find_route(city_graph, origin_id: String, destination_id: String, options: Dictionary = {}) -> Dictionary:
	if origin_id.is_empty() or destination_id.is_empty():
		return _unreachable_result(origin_id, destination_id)
	if city_graph.get_district(origin_id) == null or city_graph.get_district(destination_id) == null:
		return _unreachable_result(origin_id, destination_id)
	if origin_id == destination_id:
		return {
			"reachable": true,
			"origin_id": origin_id,
			"destination_id": destination_id,
			"district_ids": [origin_id],
			"road_ids": [],
			"total_cost": 0.0,
			"total_distance_km": 0.0,
		}

	var frontier: Array = city_graph.district_states.keys()
	var distances: Dictionary = {}
	var previous_nodes: Dictionary = {}
	var previous_roads: Dictionary = {}
	for district_id in frontier:
		distances[String(district_id)] = RoadState.INF_COST
	distances[origin_id] = 0.0

	while not frontier.is_empty():
		var current_id: String = _pick_lowest_cost(frontier, distances)
		if current_id.is_empty():
			break
		frontier.erase(current_id)
		if current_id == destination_id:
			break

		for edge in city_graph.get_neighbors(current_id):
			var neighbor_id: String = String(edge.get("to_id", ""))
			if not frontier.has(neighbor_id):
				continue
			var road = city_graph.get_road(String(edge.get("road_id", "")))
			if road == null:
				continue
			var edge_cost: float = road.travel_cost(options)
			if edge_cost >= RoadState.INF_COST:
				continue
			var candidate_cost: float = float(distances.get(current_id, RoadState.INF_COST)) + edge_cost
			if candidate_cost < float(distances.get(neighbor_id, RoadState.INF_COST)):
				distances[neighbor_id] = candidate_cost
				previous_nodes[neighbor_id] = current_id
				previous_roads[neighbor_id] = road.id

	if not previous_nodes.has(destination_id):
		return _unreachable_result(origin_id, destination_id)

	var district_ids: Array = [destination_id]
	var road_ids: Array = []
	var cursor: String = destination_id
	while previous_nodes.has(cursor):
		road_ids.push_front(previous_roads[cursor])
		cursor = String(previous_nodes[cursor])
		district_ids.push_front(cursor)

	var total_distance: float = 0.0
	for road_id in road_ids:
		var road = city_graph.get_road(String(road_id))
		if road != null:
			total_distance += road.length_km

	return {
		"reachable": true,
		"origin_id": origin_id,
		"destination_id": destination_id,
		"district_ids": district_ids,
		"road_ids": road_ids,
		"total_cost": float(distances.get(destination_id, RoadState.INF_COST)),
		"total_distance_km": total_distance,
	}


func _pick_lowest_cost(frontier: Array, distances: Dictionary) -> String:
	var best_id: String = ""
	var best_cost: float = RoadState.INF_COST
	for district_id in frontier:
		var district_key: String = String(district_id)
		var candidate_cost: float = float(distances.get(district_key, RoadState.INF_COST))
		if candidate_cost < best_cost:
			best_cost = candidate_cost
			best_id = district_key
	return best_id


func _unreachable_result(origin_id: String, destination_id: String) -> Dictionary:
	return {
		"reachable": false,
		"origin_id": origin_id,
		"destination_id": destination_id,
		"district_ids": [],
		"road_ids": [],
		"total_cost": RoadState.INF_COST,
		"total_distance_km": 0.0,
	}
