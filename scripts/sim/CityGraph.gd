extends RefCounted
class_name CityGraph

const DistrictState = preload("res://scripts/sim/DistrictState.gd")
const RoadState = preload("res://scripts/sim/RoadState.gd")
const ShelterState = preload("res://scripts/sim/ShelterState.gd")

var id: String = ""
var name: String = ""
var description: String = ""
var district_states: Dictionary = {}
var road_states: Dictionary = {}
var shelter_states: Dictionary = {}
var adjacency: Dictionary = {}


func _init(map_data: Dictionary = {}) -> void:
	if not map_data.is_empty():
		load_from_map_data(map_data)


func load_from_map_data(map_data: Dictionary) -> void:
	id = String(map_data.get("id", ""))
	name = String(map_data.get("name", ""))
	description = String(map_data.get("description", ""))
	district_states.clear()
	road_states.clear()
	shelter_states.clear()
	adjacency.clear()

	for district_data in Array(map_data.get("districts", [])):
		if not district_data is Dictionary:
			continue
		var district = DistrictState.new(district_data)
		district_states[district.id] = district
		adjacency[district.id] = []
		if district.is_shelter:
			shelter_states[district.id] = ShelterState.new({
				"id": district.id,
				"district_id": district.id,
				"capacity": district.shelter_capacity,
			})

	for road_data in Array(map_data.get("roads", [])):
		if not road_data is Dictionary:
			continue
		var road = RoadState.new(road_data)
		road_states[road.id] = road
		_add_edge(road.from_id, road.to_id, road.id)
		if not road.one_way:
			_add_edge(road.to_id, road.from_id, road.id)


func get_district(district_id: String):
	return district_states.get(district_id)


func get_road(road_id: String):
	return road_states.get(road_id)


func get_shelter(shelter_id: String):
	return shelter_states.get(shelter_id)


func get_neighbors(district_id: String) -> Array:
	if not adjacency.has(district_id):
		return []
	return Array(adjacency[district_id]).duplicate(true)


func get_shelter_ids() -> Array:
	var ids: Array = shelter_states.keys()
	ids.sort()
	return ids


func apply_to_game_state(state) -> void:
	state.district_states = district_states.duplicate(false)
	state.road_states = road_states.duplicate(false)
	state.shelter_states = shelter_states.duplicate(false)


func _add_edge(from_id: String, to_id: String, road_id: String) -> void:
	if not adjacency.has(from_id):
		adjacency[from_id] = []
	var edges: Array = Array(adjacency[from_id])
	edges.append({
		"to_id": to_id,
		"road_id": road_id,
	})
	adjacency[from_id] = edges
