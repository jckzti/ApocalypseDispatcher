extends RefCounted
class_name EvacuationResolver

const GameEnums = preload("res://scripts/core/GameEnums.gd")


func load_bus(bus, order, city_graph, state, population_model) -> Dictionary:
	var boarded: Dictionary = GameEnums.create_empty_population()
	var district = city_graph.get_district(order.pickup_district_id)
	if district == null:
		return boarded
	boarded = population_model.board_population(district, bus.available_capacity(), order.priority_policy, state.global_resources)
	bus.add_passengers(boarded)
	return boarded


func unload_bus(bus, order, city_graph, state) -> Dictionary:
	var unloaded: Dictionary = GameEnums.create_empty_population()
	var shelter = city_graph.get_shelter(order.dropoff_shelter_id)
	if shelter == null:
		return unloaded

	var accepted: Dictionary = shelter.receive_population(bus.passengers)
	var total_unloaded: int = bus.remove_passengers(accepted)
	if total_unloaded > 0:
		state.global_metrics["saved_population"] = int(state.global_metrics.get("saved_population", 0)) + total_unloaded
		state.global_metrics["evacuated_population"] = int(state.global_metrics.get("evacuated_population", 0)) + total_unloaded
	return accepted
