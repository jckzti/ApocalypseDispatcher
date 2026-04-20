extends RefCounted
class_name BusUnit

const GameEnums = preload("res://scripts/core/GameEnums.gd")

var id: String = ""
var name: String = ""
var capacity: int = 0
var fuel_current: float = 0.0
var fuel_max: float = 0.0
var fuel_consumption_per_km: float = 1.0
var speed_kmh: float = 30.0
var state: String = "idle"
var current_district_id: String = ""
var current_road_id: String = ""
var target_district_id: String = ""
var route_district_ids: Array = []
var route_road_ids: Array = []
var route_index: int = 0
var current_segment_remaining_km: float = 0.0
var damage: float = 0.0
var driver_fatigue: float = 0.0
var tags: Array = []
var active_modifiers: Array = []
var passengers: Dictionary = {}
var assigned_order_id: String = ""


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	name = String(data.get("name", id))
	capacity = int(data.get("capacity", data.get("capacity_base", 0)))
	fuel_max = float(data.get("fuel_max", 0.0))
	fuel_current = float(data.get("fuel_current", fuel_max))
	fuel_consumption_per_km = float(data.get("fuel_consumption_per_km", 1.0))
	speed_kmh = float(data.get("speed_kmh", 30.0))
	state = String(data.get("state", "idle"))
	current_district_id = String(data.get("current_district_id", data.get("district_id", "")))
	current_road_id = String(data.get("current_road_id", ""))
	target_district_id = String(data.get("target_district_id", ""))
	route_district_ids = Array(data.get("route_district_ids", [])).duplicate(true)
	route_road_ids = Array(data.get("route_road_ids", [])).duplicate(true)
	route_index = int(data.get("route_index", 0))
	current_segment_remaining_km = float(data.get("current_segment_remaining_km", 0.0))
	damage = float(data.get("damage", 0.0))
	driver_fatigue = float(data.get("driver_fatigue", 0.0))
	tags = Array(data.get("tags", [])).duplicate(true)
	active_modifiers = Array(data.get("active_modifiers", [])).duplicate(true)
	passengers = _normalize_population(Dictionary(data.get("passengers", {})))
	assigned_order_id = String(data.get("assigned_order_id", ""))


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"capacity": capacity,
		"fuel_current": fuel_current,
		"fuel_max": fuel_max,
		"fuel_consumption_per_km": fuel_consumption_per_km,
		"speed_kmh": speed_kmh,
		"state": state,
		"current_district_id": current_district_id,
		"current_road_id": current_road_id,
		"target_district_id": target_district_id,
		"route_district_ids": route_district_ids.duplicate(true),
		"route_road_ids": route_road_ids.duplicate(true),
		"route_index": route_index,
		"current_segment_remaining_km": current_segment_remaining_km,
		"damage": damage,
		"driver_fatigue": driver_fatigue,
		"tags": tags.duplicate(true),
		"active_modifiers": active_modifiers.duplicate(true),
		"passengers": passengers.duplicate(true),
		"assigned_order_id": assigned_order_id,
	}


func total_passengers() -> int:
	var total: int = 0
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		total += int(passengers.get(cohort_key, 0))
	return total


func available_capacity() -> int:
	return maxi(0, capacity - total_passengers())


func is_idle() -> bool:
	return state == "idle"


func add_passengers(boarded: Dictionary) -> int:
	var total_added: int = 0
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		var amount: int = maxi(0, int(boarded.get(cohort_key, 0)))
		if amount <= 0:
			continue
		passengers[cohort_key] = int(passengers.get(cohort_key, 0)) + amount
		total_added += amount
	return total_added


func remove_passengers(unloaded: Dictionary) -> int:
	var total_removed: int = 0
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		var amount: int = maxi(0, int(unloaded.get(cohort_key, 0)))
		if amount <= 0:
			continue
		var available: int = int(passengers.get(cohort_key, 0))
		var removed: int = mini(available, amount)
		passengers[cohort_key] = available - removed
		total_removed += removed
	return total_removed


func clear_route() -> void:
	route_district_ids.clear()
	route_road_ids.clear()
	route_index = 0
	current_segment_remaining_km = 0.0
	current_road_id = ""
	target_district_id = ""


func set_route(route: Dictionary, next_state: String) -> void:
	route_district_ids = Array(route.get("district_ids", [])).duplicate(true)
	route_road_ids = Array(route.get("road_ids", [])).duplicate(true)
	route_index = 0
	current_segment_remaining_km = 0.0
	current_road_id = ""
	target_district_id = String(route.get("destination_id", ""))
	state = next_state


func distance_per_minute() -> float:
	var fatigue_modifier: float = clampf(1.0 - (driver_fatigue / 200.0), 0.5, 1.0)
	var damage_modifier: float = clampf(1.0 - (damage / 150.0), 0.4, 1.0)
	return maxf(0.05, (speed_kmh / 60.0) * fatigue_modifier * damage_modifier)


func _normalize_population(raw_population: Dictionary) -> Dictionary:
	var normalized: Dictionary = GameEnums.create_empty_population()
	for key in raw_population.keys():
		normalized[String(key)] = int(raw_population[key])
	return normalized
