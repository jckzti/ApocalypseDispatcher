extends RefCounted
class_name DistrictState

const GameConstants = preload("res://scripts/core/GameConstants.gd")
const GameEnums = preload("res://scripts/core/GameEnums.gd")

var id: String = ""
var name: String = ""
var x: float = 0.0
var y: float = 0.0
var tags: Array = []
var population: Dictionary = {}
var deaths_by_cohort: Dictionary = {}
var panic: float = 0.0
var trust: float = 50.0
var danger: float = 0.0
var collapse: float = 0.0
var looting: float = 0.0
var misinformation: float = 0.0
var boarding_base_per_minute: int = 0
var infrastructure: float = 100.0
var is_shelter: bool = false
var shelter_capacity: int = 0
var flags: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	name = String(data.get("name", ""))
	x = float(data.get("x", 0.0))
	y = float(data.get("y", 0.0))
	tags = Array(data.get("tags", [])).duplicate(true)
	population = _normalize_population(Dictionary(data.get("population", {})))
	deaths_by_cohort = _normalize_population(Dictionary(data.get("deaths_by_cohort", {})))
	panic = float(data.get("panic", 0.0))
	trust = float(data.get("trust", 50.0))
	danger = float(data.get("danger", 0.0))
	collapse = float(data.get("collapse", 0.0))
	looting = float(data.get("looting", data.get("saque", 0.0)))
	misinformation = float(data.get("misinformation", data.get("desinformacao", 0.0)))
	boarding_base_per_minute = int(data.get("boarding_base_per_minute", 0))
	infrastructure = float(data.get("infrastructure", 100.0))
	is_shelter = bool(data.get("is_shelter", false))
	shelter_capacity = int(data.get("shelter_capacity", 0))
	flags = Dictionary(data.get("flags", {})).duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"x": x,
		"y": y,
		"tags": tags.duplicate(true),
		"population": population.duplicate(true),
		"deaths_by_cohort": deaths_by_cohort.duplicate(true),
		"panic": panic,
		"trust": trust,
		"danger": danger,
		"collapse": collapse,
		"looting": looting,
		"misinformation": misinformation,
		"boarding_base_per_minute": boarding_base_per_minute,
		"infrastructure": infrastructure,
		"is_shelter": is_shelter,
		"shelter_capacity": shelter_capacity,
		"flags": flags.duplicate(true),
	}


func total_population() -> int:
	var total: int = 0
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		total += int(population.get(cohort_key, 0))
	return total


func add_population(delta: Dictionary) -> int:
	var total_added: int = 0
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		var amount: int = maxi(0, int(delta.get(cohort_key, 0)))
		if amount <= 0:
			continue
		population[cohort_key] = int(population.get(cohort_key, 0)) + amount
		total_added += amount
	return total_added


func remove_population(cohort_key: String, amount: int) -> int:
	var normalized_amount: int = maxi(0, amount)
	var available: int = int(population.get(cohort_key, 0))
	var removed: int = mini(available, normalized_amount)
	population[cohort_key] = available - removed
	return removed


func record_deaths(deaths: Dictionary) -> int:
	var total_deaths: int = 0
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		var amount: int = maxi(0, int(deaths.get(cohort_key, 0)))
		if amount <= 0:
			continue
		deaths_by_cohort[cohort_key] = int(deaths_by_cohort.get(cohort_key, 0)) + amount
		total_deaths += amount
	return total_deaths


func is_collapsed() -> bool:
	return collapse >= GameConstants.COLLAPSE_THRESHOLD


func can_board() -> bool:
	return not is_collapsed() and total_population() > 0


func _normalize_population(raw_population: Dictionary) -> Dictionary:
	var normalized: Dictionary = GameEnums.create_empty_population()
	for key in raw_population.keys():
		normalized[String(key)] = int(raw_population[key])
	return normalized
