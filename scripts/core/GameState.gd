extends RefCounted
class_name GameState

const DeterministicRng = preload("res://scripts/core/DeterministicRng.gd")
const GameConstants = preload("res://scripts/core/GameConstants.gd")
const GameEnums = preload("res://scripts/core/GameEnums.gd")
const SELF_PATH := "res://scripts/core/GameState.gd"

var seed: int = 1
var rng_state: int = 1
var elapsed_minutes: int = 0
var crisis_level: int = GameConstants.DEFAULT_CRISIS_LEVEL
var scenario_id: String = ""
var map_id: String = ""
var global_resources: Dictionary = {}
var global_metrics: Dictionary = {}
var district_states: Dictionary = {}
var road_states: Dictionary = {}
var shelter_states: Dictionary = {}
var bus_units: Dictionary = {}
var evacuation_orders: Dictionary = {}
var owned_cards: Dictionary = {}
var active_modifiers: Array = []
var scheduled_events: Array = []
var event_history: Array = []
var run_flags: Dictionary = {}
var score_state: Dictionary = {}
var command_history: Array = []


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary):
	seed = int(data.get("seed", seed))
	rng_state = int(data.get("rng_state", seed))
	elapsed_minutes = int(data.get("elapsed_minutes", elapsed_minutes))
	crisis_level = int(data.get("crisis_level", crisis_level))
	scenario_id = String(data.get("scenario_id", scenario_id))
	map_id = String(data.get("map_id", map_id))
	global_resources = _copy_dictionary(data.get("global_resources", GameEnums.create_empty_resources()))
	global_metrics = _copy_dictionary(data.get("global_metrics", GameConstants.DEFAULT_GLOBAL_METRICS))
	district_states = _copy_dictionary(data.get("district_states", {}))
	road_states = _copy_dictionary(data.get("road_states", {}))
	shelter_states = _copy_dictionary(data.get("shelter_states", {}))
	bus_units = _copy_dictionary(data.get("bus_units", {}))
	evacuation_orders = _copy_dictionary(data.get("evacuation_orders", {}))
	owned_cards = _copy_dictionary(data.get("owned_cards", {}))
	active_modifiers = Array(data.get("active_modifiers", [])).duplicate(true)
	scheduled_events = Array(data.get("scheduled_events", [])).duplicate(true)
	event_history = Array(data.get("event_history", [])).duplicate(true)
	run_flags = _copy_dictionary(data.get("run_flags", {
		"paused": false,
		"simulation_speed": GameConstants.DEFAULT_SIMULATION_SPEED,
	}))
	score_state = _copy_dictionary(data.get("score_state", GameConstants.DEFAULT_SCORE_STATE))
	command_history = Array(data.get("command_history", [])).duplicate(true)
	return self


func to_dictionary() -> Dictionary:
	return {
		"seed": seed,
		"rng_state": rng_state,
		"elapsed_minutes": elapsed_minutes,
		"crisis_level": crisis_level,
		"scenario_id": scenario_id,
		"map_id": map_id,
		"global_resources": _serialize_variant(global_resources),
		"global_metrics": _serialize_variant(global_metrics),
		"district_states": _serialize_variant(district_states),
		"road_states": _serialize_variant(road_states),
		"shelter_states": _serialize_variant(shelter_states),
		"bus_units": _serialize_variant(bus_units),
		"evacuation_orders": _serialize_variant(evacuation_orders),
		"owned_cards": _serialize_variant(owned_cards),
		"active_modifiers": _serialize_variant(active_modifiers),
		"scheduled_events": _serialize_variant(scheduled_events),
		"event_history": _serialize_variant(event_history),
		"run_flags": _serialize_variant(run_flags),
		"score_state": _serialize_variant(score_state),
		"command_history": _serialize_variant(command_history),
	}


func duplicate_state():
	return load(SELF_PATH).new(to_dictionary())


func sync_rng(rng) -> void:
	if rng == null:
		return
	seed = rng.get_seed()
	rng_state = rng.get_state()


func record_command(command: Dictionary) -> void:
	command_history.append(_serialize_variant(command))


func is_paused() -> bool:
	return bool(run_flags.get("paused", false))


func set_paused(value: bool) -> void:
	run_flags["paused"] = value


func get_simulation_speed() -> float:
	return float(run_flags.get("simulation_speed", GameConstants.DEFAULT_SIMULATION_SPEED))


func set_simulation_speed(value: float) -> void:
	run_flags["simulation_speed"] = value


static func create_initial(config):
	var owned_cards: Dictionary = {}
	for card_id in config.starting_cards:
		owned_cards[String(card_id)] = 1
	return load(SELF_PATH).new({
		"seed": config.seed,
		"rng_state": config.seed,
		"elapsed_minutes": 0,
		"crisis_level": config.crisis_level,
		"scenario_id": config.scenario_id,
		"map_id": config.map_id,
		"global_resources": config.starting_resources.duplicate(true),
		"global_metrics": GameConstants.DEFAULT_GLOBAL_METRICS.duplicate(true),
		"district_states": {},
		"road_states": {},
		"shelter_states": {},
		"bus_units": {},
		"evacuation_orders": {},
		"owned_cards": owned_cards,
		"active_modifiers": [],
		"scheduled_events": [],
		"event_history": [],
		"run_flags": {
		"paused": false,
		"simulation_speed": GameConstants.DEFAULT_SIMULATION_SPEED,
		},
		"score_state": GameConstants.DEFAULT_SCORE_STATE.duplicate(true),
		"command_history": [],
	})


func _copy_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return Dictionary(value).duplicate(true)
	return {}


func _serialize_variant(value: Variant) -> Variant:
	if value == null:
		return null
	if value is Dictionary:
		var serialized_dict: Dictionary = {}
		for key in value.keys():
			serialized_dict[String(key)] = _serialize_variant(value[key])
		return serialized_dict
	if value is Array:
		var serialized_array: Array = []
		for item in value:
			serialized_array.append(_serialize_variant(item))
		return serialized_array
	if value is Object and value.has_method("to_dictionary"):
		return _serialize_variant(value.to_dictionary())
	return value
