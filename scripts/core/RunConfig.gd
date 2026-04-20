extends RefCounted
class_name RunConfig

const GameConstants = preload("res://scripts/core/GameConstants.gd")
const GameEnums = preload("res://scripts/core/GameEnums.gd")
const SELF_PATH := "res://scripts/core/RunConfig.gd"

var seed: int = 1
var scenario_id: String = ""
var game_mode_id: String = "campaign_standard"
var map_id: String = ""
var crisis_level: int = GameConstants.DEFAULT_CRISIS_LEVEL
var starting_resources: Dictionary = {}
var starting_buses: Array = []
var starting_cards: Array = []
var allowed_card_ids: Array = []
var allowed_card_classes: Array = []
var allowed_event_ids: Array = []
var objectives: Array = []
var end_conditions: Dictionary = {}
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary):
	seed = int(data.get("seed", seed))
	scenario_id = String(data.get("scenario_id", data.get("id", scenario_id)))
	game_mode_id = String(data.get("game_mode_id", game_mode_id))
	map_id = String(data.get("map_id", map_id))
	crisis_level = int(data.get("crisis_level", crisis_level))
	starting_resources = _merge_defaults(GameEnums.create_empty_resources(), data.get("starting_resources", {}))
	starting_buses = Array(data.get("starting_buses", [])).duplicate(true)
	starting_cards = Array(data.get("starting_cards", [])).duplicate(true)
	allowed_card_ids = Array(data.get("allowed_card_ids", data.get("allowed_cards", []))).duplicate(true)
	allowed_card_classes = Array(data.get("allowed_card_classes", [])).duplicate(true)
	allowed_event_ids = Array(data.get("allowed_event_ids", [])).duplicate(true)
	objectives = Array(data.get("objectives", [])).duplicate(true)
	end_conditions = Dictionary(data.get("end_conditions", {})).duplicate(true)
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)
	return self


func to_dictionary() -> Dictionary:
	return {
		"seed": seed,
		"scenario_id": scenario_id,
		"game_mode_id": game_mode_id,
		"map_id": map_id,
		"crisis_level": crisis_level,
		"starting_resources": starting_resources.duplicate(true),
		"starting_buses": starting_buses.duplicate(true),
		"starting_cards": starting_cards.duplicate(true),
		"allowed_card_ids": allowed_card_ids.duplicate(true),
		"allowed_card_classes": allowed_card_classes.duplicate(true),
		"allowed_event_ids": allowed_event_ids.duplicate(true),
		"objectives": objectives.duplicate(true),
		"end_conditions": end_conditions.duplicate(true),
		"metadata": metadata.duplicate(true),
	}


func duplicate_config():
	return load(SELF_PATH).new(to_dictionary())


static func from_scenario_def(scenario_def: Object, seed_value: int):
	var data: Dictionary = {}
	if scenario_def != null and scenario_def.has_method("to_dictionary"):
		data = scenario_def.to_dictionary()
	data["seed"] = seed_value
	return load(SELF_PATH).new(data)


func _merge_defaults(defaults: Dictionary, values: Variant) -> Dictionary:
	var merged: Dictionary = defaults.duplicate(true)
	if values is Dictionary:
		for key in values.keys():
			merged[key] = values[key]
	return merged
