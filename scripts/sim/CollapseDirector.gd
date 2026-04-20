extends RefCounted
class_name CollapseDirector

const GameConstants = preload("res://scripts/core/GameConstants.gd")

var modifier_stack = null


func _init(modifier_stack_override = null) -> void:
	modifier_stack = modifier_stack_override


func update(state, city_graph, minutes: int = 1) -> void:
	for _minute in range(minutes):
		_advance_one_minute(state, city_graph)


func _advance_one_minute(state, city_graph) -> void:
	var district_ids: Array = city_graph.district_states.keys()
	district_ids.sort()
	var pending_danger: Dictionary = {}
	var pending_collapse: Dictionary = {}

	for district_id in district_ids:
		var district = city_graph.get_district(String(district_id))
		var neighbor_collapsed_count := _count_collapsed_neighbors(city_graph, district.id)
		var base_threat_rate: float = 0.45 + (float(state.crisis_level) * 0.2)
		if modifier_stack != null:
			base_threat_rate = float(modifier_stack.apply_value("collapse_base_threat_rate", base_threat_rate, {"district_id": district.id}))
		var danger_delta: float = base_threat_rate + (float(neighbor_collapsed_count) * 0.15)
		if modifier_stack != null:
			danger_delta = float(modifier_stack.apply_value("district_danger_delta", danger_delta, {"district_id": district.id}))
		pending_danger[district.id] = clampf(district.danger + danger_delta, 0.0, 100.0)

		var collapse_delta: float = maxf(0.0, float(pending_danger[district.id]) - 65.0) * 0.015
		if modifier_stack != null:
			collapse_delta = float(modifier_stack.apply_value("district_collapse_delta", collapse_delta, {"district_id": district.id}))
		pending_collapse[district.id] = clampf(district.collapse + collapse_delta, 0.0, 100.0)

	for district_id in district_ids:
		var district = city_graph.get_district(String(district_id))
		district.danger = float(pending_danger.get(district.id, district.danger))
		district.collapse = float(pending_collapse.get(district.id, district.collapse))

	_update_connected_roads(city_graph)
	_update_global_crisis_level(state, city_graph)


func _count_collapsed_neighbors(city_graph, district_id: String) -> int:
	var collapsed_neighbors := 0
	for edge in city_graph.get_neighbors(district_id):
		var neighbor = city_graph.get_district(String(edge.get("to_id", "")))
		if neighbor != null and neighbor.collapse >= 70.0:
			collapsed_neighbors += 1
	return collapsed_neighbors


func _update_connected_roads(city_graph) -> void:
	var road_ids: Array = city_graph.road_states.keys()
	road_ids.sort()
	for road_id in road_ids:
		var road = city_graph.get_road(String(road_id))
		var from_district = city_graph.get_district(road.from_id)
		var to_district = city_graph.get_district(road.to_id)
		var collapse_pressure := maxf(from_district.collapse if from_district != null else 0.0, to_district.collapse if to_district != null else 0.0)

		var blockade_delta := 0.0
		var danger_delta := 0.0
		if collapse_pressure >= 50.0:
			blockade_delta = 0.5 + ((collapse_pressure - 50.0) / 100.0)
			danger_delta = collapse_pressure * 0.01

		if modifier_stack != null:
			blockade_delta = float(modifier_stack.apply_value("road_blockade_from_collapse", blockade_delta, {"road_id": road.id}))
			danger_delta = float(modifier_stack.apply_value("road_danger_from_collapse", danger_delta, {"road_id": road.id}))

		road.blockade = clampf(road.blockade + blockade_delta, 0.0, 100.0)
		road.danger = clampf(road.danger + danger_delta, 0.0, 100.0)
		road.blocked_by_collapse = collapse_pressure >= 85.0


func _update_global_crisis_level(state, city_graph) -> void:
	var total_danger := 0.0
	var district_count := 0
	for district in city_graph.district_states.values():
		total_danger += district.danger
		district_count += 1
	if district_count <= 0:
		return
	var average_danger := total_danger / float(district_count)
	state.crisis_level = maxi(state.crisis_level, int(floor(average_danger / 20.0)))
