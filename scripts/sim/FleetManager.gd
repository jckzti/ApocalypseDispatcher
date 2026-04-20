extends RefCounted
class_name FleetManager

const RoadState = preload("res://scripts/sim/RoadState.gd")
const RoutePlanner = preload("res://scripts/sim/RoutePlanner.gd")
const PopulationModel = preload("res://scripts/sim/PopulationModel.gd")
const EvacuationResolver = preload("res://scripts/sim/EvacuationResolver.gd")

var route_planner
var population_model
var evacuation_resolver
var modifier_stack = null


func _init(route_planner_override = null, population_model_override = null, evacuation_resolver_override = null, modifier_stack_override = null) -> void:
	route_planner = route_planner_override if route_planner_override != null else RoutePlanner.new()
	population_model = population_model_override if population_model_override != null else PopulationModel.new(modifier_stack_override)
	evacuation_resolver = evacuation_resolver_override if evacuation_resolver_override != null else EvacuationResolver.new()
	modifier_stack = modifier_stack_override


func update(state, city_graph, minutes: int = 1) -> void:
	for _minute in range(minutes):
		var bus_ids: Array = state.bus_units.keys()
		bus_ids.sort()
		for bus_id in bus_ids:
			_update_bus(state.bus_units[bus_id], state, city_graph)


func _update_bus(bus, state, city_graph) -> void:
	var order = _resolve_order(bus, state)
	if order == null:
		return
	if not order.active:
		bus.state = "idle"
		return

	match bus.state:
		"idle":
			if bus.current_district_id == order.pickup_district_id:
				bus.state = "loading"
			else:
				_assign_route(bus, city_graph, bus.current_district_id, order.pickup_district_id, "to_pickup", order)
		"to_pickup":
			if _advance_travel(bus, city_graph):
				bus.state = "loading"
		"loading":
			var boarded: Dictionary = evacuation_resolver.load_bus(bus, order, city_graph, state, population_model)
			var boarded_total: int = _sum_population(boarded)
			var pickup_district = city_graph.get_district(order.pickup_district_id)
			var load_ratio: float = 0.0
			if bus.capacity > 0:
				load_ratio = float(bus.total_passengers()) / float(bus.capacity)
			if bus.total_passengers() > 0 and (load_ratio >= order.min_load_percent or bus.available_capacity() == 0 or pickup_district.total_population() == 0):
				_assign_route(bus, city_graph, order.pickup_district_id, order.dropoff_shelter_id, "to_dropoff", order)
			elif boarded_total == 0 and bus.total_passengers() > 0:
				_assign_route(bus, city_graph, order.pickup_district_id, order.dropoff_shelter_id, "to_dropoff", order)
		"to_dropoff":
			if _advance_travel(bus, city_graph):
				bus.state = "unloading"
		"unloading":
			evacuation_resolver.unload_bus(bus, order, city_graph, state)
			if order.repeat and _pickup_has_population(city_graph, order.pickup_district_id):
				_assign_route(bus, city_graph, order.dropoff_shelter_id, order.pickup_district_id, "to_pickup", order)
			else:
				order.active = false
				bus.assigned_order_id = ""
				bus.state = "idle"
		"disabled":
			return
		_:
			bus.state = "idle"


func _resolve_order(bus, state):
	if not bus.assigned_order_id.is_empty() and state.evacuation_orders.has(bus.assigned_order_id):
		return state.evacuation_orders[bus.assigned_order_id]

	var order_ids: Array = state.evacuation_orders.keys()
	order_ids.sort()
	for order_id in order_ids:
		var order = state.evacuation_orders[order_id]
		if order.assigned_bus_ids.has(bus.id):
			bus.assigned_order_id = order.id
			return order
	return null


func _assign_route(bus, city_graph, origin_id: String, destination_id: String, travel_state: String, order) -> void:
	var route: Dictionary = route_planner.find_route(city_graph, origin_id, destination_id, {
		"avoid_high_danger": order.avoid_high_danger,
		"allow_dangerous_roads": order.allow_dangerous_roads,
	})
	if not bool(route.get("reachable", false)):
		bus.state = "disabled"
		return
	if Array(route.get("road_ids", [])).is_empty():
		bus.current_district_id = destination_id
		bus.state = "loading" if travel_state == "to_pickup" else "unloading"
		return
	bus.set_route(route, travel_state)


func _advance_travel(bus, city_graph) -> bool:
	if bus.route_road_ids.is_empty():
		return true

	var distance_budget: float = bus.distance_per_minute()
	while distance_budget > 0.0 and bus.route_index < bus.route_road_ids.size():
		var road = city_graph.get_road(String(bus.route_road_ids[bus.route_index]))
		if road == null:
			bus.state = "disabled"
			return false

		var road_remaining: float = bus.current_segment_remaining_km
		if road_remaining <= 0.0:
			road_remaining = road.length_km

		var fuel_consumption_per_km: float = bus.fuel_consumption_per_km
		if modifier_stack != null:
			fuel_consumption_per_km = float(modifier_stack.apply_value("bus_fuel_consumption", bus.fuel_consumption_per_km, {"bus_id": bus.id}))

		var max_distance_by_fuel: float = 0.0
		if fuel_consumption_per_km > 0.0:
			max_distance_by_fuel = bus.fuel_current / fuel_consumption_per_km
		if max_distance_by_fuel <= 0.0:
			bus.state = "disabled"
			return false

		var traveled: float = minf(distance_budget, minf(road_remaining, max_distance_by_fuel))
		if traveled <= 0.0:
			bus.state = "disabled"
			return false

		bus.fuel_current = maxf(0.0, bus.fuel_current - (traveled * fuel_consumption_per_km))
		bus.driver_fatigue = minf(100.0, bus.driver_fatigue + (traveled * 0.8))
		bus.damage = minf(100.0, bus.damage + (road.danger * traveled * 0.03))
		road_remaining -= traveled
		distance_budget -= traveled

		if road_remaining <= 0.0001:
			bus.route_index += 1
			bus.current_segment_remaining_km = 0.0
			bus.current_road_id = ""
			if bus.route_index < bus.route_district_ids.size():
				bus.current_district_id = String(bus.route_district_ids[bus.route_index])
		else:
			bus.current_segment_remaining_km = road_remaining
			bus.current_road_id = road.id
			if bus.fuel_current <= 0.0:
				bus.state = "disabled"
				return false

	if bus.route_index >= bus.route_road_ids.size():
		if not bus.route_district_ids.is_empty():
			bus.current_district_id = String(bus.route_district_ids[bus.route_district_ids.size() - 1])
		bus.clear_route()
		return true
	return false


func _pickup_has_population(city_graph, pickup_district_id: String) -> bool:
	var district = city_graph.get_district(pickup_district_id)
	return district != null and district.total_population() > 0


func _sum_population(population: Dictionary) -> int:
	var total: int = 0
	for amount in population.values():
		total += int(amount)
	return total
