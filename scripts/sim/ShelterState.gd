extends RefCounted
class_name ShelterState

const GameEnums = preload("res://scripts/core/GameEnums.gd")

var id: String = ""
var district_id: String = ""
var capacity: int = 0
var occupants_by_cohort: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	district_id = String(data.get("district_id", id))
	capacity = int(data.get("capacity", 0))
	occupants_by_cohort = _normalize_population(Dictionary(data.get("occupants_by_cohort", {})))


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"district_id": district_id,
		"capacity": capacity,
		"occupants_by_cohort": occupants_by_cohort.duplicate(true),
	}


func total_occupants() -> int:
	var total: int = 0
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		total += int(occupants_by_cohort.get(cohort_key, 0))
	return total


func available_capacity() -> int:
	return maxi(0, capacity - total_occupants())


func receive_population(incoming: Dictionary) -> Dictionary:
	var accepted: Dictionary = GameEnums.create_empty_population()
	var capacity_left: int = available_capacity()
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		if capacity_left <= 0:
			break
		var requested: int = maxi(0, int(incoming.get(cohort_key, 0)))
		var grant: int = mini(requested, capacity_left)
		if grant <= 0:
			continue
		accepted[cohort_key] = grant
		occupants_by_cohort[cohort_key] = int(occupants_by_cohort.get(cohort_key, 0)) + grant
		capacity_left -= grant
	return accepted


func _normalize_population(raw_population: Dictionary) -> Dictionary:
	var normalized: Dictionary = GameEnums.create_empty_population()
	for key in raw_population.keys():
		normalized[String(key)] = int(raw_population[key])
	return normalized
