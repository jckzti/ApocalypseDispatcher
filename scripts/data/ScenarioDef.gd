extends RefCounted
class_name ScenarioDef

var id: String = ""
var name: String = ""
var game_mode_id: String = "campaign_standard"
var map_id: String = ""
var starting_seed_mode: String = "random"
var starting_resources: Dictionary = {}
var starting_buses: Array = []
var starting_cards: Array = []
var allowed_card_ids: Array = []
var allowed_card_classes: Array = []
var allowed_event_ids: Array = []
var objectives: Array = []
var end_conditions: Dictionary = {}
var tutorial_steps: Array = []
var metadata: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	name = String(data.get("name", ""))
	game_mode_id = String(data.get("game_mode_id", data.get("mode_id", game_mode_id)))
	map_id = String(data.get("map_id", ""))
	starting_seed_mode = String(data.get("starting_seed_mode", "random"))
	starting_resources = Dictionary(data.get("starting_resources", {})).duplicate(true)
	starting_buses = Array(data.get("starting_buses", [])).duplicate(true)
	starting_cards = Array(data.get("starting_cards", [])).duplicate(true)
	allowed_card_ids = Array(data.get("allowed_card_ids", data.get("allowed_cards", []))).duplicate(true)
	allowed_card_classes = Array(data.get("allowed_card_classes", [])).duplicate(true)
	allowed_event_ids = Array(data.get("allowed_event_ids", [])).duplicate(true)
	objectives = Array(data.get("objectives", [])).duplicate(true)
	end_conditions = Dictionary(data.get("end_conditions", {})).duplicate(true)
	tutorial_steps = Array(data.get("tutorial_steps", [])).duplicate(true)
	metadata = Dictionary(data.get("metadata", {})).duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"game_mode_id": game_mode_id,
		"map_id": map_id,
		"starting_seed_mode": starting_seed_mode,
		"starting_resources": starting_resources.duplicate(true),
		"starting_buses": starting_buses.duplicate(true),
		"starting_cards": starting_cards.duplicate(true),
		"allowed_card_ids": allowed_card_ids.duplicate(true),
		"allowed_card_classes": allowed_card_classes.duplicate(true),
		"allowed_event_ids": allowed_event_ids.duplicate(true),
		"objectives": objectives.duplicate(true),
		"end_conditions": end_conditions.duplicate(true),
		"tutorial_steps": tutorial_steps.duplicate(true),
		"metadata": metadata.duplicate(true),
	}


func validate() -> Array:
	var errors: Array = []
	if id.is_empty():
		errors.append("ScenarioDef sem campo obrigatorio 'id'.")
	if name.is_empty():
		errors.append("ScenarioDef '%s' sem campo obrigatorio 'name'." % id)
	if game_mode_id.is_empty():
		errors.append("ScenarioDef '%s' sem campo obrigatorio 'game_mode_id'." % id)
	if map_id.is_empty():
		errors.append("ScenarioDef '%s' sem campo obrigatorio 'map_id'." % id)
	if starting_resources.is_empty():
		errors.append("ScenarioDef '%s' precisa de starting_resources." % id)
	if starting_buses.is_empty():
		errors.append("ScenarioDef '%s' precisa de ao menos um onibus inicial." % id)
	return errors


func create_runtime_copy(game_mode_def = null) -> ScenarioDef:
	var runtime_data: Dictionary = to_dictionary()
	if game_mode_def == null:
		return ScenarioDef.new(runtime_data)

	var merged_metadata := Dictionary(game_mode_def.ruleset_modifiers).duplicate(true)
	_deep_merge_dictionary(merged_metadata, metadata)
	merged_metadata["game_mode_id"] = String(game_mode_def.id)
	merged_metadata["game_mode_name"] = String(game_mode_def.name)
	merged_metadata["game_mode_tags"] = Array(game_mode_def.tags).duplicate(true)
	if not game_mode_def.reward_curve.is_empty():
		merged_metadata["reward_curve"] = Dictionary(game_mode_def.reward_curve).duplicate(true)

	runtime_data["metadata"] = merged_metadata
	runtime_data["objectives"] = _merge_array_copy(game_mode_def.objective_set, objectives)
	runtime_data["end_conditions"] = _merge_dictionary_copy(game_mode_def.end_condition_set, end_conditions)
	runtime_data["allowed_card_ids"] = _merge_unique_array(game_mode_def.allowed_cards, allowed_card_ids)
	runtime_data["allowed_card_classes"] = _merge_unique_array(game_mode_def.allowed_card_classes, allowed_card_classes)
	return ScenarioDef.new(runtime_data)


func _merge_array_copy(base_values: Array, override_values: Array) -> Array:
	var merged: Array = Array(base_values).duplicate(true)
	merged.append_array(Array(override_values).duplicate(true))
	return merged


func _merge_unique_array(base_values: Array, override_values: Array) -> Array:
	var merged: Array = []
	for raw_value in Array(base_values) + Array(override_values):
		var normalized := String(raw_value)
		if merged.has(normalized):
			continue
		merged.append(normalized)
	return merged


func _merge_dictionary_copy(base_values: Dictionary, override_values: Dictionary) -> Dictionary:
	var merged: Dictionary = Dictionary(base_values).duplicate(true)
	_deep_merge_dictionary(merged, Dictionary(override_values))
	return merged


func _deep_merge_dictionary(target: Dictionary, values: Dictionary) -> void:
	for key in values.keys():
		var existing = target.get(key)
		var incoming = values[key]
		if existing is Dictionary and incoming is Dictionary:
			var nested := Dictionary(existing).duplicate(true)
			_deep_merge_dictionary(nested, Dictionary(incoming))
			target[key] = nested
			continue
		target[key] = incoming
