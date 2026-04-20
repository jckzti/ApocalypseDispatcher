extends RefCounted
class_name PopulationModel

const GameConstants = preload("res://scripts/core/GameConstants.gd")
const GameEnums = preload("res://scripts/core/GameEnums.gd")

var modifier_stack = null


func _init(modifier_stack_override = null) -> void:
	modifier_stack = modifier_stack_override


func get_boarding_capacity(district_state, global_resources: Dictionary = {}) -> int:
	if district_state == null or not district_state.can_board():
		return 0

	var effective_panic: float = district_state.panic
	var effective_boarding_base: float = float(district_state.boarding_base_per_minute)
	if modifier_stack != null:
		effective_panic = float(modifier_stack.apply_value("district_panic", district_state.panic, {"district_id": district_state.id}))
		effective_boarding_base = float(modifier_stack.apply_value("boarding_rate", float(district_state.boarding_base_per_minute), {"district_id": district_state.id}))

	var panic_modifier: float = maxf(0.15, 1.0 - (effective_panic / 100.0))
	var communication_modifier: float = 1.0 + (float(global_resources.get("communication", 0)) * 0.04)
	var global_trust: float = float(global_resources.get("trust", district_state.trust))
	var trust_modifier: float = clampf(0.6 + (((district_state.trust + global_trust) * 0.5) / 100.0), 0.4, 1.6)
	var effective_rate: float = effective_boarding_base * panic_modifier * communication_modifier * trust_modifier
	return maxi(0, int(floor(effective_rate)))


func board_population(district_state, bus_capacity: int, priority_policy: String, global_resources: Dictionary = {}) -> Dictionary:
	var boarded: Dictionary = GameEnums.create_empty_population()
	if district_state == null or bus_capacity <= 0:
		return boarded

	var boarding_limit: int = mini(bus_capacity, get_boarding_capacity(district_state, global_resources))
	if boarding_limit <= 0:
		return boarded

	var ordered_cohorts: Array = _priority_order(priority_policy)
	var remaining_capacity: int = boarding_limit
	for cohort_key in ordered_cohorts:
		remaining_capacity = _board_cohort(district_state, boarded, cohort_key, remaining_capacity)
		if remaining_capacity <= 0:
			return boarded

	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		if ordered_cohorts.has(cohort_key):
			continue
		remaining_capacity = _board_cohort(district_state, boarded, cohort_key, remaining_capacity)
		if remaining_capacity <= 0:
			break

	return boarded


func apply_attrition(district_state, minutes: int = 1, global_resources: Dictionary = {}) -> Dictionary:
	var deaths: Dictionary = GameEnums.create_empty_population()
	if district_state == null or minutes <= 0 or district_state.total_population() <= 0:
		return deaths

	var effective_danger: float = district_state.danger
	var effective_panic: float = district_state.panic
	if modifier_stack != null:
		effective_danger = float(modifier_stack.apply_value("district_danger", district_state.danger, {"district_id": district_state.id}))
		effective_panic = float(modifier_stack.apply_value("district_panic", district_state.panic, {"district_id": district_state.id}))

	var danger_factor: float = maxf(0.0, effective_danger - 25.0) / 75.0
	if danger_factor <= 0.0:
		return deaths

	var panic_factor: float = 1.0 + (effective_panic / 100.0)
	var medical_modifier: float = maxf(0.5, 1.0 - (float(global_resources.get("medical_supplies", 0)) * 0.02))
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		var available: int = int(district_state.population.get(cohort_key, 0))
		if available <= 0:
			continue
		var vulnerability: float = float(GameConstants.COHORT_VULNERABILITY.get(cohort_key, 1.0))
		var cohort_modifier: float = vulnerability
		if cohort_key == "patients" or cohort_key == "elderly":
			cohort_modifier *= medical_modifier
		var death_rate: float = 0.0015 * float(minutes) * danger_factor * panic_factor * cohort_modifier
		if modifier_stack != null:
			death_rate = float(modifier_stack.apply_value("attrition_rate", death_rate, {
				"district_id": district_state.id,
				"cohort": cohort_key,
			}))
		var loss: int = int(floor(float(available) * death_rate))
		if district_state.danger >= 75.0 and loss == 0 and available > 0 and cohort_modifier >= 1.4:
			loss = 1
		loss = district_state.remove_population(cohort_key, loss)
		if loss > 0:
			deaths[cohort_key] = loss

	district_state.record_deaths(deaths)
	return deaths


func _priority_order(priority_policy: String) -> Array:
	match priority_policy:
		"children_first":
			return ["children", "elderly", "patients", "essential_staff", "adults", "volunteer_drivers", "high_influence"]
		"medical_first":
			return ["patients", "elderly", "children", "essential_staff", "adults", "volunteer_drivers", "high_influence"]
		"essential_staff_first":
			return ["essential_staff", "volunteer_drivers", "adults", "children", "elderly", "patients", "high_influence"]
		"fastest_boarding":
			return ["adults", "volunteer_drivers", "essential_staff", "high_influence", "children", "elderly", "patients"]
		"political_pressure":
			return ["high_influence", "children", "elderly", "patients", "essential_staff", "adults", "volunteer_drivers"]
		_:
			return GameEnums.POPULATION_COHORT_KEYS.duplicate(true)


func _board_cohort(district_state, boarded: Dictionary, cohort_key: String, remaining_capacity: int) -> int:
	if remaining_capacity <= 0:
		return 0
	var available: int = int(district_state.population.get(cohort_key, 0))
	if available <= 0:
		return remaining_capacity
	var to_board: int = mini(available, remaining_capacity)
	var removed: int = district_state.remove_population(cohort_key, to_board)
	boarded[cohort_key] = int(boarded.get(cohort_key, 0)) + removed
	return remaining_capacity - removed
