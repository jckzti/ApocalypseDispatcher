extends RefCounted
class_name CardDef

const VALID_CLASSES := [
	"logistics",
	"engineering",
	"communications",
	"security",
	"medical",
	"civic",
	"black_market",
	"anomaly",
]

const VALID_RARITIES := [
	"common",
	"uncommon",
	"rare",
	"epic",
	"legendary",
	"anomalous",
]

var id: String = ""
var name: String = ""
var card_class: String = ""
var rarity: String = "common"
var tags: Array = []
var min_crisis_level: int = 0
var max_level: int = 1
var description: String = ""
var effects_by_level: Array = []
var requirements: Dictionary = {}
var exclusive_group: Variant = null
var flavor: String = ""


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	name = String(data.get("name", ""))
	card_class = String(data.get("class", ""))
	rarity = String(data.get("rarity", "common"))
	tags = Array(data.get("tags", [])).duplicate(true)
	min_crisis_level = int(data.get("min_crisis_level", 0))
	max_level = int(data.get("max_level", 1))
	description = String(data.get("description", ""))
	effects_by_level = Array(data.get("effects_by_level", [])).duplicate(true)
	requirements = Dictionary(data.get("requirements", {})).duplicate(true)
	exclusive_group = data.get("exclusive_group", null)
	flavor = String(data.get("flavor", ""))


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"name": name,
		"class": card_class,
		"rarity": rarity,
		"tags": tags.duplicate(true),
		"min_crisis_level": min_crisis_level,
		"max_level": max_level,
		"description": description,
		"effects_by_level": effects_by_level.duplicate(true),
		"requirements": requirements.duplicate(true),
		"exclusive_group": exclusive_group,
		"flavor": flavor,
	}


func validate() -> Array:
	var errors: Array = []
	if id.is_empty():
		errors.append("CardDef sem campo obrigatorio 'id'.")
	if name.is_empty():
		errors.append("CardDef '%s' sem campo obrigatorio 'name'." % id)
	if not VALID_CLASSES.has(card_class):
		errors.append("CardDef '%s' possui class invalida '%s'." % [id, card_class])
	if not VALID_RARITIES.has(rarity):
		errors.append("CardDef '%s' possui rarity invalida '%s'." % [id, rarity])
	if max_level <= 0:
		errors.append("CardDef '%s' precisa de max_level maior que zero." % id)
	if effects_by_level.is_empty():
		errors.append("CardDef '%s' precisa de ao menos um efeito em effects_by_level." % id)
	return errors
