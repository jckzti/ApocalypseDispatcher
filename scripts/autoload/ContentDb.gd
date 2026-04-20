extends Node

const ContentValidator = preload("res://scripts/data/ContentValidator.gd")
const DailyChallengeService = preload("res://scripts/core/DailyChallengeService.gd")
const GameConstants = preload("res://scripts/core/GameConstants.gd")

var cards: Dictionary = {}
var events: Dictionary = {}
var game_modes: Dictionary = {}
var maps: Dictionary = {}
var scenarios: Dictionary = {}
var last_errors: Array = []
var last_root_path: String = ""
var _loaded := false


func reset() -> void:
	cards.clear()
	events.clear()
	game_modes.clear()
	maps.clear()
	scenarios.clear()
	last_errors.clear()
	last_root_path = ""
	_loaded = false


func load_content(root_path: String = GameConstants.CONTENT_ROOT) -> bool:
	var result: Dictionary = ContentValidator.load_and_validate(root_path)
	last_root_path = root_path
	last_errors = Array(result.get("errors", [])).duplicate(true)
	_loaded = bool(result.get("is_valid", false))
	if not _loaded:
		cards.clear()
		events.clear()
		game_modes.clear()
		maps.clear()
		scenarios.clear()
		return false

	cards = Dictionary(result.get("cards", {})).duplicate(false)
	events = Dictionary(result.get("events", {})).duplicate(false)
	game_modes = Dictionary(result.get("game_modes", {})).duplicate(false)
	maps = Dictionary(result.get("maps", {})).duplicate(false)
	scenarios = Dictionary(result.get("scenarios", {})).duplicate(false)
	return true


func has_loaded_content() -> bool:
	return _loaded


func get_last_errors() -> Array:
	return last_errors.duplicate(true)


func get_card(card_id: String):
	return cards.get(card_id)


func get_event(event_id: String):
	return events.get(event_id)


func get_game_mode(game_mode_id: String):
	return game_modes.get(game_mode_id)


func get_map(map_id: String):
	return maps.get(map_id)


func get_scenario(scenario_id: String):
	return scenarios.get(scenario_id)


func resolve_scenario(scenario_def, context: Dictionary = {}):
	if scenario_def == null:
		return null
	var game_mode = get_game_mode(String(scenario_def.game_mode_id))
	var runtime_scenario = scenario_def
	if scenario_def.has_method("create_runtime_copy"):
		runtime_scenario = scenario_def.create_runtime_copy(game_mode)
	if bool(Dictionary(runtime_scenario.metadata).get("daily_mode", false)) and not bool(context.get("skip_daily", false)):
		return DailyChallengeService.resolve_runtime_scenario(self, runtime_scenario, context)
	return runtime_scenario


func get_runtime_scenario(scenario_id: String, context: Dictionary = {}):
	return resolve_scenario(get_scenario(scenario_id), context)
