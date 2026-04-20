extends "res://addons/gut/test.gd"

const DistrictState = preload("res://scripts/sim/DistrictState.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const PopulationModel = preload("res://scripts/sim/PopulationModel.gd")


func test_multiplicative_modifiers_compose_correctly() -> void:
	var stack := ModifierStack.new()
	stack.add_modifier({"stat": "boarding_rate", "op": "multiply", "value": 0.9})
	stack.add_modifier({"stat": "boarding_rate", "op": "multiply", "value": 0.8})

	assert_almost_eq(float(stack.apply_value("boarding_rate", 100.0)), 72.0)


func test_temporary_modifier_expires() -> void:
	var stack := ModifierStack.new()
	stack.add_modifier({"stat": "boarding_rate", "op": "add", "value": 10.0, "duration_minutes": 2})

	assert_eq(int(stack.apply_value("boarding_rate", 40)), 50)
	stack.advance(2)
	assert_eq(int(stack.apply_value("boarding_rate", 40)), 40)


func test_population_model_uses_modifier_stack_for_boarding() -> void:
	var district := DistrictState.new({
		"id": "pickup",
		"name": "Pickup",
		"population": { "adults": 100, "children": 0, "elderly": 0, "patients": 0, "essential_staff": 0, "volunteer_drivers": 0, "high_influence": 0 },
		"panic": 40,
		"trust": 50,
		"boarding_base_per_minute": 20
	})
	var stack := ModifierStack.new()
	stack.add_modifier({"stat": "district_panic", "op": "add", "value": -30.0, "scope": {"district_id": "pickup"}})
	stack.add_modifier({"stat": "boarding_rate", "op": "multiply", "value": 1.5, "scope": {"district_id": "pickup"}})

	var without_modifiers := PopulationModel.new()
	var with_modifiers := PopulationModel.new(stack)

	assert_true(with_modifiers.get_boarding_capacity(district, {"communication": 0, "trust": 50}) > without_modifiers.get_boarding_capacity(district, {"communication": 0, "trust": 50}))
