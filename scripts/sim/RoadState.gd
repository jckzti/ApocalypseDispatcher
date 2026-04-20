extends RefCounted
class_name RoadState

const GameConstants = preload("res://scripts/core/GameConstants.gd")

const INF_COST := 1.0e20

var id: String = ""
var from_id: String = ""
var to_id: String = ""
var length_km: float = 0.0
var traffic: float = 0.0
var blockade: float = 0.0
var danger: float = 0.0
var quality: float = 100.0
var one_way: bool = false
var tags: Array = []
var blocked_by_collapse: bool = false


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	from_id = String(data.get("from", ""))
	to_id = String(data.get("to", ""))
	length_km = float(data.get("length_km", 0.0))
	traffic = float(data.get("traffic", 0.0))
	blockade = float(data.get("blockade", 0.0))
	danger = float(data.get("danger", 0.0))
	quality = float(data.get("quality", 100.0))
	one_way = bool(data.get("one_way", false))
	tags = Array(data.get("tags", [])).duplicate(true)
	blocked_by_collapse = bool(data.get("blocked_by_collapse", false))


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"from": from_id,
		"to": to_id,
		"length_km": length_km,
		"traffic": traffic,
		"blockade": blockade,
		"danger": danger,
		"quality": quality,
		"one_way": one_way,
		"tags": tags.duplicate(true),
		"blocked_by_collapse": blocked_by_collapse,
	}


func travel_cost(options: Dictionary = {}) -> float:
	if blockade >= 100.0 and not bool(options.get("allow_blocked_roads", false)):
		return INF_COST

	var cost := length_km
	cost *= 1.0 + (traffic / 100.0)
	cost *= 1.0 + (danger / 100.0)
	cost *= 1.0 + (blockade / 100.0)
	cost *= 1.0 + maxf(0.0, 50.0 - quality) / 100.0

	if blocked_by_collapse:
		cost *= 5.0

	if bool(options.get("avoid_high_danger", false)) and danger >= float(options.get("danger_threshold", GameConstants.HIGH_DANGER_THRESHOLD)):
		if bool(options.get("allow_dangerous_roads", false)):
			cost *= 2.5
		else:
			cost *= 1000.0

	return cost
