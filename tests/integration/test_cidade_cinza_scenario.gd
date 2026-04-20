extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const SimulationRunner = preload("res://scripts/sim/SimulationRunner.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const BusUnit = preload("res://scripts/sim/BusUnit.gd")
const EvacuationOrder = preload("res://scripts/sim/EvacuationOrder.gd")


func test_cidade_cinza_advances_with_multiple_orders() -> void:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)

	var scenario_def = content_db.get_runtime_scenario("campanha_01_cidade_cinza")
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = 808
	var state = GameState.create_initial(run_config)
	state.run_flags["allowed_event_ids"] = scenario_def.allowed_event_ids.duplicate(true)
	var graph = CityGraph.new(content_db.get_map(scenario_def.map_id).to_dictionary())
	graph.apply_to_game_state(state)
	var modifier_stack = ModifierStack.new()
	var runner = SimulationRunner.new(run_config, state)
	runner.configure_runtime(graph, modifier_stack, null, null, null, null, content_db)

	for bus_data in scenario_def.starting_buses:
		var bus = BusUnit.new(bus_data)
		bus.current_district_id = "comando_central"
		runner.state.bus_units[bus.id] = bus

	runner.state.evacuation_orders["order_01"] = EvacuationOrder.new({
		"id": "order_01",
		"pickup_district_id": "bairro_antenas",
		"dropoff_shelter_id": "estadio_norte",
		"assigned_bus_ids": ["bus_01"],
		"priority_policy": "children_first",
	})
	runner.state.evacuation_orders["order_02"] = EvacuationOrder.new({
		"id": "order_02",
		"pickup_district_id": "hospital_velho",
		"dropoff_shelter_id": "terminal_aurora",
		"assigned_bus_ids": ["bus_02"],
		"priority_policy": "medical_first",
	})
	runner.state.evacuation_orders["order_03"] = EvacuationOrder.new({
		"id": "order_03",
		"pickup_district_id": "conjunto_orvalho",
		"dropoff_shelter_id": "universidade_firme",
		"assigned_bus_ids": ["bus_03"],
		"priority_policy": "balanced",
	})
	runner.state.bus_units["bus_01"].assigned_order_id = "order_01"
	runner.state.bus_units["bus_02"].assigned_order_id = "order_02"
	runner.state.bus_units["bus_03"].assigned_order_id = "order_03"

	var initial_fuel := float(runner.state.global_resources.get("fuel", 0))
	runner.advance(40)

	assert_true(int(runner.state.global_metrics.get("saved_population", 0)) > 0)
	assert_true(int(graph.get_shelter("estadio_norte").total_occupants()) > 0 or int(graph.get_shelter("terminal_aurora").total_occupants()) > 0 or int(graph.get_shelter("universidade_firme").total_occupants()) > 0)
	assert_true(float(runner.state.bus_units["bus_01"].fuel_current) < float(runner.state.bus_units["bus_01"].fuel_max))
	assert_true(float(runner.state.global_resources.get("fuel", 0)) <= initial_fuel)

	content_db.free()
