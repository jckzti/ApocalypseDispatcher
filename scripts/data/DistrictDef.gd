extends RefCounted
class_name DistrictDef

const GameEnums = preload("res://scripts/core/GameEnums.gd")

var id: String = ""
var name: String = ""
var x: float = 0.0
var y: float = 0.0
var tags: Array = []
var population: Dictionary = {}
var panic: float = 0.0
var trust: float = 50.0
var danger: float = 0.0
var collapse: float = 0.0
var boarding_base_per_minute: int = 0
var is_shelter: bool = false
var shelter_capacity: int = 0


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	name = String(data.get("name", ""))
	x = float(data.get("x", 0.0))
	y = float(data.get("y", 0.0))
	tags = Array(data.get("tags", [])).duplicate(true)
	population = _normalize_population(Dictionary(data.get("population", {})))
	panic = float(data.get("panic", 0.0))
	trust = float(data.get("trust", 50.0))
	danger = float(data.get("danger", 0.0))
	collapse = float(data.get("collapse", 0.0))
	boarding_base_per_minute = int(data.get("boarding_base_per_minute", 0))
	is_shelter = bool(data.get("is_shelter", false))
	shelter_capacity = int(data.get("shelter_capacity", 0))


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"x": x,
		"y": y,
		"tags": tags.duplicate(true),
		"population": population.duplicate(true),
		"panic": panic,
		"trust": trust,
		"danger": danger,
		"collapse": collapse,
		"boarding_base_per_minute": boarding_base_per_minute,
		"is_shelter": is_shelter,
		"shelter_capacity": shelter_capacity,
	}


func validate() -> Array:
	var errors: Array = []
	if id.is_empty():
		errors.append("DistrictDef sem campo obrigatorio 'id'.")
	if name.is_empty():
		errors.append("DistrictDef '%s' sem campo obrigatorio 'name'." % id)
	if boarding_base_per_minute < 0:
		errors.append("DistrictDef '%s' possui boarding_base_per_minute negativo." % id)
	if is_shelter and shelter_capacity <= 0:
		errors.append("DistrictDef '%s' marcado como abrigo sem shelter_capacity positiva." % id)
	return errors


func _normalize_population(raw_population: Dictionary) -> Dictionary:
	var normalized := GameEnums.create_empty_population()
	for key in raw_population.keys():
		normalized[String(key)] = int(raw_population[key])
	return normalized
