extends RefCounted
class_name ContentValidator

const GameConstants = preload("res://scripts/core/GameConstants.gd")
const CardDef = preload("res://scripts/data/CardDef.gd")
const EventDef = preload("res://scripts/data/EventDef.gd")
const GameModeDef = preload("res://scripts/data/GameModeDef.gd")
const MapDef = preload("res://scripts/data/MapDef.gd")
const ScenarioDef = preload("res://scripts/data/ScenarioDef.gd")

const CATEGORY_SPECS := {
	"cards": {"dir": "cards", "ctor": CardDef},
	"events": {"dir": "events", "ctor": EventDef},
	"game_modes": {"dir": "game_modes", "ctor": GameModeDef},
	"maps": {"dir": "maps", "ctor": MapDef},
	"scenarios": {"dir": "scenarios", "ctor": ScenarioDef},
}


static func load_and_validate(root_path: String = GameConstants.CONTENT_ROOT) -> Dictionary:
	var result := {
		"cards": {},
		"events": {},
		"game_modes": {},
		"maps": {},
		"scenarios": {},
		"errors": [],
		"is_valid": false,
	}

	for category in CATEGORY_SPECS.keys():
		var loaded_category := _load_category(root_path, category)
		result[category] = loaded_category["items"]
		result["errors"].append_array(loaded_category["errors"])

	result["errors"].append_array(_validate_cross_references(result))
	result["is_valid"] = result["errors"].is_empty()
	return result


static func _load_category(root_path: String, category: String) -> Dictionary:
	var spec: Dictionary = CATEGORY_SPECS[category]
	var category_path := "%s/%s" % [root_path, String(spec["dir"])]
	var items: Dictionary = {}
	var errors: Array = []
	var dir := DirAccess.open(category_path)
	if dir == null:
		errors.append("%s: diretorio de conteudo nao encontrado." % category_path)
		return {"items": items, "errors": errors}

	var file_paths: Array = []
	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry.is_empty():
			break
		if entry.begins_with(".") or dir.current_is_dir() or not entry.ends_with(".json"):
			continue
		file_paths.append("%s/%s" % [category_path, entry])
	dir.list_dir_end()
	file_paths.sort()

	if file_paths.is_empty():
		errors.append("%s: nenhum arquivo JSON encontrado." % category_path)
		return {"items": items, "errors": errors}

	for file_path in file_paths:
		var parsed := _parse_json_file(file_path)
		errors.append_array(parsed["errors"])
		if not parsed["errors"].is_empty():
			continue

		var entries: Array = _normalize_entries(parsed["data"])
		for entry_data in entries:
			if not entry_data is Dictionary:
				errors.append("%s: cada item precisa ser um objeto JSON." % file_path)
				continue
			var def = spec["ctor"].new(entry_data)
			var entry_id := String(def.id)
			if entry_id.is_empty():
				errors.append("%s: item sem id." % file_path)
				continue
			if items.has(entry_id):
				errors.append("%s: id duplicado '%s' em %s." % [file_path, entry_id, category])
				continue
			items[entry_id] = def
			for error_message in def.validate():
				errors.append("%s: %s" % [file_path, error_message])
	return {"items": items, "errors": errors}


static func _parse_json_file(file_path: String) -> Dictionary:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {
			"data": null,
			"errors": ["%s: nao foi possivel abrir o arquivo." % file_path],
		}

	var text := file.get_as_text()
	var json := JSON.new()
	var parse_error := json.parse(text)
	if parse_error != OK:
		return {
			"data": null,
			"errors": [
				"%s: JSON invalido na linha %d: %s" % [
					file_path,
					json.get_error_line(),
					json.get_error_message(),
				]
			],
		}

	return {
		"data": json.data,
		"errors": [],
	}


static func _normalize_entries(data: Variant) -> Array:
	if data is Array:
		return Array(data)
	if data is Dictionary:
		return [data]
	return []


static func _validate_cross_references(content: Dictionary) -> Array:
	var errors: Array = []
	var cards: Dictionary = content.get("cards", {})
	var events: Dictionary = content.get("events", {})
	var game_modes: Dictionary = content.get("game_modes", {})
	var maps: Dictionary = content.get("maps", {})
	var scenarios: Dictionary = content.get("scenarios", {})

	for scenario in scenarios.values():
		if not game_modes.has(scenario.game_mode_id):
			errors.append("Scenario '%s' referencia game_mode_id inexistente '%s'." % [scenario.id, scenario.game_mode_id])
		if not maps.has(scenario.map_id):
			errors.append("Scenario '%s' referencia map_id inexistente '%s'." % [scenario.id, scenario.map_id])
		for card_id in scenario.starting_cards:
			if not cards.has(String(card_id)):
				errors.append("Scenario '%s' referencia carta inexistente '%s'." % [scenario.id, String(card_id)])
		for card_id in scenario.allowed_card_ids:
			if not cards.has(String(card_id)):
				errors.append("Scenario '%s' referencia carta permitida inexistente '%s'." % [scenario.id, String(card_id)])
		for event_id in scenario.allowed_event_ids:
			if not events.has(String(event_id)):
				errors.append("Scenario '%s' referencia evento inexistente '%s'." % [scenario.id, String(event_id)])
		var metadata: Dictionary = Dictionary(scenario.metadata)
		for source_scenario_id in Array(metadata.get("daily_source_pool", [])):
			if not scenarios.has(String(source_scenario_id)):
				errors.append("Scenario '%s' referencia source daily inexistente '%s'." % [scenario.id, String(source_scenario_id)])
		for raw_modifier in Array(metadata.get("daily_modifier_pool", [])):
			var modifier: Dictionary = Dictionary(raw_modifier)
			for card_id in Array(modifier.get("starting_cards_add", [])) + Array(modifier.get("allowed_card_ids_add", [])):
				if not cards.has(String(card_id)):
					errors.append("Scenario '%s' referencia carta diaria inexistente '%s'." % [scenario.id, String(card_id)])
			for event_id in Array(modifier.get("allowed_event_ids_add", [])) + Array(modifier.get("allowed_event_ids_remove", [])):
				if not events.has(String(event_id)):
					errors.append("Scenario '%s' referencia evento diario inexistente '%s'." % [scenario.id, String(event_id)])
	for game_mode in game_modes.values():
		for scenario_id in game_mode.scenario_pool:
			if not scenarios.has(String(scenario_id)):
				errors.append("GameMode '%s' referencia scenario inexistente '%s'." % [game_mode.id, String(scenario_id)])
		for card_id in game_mode.allowed_cards:
			if not cards.has(String(card_id)):
				errors.append("GameMode '%s' referencia carta permitida inexistente '%s'." % [game_mode.id, String(card_id)])
	return errors
