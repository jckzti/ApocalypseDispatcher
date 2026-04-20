extends RefCounted
class_name SimulationRunner

signal state_changed(snapshot: Dictionary)

const DeterministicRng = preload("res://scripts/core/DeterministicRng.gd")
const GameConstants = preload("res://scripts/core/GameConstants.gd")
const GameEnums = preload("res://scripts/core/GameEnums.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const CollapseDirector = preload("res://scripts/sim/CollapseDirector.gd")
const EventDirector = preload("res://scripts/sim/EventDirector.gd")
const EvacuationResolver = preload("res://scripts/sim/EvacuationResolver.gd")
const EvacuationOrder = preload("res://scripts/sim/EvacuationOrder.gd")
const FleetManager = preload("res://scripts/sim/FleetManager.gd")
const InfiniteModeDirector = preload("res://scripts/sim/InfiniteModeDirector.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const PopulationModel = preload("res://scripts/sim/PopulationModel.gd")
const RoutePlanner = preload("res://scripts/sim/RoutePlanner.gd")
const SimulationClock = preload("res://scripts/sim/SimulationClock.gd")
const BusUnit = preload("res://scripts/sim/BusUnit.gd")
const DistrictState = preload("res://scripts/sim/DistrictState.gd")
const RoadState = preload("res://scripts/sim/RoadState.gd")
const ShelterState = preload("res://scripts/sim/ShelterState.gd")

var config
var state
var clock
var rng
var city_graph = null
var modifier_stack = null
var collapse_director = null
var event_director = null
var population_model = null
var fleet_manager = null
var infinite_mode_director = null
var _pending_commands: Array = []


func _init(run_config, initial_state = null) -> void:
	config = run_config.duplicate_config()
	state = initial_state.duplicate_state() if initial_state != null else GameState.create_initial(config)
	_rehydrate_state_objects()
	clock = SimulationClock.new(state.elapsed_minutes)
	rng = DeterministicRng.new(state.seed)
	rng.set_state(state.rng_state)


func submit_command(command: Dictionary) -> void:
	_pending_commands.append(command.duplicate(true))


func advance(minutes: int) -> Dictionary:
	if minutes < 0:
		push_error("SimulationRunner.advance recebeu valor negativo.")
		return create_snapshot()

	for _unused_minute in range(minutes):
		_advance_one_minute()

	var snapshot: Dictionary = create_snapshot()
	state_changed.emit(snapshot)
	return snapshot


func create_snapshot() -> Dictionary:
	state.elapsed_minutes = clock.elapsed_minutes
	state.sync_rng(rng)
	if modifier_stack != null:
		state.active_modifiers = modifier_stack.to_array()
	return state.to_dictionary()


func configure_runtime(graph, modifier_stack_override = null, collapse_director_override = null, population_model_override = null, fleet_manager_override = null, event_director_override = null, content_db_override = null, infinite_mode_director_override = null) -> void:
	city_graph = graph
	if modifier_stack_override != null:
		modifier_stack = modifier_stack_override
	elif modifier_stack == null:
		modifier_stack = ModifierStack.new()

	collapse_director = collapse_director_override if collapse_director_override != null else CollapseDirector.new(modifier_stack)
	event_director = event_director_override if event_director_override != null else EventDirector.new(content_db_override, rng)
	population_model = population_model_override if population_model_override != null else PopulationModel.new(modifier_stack)
	fleet_manager = fleet_manager_override if fleet_manager_override != null else FleetManager.new(RoutePlanner.new(), population_model, EvacuationResolver.new(), modifier_stack)
	infinite_mode_director = infinite_mode_director_override if infinite_mode_director_override != null else InfiniteModeDirector.new(config.metadata, rng)
	if city_graph != null:
		city_graph.apply_to_game_state(state)
	if infinite_mode_director != null:
		infinite_mode_director.ensure_state(state)


func _advance_one_minute() -> void:
	if state.is_paused():
		return

	_process_pending_commands()
	clock.advance(GameConstants.DEFAULT_TICK_MINUTES)
	state.elapsed_minutes = clock.elapsed_minutes

	if modifier_stack != null:
		modifier_stack.advance(GameConstants.DEFAULT_TICK_MINUTES)
	if collapse_director != null and city_graph != null:
		collapse_director.update(state, city_graph, GameConstants.DEFAULT_TICK_MINUTES)
	if infinite_mode_director != null and city_graph != null:
		infinite_mode_director.update(state, city_graph, GameConstants.DEFAULT_TICK_MINUTES)
	if event_director != null and city_graph != null:
		event_director.update(state, city_graph)
	if fleet_manager != null and city_graph != null:
		fleet_manager.update(state, city_graph, GameConstants.DEFAULT_TICK_MINUTES)
	if population_model != null and city_graph != null:
		_apply_attrition_to_districts()
	state.sync_rng(rng)


func _process_pending_commands() -> void:
	if _pending_commands.is_empty():
		return

	for command in _pending_commands:
		var normalized: Dictionary = command.duplicate(true)
		var type_value: int = GameEnums.parse_command_type(normalized.get("type", GameEnums.CommandType.CREATE_EVACUATION_ORDER))
		normalized["type"] = GameEnums.command_type_to_key(type_value)
		match type_value:
			GameEnums.CommandType.PAUSE_SIMULATION:
				state.set_paused(bool(normalized.get("paused", true)))
			GameEnums.CommandType.SET_SIMULATION_SPEED:
				state.set_simulation_speed(maxf(0.0, float(normalized.get("speed", GameConstants.DEFAULT_SIMULATION_SPEED))))
			_:
				pass
		state.record_command(normalized)

	_pending_commands.clear()


func _apply_attrition_to_districts() -> void:
	var district_ids: Array = state.district_states.keys()
	district_ids.sort()
	for district_id in district_ids:
		var district = state.district_states[district_id]
		if district == null:
			continue
		var deaths: Dictionary = population_model.apply_attrition(district, GameConstants.DEFAULT_TICK_MINUTES, state.global_resources)
		state.global_metrics["dead_population"] = int(state.global_metrics.get("dead_population", 0)) + _sum_population(deaths)


func _sum_population(population: Dictionary) -> int:
	var total := 0
	for amount in population.values():
		total += int(amount)
	return total


func _rehydrate_state_objects() -> void:
	state.district_states = _rehydrate_dictionary(state.district_states, DistrictState)
	state.road_states = _rehydrate_dictionary(state.road_states, RoadState)
	state.shelter_states = _rehydrate_dictionary(state.shelter_states, ShelterState)
	state.bus_units = _rehydrate_dictionary(state.bus_units, BusUnit)
	state.evacuation_orders = _rehydrate_dictionary(state.evacuation_orders, EvacuationOrder)


func _rehydrate_dictionary(raw_dictionary: Dictionary, script_resource) -> Dictionary:
	var hydrated: Dictionary = {}
	var keys: Array = raw_dictionary.keys()
	keys.sort()
	for key in keys:
		var entry = raw_dictionary[key]
		if entry is Dictionary:
			hydrated[String(key)] = script_resource.new(Dictionary(entry))
		else:
			hydrated[String(key)] = entry
	return hydrated
