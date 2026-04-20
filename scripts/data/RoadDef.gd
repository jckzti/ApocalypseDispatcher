extends RefCounted
class_name RoadDef

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
	}


func validate() -> Array:
	var errors: Array = []
	if id.is_empty():
		errors.append("RoadDef sem campo obrigatorio 'id'.")
	if from_id.is_empty() or to_id.is_empty():
		errors.append("RoadDef '%s' precisa de campos 'from' e 'to'." % id)
	if length_km <= 0.0:
		errors.append("RoadDef '%s' precisa de length_km maior que zero." % id)
	return errors
