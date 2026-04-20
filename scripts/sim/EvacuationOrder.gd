extends RefCounted
class_name EvacuationOrder

var id: String = ""
var pickup_district_id: String = ""
var dropoff_shelter_id: String = ""
var priority_policy: String = "balanced"
var assigned_bus_ids: Array = []
var active: bool = true
var repeat: bool = true
var min_load_percent: float = 0.5
var avoid_high_danger: bool = false
var allow_dangerous_roads: bool = false
var created_at_minute: int = 0


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	pickup_district_id = String(data.get("pickup_district_id", ""))
	dropoff_shelter_id = String(data.get("dropoff_shelter_id", ""))
	priority_policy = String(data.get("priority_policy", "balanced"))
	assigned_bus_ids = Array(data.get("assigned_bus_ids", [])).duplicate(true)
	active = bool(data.get("active", true))
	repeat = bool(data.get("repeat", true))
	min_load_percent = float(data.get("min_load_percent", 0.5))
	avoid_high_danger = bool(data.get("avoid_high_danger", false))
	allow_dangerous_roads = bool(data.get("allow_dangerous_roads", false))
	created_at_minute = int(data.get("created_at_minute", 0))


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"pickup_district_id": pickup_district_id,
		"dropoff_shelter_id": dropoff_shelter_id,
		"priority_policy": priority_policy,
		"assigned_bus_ids": assigned_bus_ids.duplicate(true),
		"active": active,
		"repeat": repeat,
		"min_load_percent": min_load_percent,
		"avoid_high_danger": avoid_high_danger,
		"allow_dangerous_roads": allow_dangerous_roads,
		"created_at_minute": created_at_minute,
	}
