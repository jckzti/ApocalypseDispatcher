extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const BusUnit = preload("res://scripts/sim/BusUnit.gd")
const EvacuationOrder = preload("res://scripts/sim/EvacuationOrder.gd")
const RoutePlanner = preload("res://scripts/sim/RoutePlanner.gd")
const PopulationModel = preload("res://scripts/sim/PopulationModel.gd")
const EvacuationResolver = preload("res://scripts/sim/EvacuationResolver.gd")
const FleetManager = preload("res://scripts/sim/FleetManager.gd")


func test_bus_completes_pickup_and_dropoff_route() -> void:
	var runtime = _create_runtime()
	var bus = BusUnit.new({
		"id": "bus_01",
		"capacity": 60,
		"fuel_max": 180,
		"fuel_current": 180,
		"speed_kmh": 38,
		"current_district_id": "centro",
	})
	var order = EvacuationOrder.new({
		"id": "order_01",
		"pickup_district_id": "centro",
		"dropoff_shelter_id": "terminal_oeste",
		"priority_policy": "balanced",
		"assigned_bus_ids": ["bus_01"],
		"repeat": false,
		"min_load_percent": 0.5,
	})
	runtime["state"].bus_units[bus.id] = bus
	runtime["state"].evacuation_orders[order.id] = order

	var fleet_manager = FleetManager.new(RoutePlanner.new(), PopulationModel.new(), EvacuationResolver.new())
	fleet_manager.update(runtime["state"], runtime["graph"], 20)

	var pickup_district = runtime["graph"].get_district("centro")
	assert_true(int(runtime["state"].global_metrics.get("saved_population", 0)) > 0)
	assert_true(pickup_district.total_population() < runtime["initial_population"])
	assert_true(bus.fuel_current < 180.0)
	assert_eq(bus.current_district_id, "terminal_oeste")
	assert_eq(bus.state, "idle")

	runtime["content_db"].free()


func test_bus_without_fuel_does_not_complete_route() -> void:
	var runtime = _create_runtime()
	var bus = BusUnit.new({
		"id": "bus_empty",
		"capacity": 40,
		"fuel_max": 20,
		"fuel_current": 1,
		"speed_kmh": 38,
		"current_district_id": "centro",
	})
	var order = EvacuationOrder.new({
		"id": "order_empty",
		"pickup_district_id": "centro",
		"dropoff_shelter_id": "terminal_oeste",
		"priority_policy": "balanced",
		"assigned_bus_ids": ["bus_empty"],
		"repeat": false,
		"min_load_percent": 0.5,
	})
	runtime["state"].bus_units[bus.id] = bus
	runtime["state"].evacuation_orders[order.id] = order

	var fleet_manager = FleetManager.new(RoutePlanner.new(), PopulationModel.new(), EvacuationResolver.new())
	fleet_manager.update(runtime["state"], runtime["graph"], 20)

	assert_eq(int(runtime["state"].global_metrics.get("saved_population", 0)), 0)
	assert_eq(bus.state, "disabled")
	assert_true(bus.current_district_id != "terminal_oeste")

	runtime["content_db"].free()


func _create_runtime() -> Dictionary:
	var content_db = ContentDbScript.new()
	var ok := content_db.load_content("res://data")
	assert_true(ok)

	var scenario_def = content_db.get_runtime_scenario("campanha_tiny_map")
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = 12345
	var state = GameState.create_initial(run_config)
	var graph = CityGraph.new(content_db.get_map("tiny_map").to_dictionary())
	graph.apply_to_game_state(state)
	var initial_population = graph.get_district("centro").total_population()

	return {
		"content_db": content_db,
		"state": state,
		"graph": graph,
		"initial_population": initial_population,
	}
