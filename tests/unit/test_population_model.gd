extends "res://addons/gut/test.gd"

const DistrictState = preload("res://scripts/sim/DistrictState.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const PopulationModel = preload("res://scripts/sim/PopulationModel.gd")


func test_children_first_boards_children_before_adults() -> void:
	var district := DistrictState.new({
		"id": "pickup",
		"name": "Pickup",
		"population": {
			"adults": 10,
			"children": 3,
			"elderly": 2,
			"patients": 1,
			"essential_staff": 0,
			"volunteer_drivers": 0,
			"high_influence": 0
		},
		"panic": 0,
		"trust": 60,
		"boarding_base_per_minute": 10
	})
	var model := PopulationModel.new()
	var boarded := model.board_population(district, 6, "children_first", {"communication": 0, "trust": 60})

	assert_eq(int(boarded["children"]), 3)
	assert_eq(int(boarded["elderly"]), 2)
	assert_eq(int(boarded["patients"]), 1)
	assert_eq(int(district.population["adults"]), 10)


func test_medical_first_boards_patients_first() -> void:
	var district := DistrictState.new({
		"id": "pickup",
		"name": "Pickup",
		"population": {
			"adults": 20,
			"children": 2,
			"elderly": 3,
			"patients": 4,
			"essential_staff": 0,
			"volunteer_drivers": 0,
			"high_influence": 0
		},
		"panic": 0,
		"trust": 55,
		"boarding_base_per_minute": 10
	})
	var model := PopulationModel.new()
	var boarded := model.board_population(district, 4, "medical_first", {"communication": 0, "trust": 55})

	assert_eq(int(boarded["patients"]), 4)
	assert_eq(int(district.population["patients"]), 0)


func test_high_danger_increases_deaths() -> void:
	var low_danger := DistrictState.new({
		"id": "low",
		"name": "Low",
		"population": {
			"adults": 300,
			"children": 40,
			"elderly": 30,
			"patients": 20,
			"essential_staff": 10,
			"volunteer_drivers": 0,
			"high_influence": 0
		},
		"panic": 20,
		"danger": 30,
		"boarding_base_per_minute": 5
	})
	var high_danger := DistrictState.new(low_danger.to_dictionary())
	high_danger.danger = 90.0
	var model := PopulationModel.new()

	var low_result := model.apply_attrition(low_danger, 10, {"medical_supplies": 0})
	var high_result := model.apply_attrition(high_danger, 10, {"medical_supplies": 0})

	assert_true(_sum_population(high_result) > _sum_population(low_result))


func test_panic_reduces_boarding_capacity() -> void:
	var calm := DistrictState.new({
		"id": "calm",
		"name": "Calm",
		"population": { "adults": 100, "children": 0, "elderly": 0, "patients": 0, "essential_staff": 0, "volunteer_drivers": 0, "high_influence": 0 },
		"panic": 10,
		"trust": 50,
		"boarding_base_per_minute": 40
	})
	var panic := DistrictState.new(calm.to_dictionary())
	panic.panic = 90.0
	var model := PopulationModel.new()

	assert_true(model.get_boarding_capacity(calm, {"communication": 0, "trust": 50}) > model.get_boarding_capacity(panic, {"communication": 0, "trust": 50}))


func test_attrition_modifier_can_reduce_losses() -> void:
	var base_district := DistrictState.new({
		"id": "base",
		"name": "Base",
		"population": {
			"adults": 200,
			"children": 50,
			"elderly": 40,
			"patients": 20,
			"essential_staff": 10,
			"volunteer_drivers": 0,
			"high_influence": 0
		},
		"panic": 35,
		"danger": 82,
		"boarding_base_per_minute": 5
	})
	var mitigated_district := DistrictState.new(base_district.to_dictionary())
	var base_model := PopulationModel.new()
	var stack := ModifierStack.new()
	stack.add_modifier({"stat": "attrition_rate", "op": "multiply", "value": 0.4})
	var mitigated_model := PopulationModel.new(stack)

	var base_result := base_model.apply_attrition(base_district, 10, {"medical_supplies": 0})
	var mitigated_result := mitigated_model.apply_attrition(mitigated_district, 10, {"medical_supplies": 0})

	assert_true(_sum_population(mitigated_result) < _sum_population(base_result))


func _sum_population(population: Dictionary) -> int:
	var total := 0
	for amount in population.values():
		total += int(amount)
	return total
