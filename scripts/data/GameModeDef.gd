extends RefCounted
class_name GameModeDef

var id: String = ""
var name: String = ""
var description: String = ""
var scenario_pool: Array = []
var allowed_cards: Array = []
var allowed_card_classes: Array = []
var tags: Array = []
var ruleset_modifiers: Dictionary = {}
var objective_set: Array = []
var end_condition_set: Dictionary = {}
var reward_curve: Dictionary = {}


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	name = String(data.get("name", ""))
	description = String(data.get("description", ""))
	scenario_pool = Array(data.get("scenario_pool", [])).duplicate(true)
	allowed_cards = Array(data.get("allowed_cards", [])).duplicate(true)
	allowed_card_classes = Array(data.get("allowed_card_classes", [])).duplicate(true)
	tags = Array(data.get("tags", [])).duplicate(true)
	ruleset_modifiers = Dictionary(data.get("ruleset_modifiers", {})).duplicate(true)
	objective_set = Array(data.get("objective_set", [])).duplicate(true)
	end_condition_set = Dictionary(data.get("end_condition_set", {})).duplicate(true)
	reward_curve = Dictionary(data.get("reward_curve", {})).duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"description": description,
		"scenario_pool": scenario_pool.duplicate(true),
		"allowed_cards": allowed_cards.duplicate(true),
		"allowed_card_classes": allowed_card_classes.duplicate(true),
		"tags": tags.duplicate(true),
		"ruleset_modifiers": ruleset_modifiers.duplicate(true),
		"objective_set": objective_set.duplicate(true),
		"end_condition_set": end_condition_set.duplicate(true),
		"reward_curve": reward_curve.duplicate(true),
	}


func validate() -> Array:
	var errors: Array = []
	if id.is_empty():
		errors.append("GameModeDef sem campo obrigatorio 'id'.")
	if name.is_empty():
		errors.append("GameModeDef '%s' sem campo obrigatorio 'name'." % id)
	return errors
