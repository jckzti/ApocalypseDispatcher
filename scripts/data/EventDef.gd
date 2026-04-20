extends RefCounted
class_name EventDef

const VALID_CATEGORIES := [
	"collapse",
	"social",
	"route",
	"faction",
	"moral",
	"anomaly",
	"civic",
	"communication",
	"fleet",
	"engineering",
	"expansion",
	"medical",
	"security",
]

var id: String = ""
var title: String = ""
var body: String = ""
var category: String = ""
var tags: Array = []
var min_crisis_level: int = 0
var weight: int = 1
var cooldown_minutes: int = 0
var trigger: Dictionary = {}
var options: Array = []


func _init(data: Dictionary = {}) -> void:
	apply_dictionary(data)


func apply_dictionary(data: Dictionary) -> void:
	id = String(data.get("id", ""))
	title = String(data.get("title", ""))
	body = String(data.get("body", ""))
	category = String(data.get("category", ""))
	tags = Array(data.get("tags", [])).duplicate(true)
	min_crisis_level = int(data.get("min_crisis_level", 0))
	weight = int(data.get("weight", 1))
	cooldown_minutes = int(data.get("cooldown_minutes", 0))
	trigger = Dictionary(data.get("trigger", {})).duplicate(true)
	options = Array(data.get("options", [])).duplicate(true)


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"title": title,
		"body": body,
		"category": category,
		"tags": tags.duplicate(true),
		"min_crisis_level": min_crisis_level,
		"weight": weight,
		"cooldown_minutes": cooldown_minutes,
		"trigger": trigger.duplicate(true),
		"options": options.duplicate(true),
	}


func validate() -> Array:
	var errors: Array = []
	if id.is_empty():
		errors.append("EventDef sem campo obrigatorio 'id'.")
	if title.is_empty():
		errors.append("EventDef '%s' sem campo obrigatorio 'title'." % id)
	if not VALID_CATEGORIES.has(category):
		errors.append("EventDef '%s' possui category invalida '%s'." % [id, category])
	if weight <= 0:
		errors.append("EventDef '%s' precisa de weight maior que zero." % id)
	if options.is_empty():
		errors.append("EventDef '%s' precisa de ao menos uma opcao." % id)
	for option_index in range(options.size()):
		var option = options[option_index]
		if not option is Dictionary:
			errors.append("EventDef '%s' possui opcao %d invalida." % [id, option_index])
			continue
		var option_id := String(option.get("id", ""))
		var option_label := String(option.get("label", ""))
		if option_id.is_empty():
			errors.append("EventDef '%s' possui opcao sem 'id'." % id)
		if option_label.is_empty():
			errors.append("EventDef '%s' possui opcao '%s' sem 'label'." % [id, option_id])
	return errors
