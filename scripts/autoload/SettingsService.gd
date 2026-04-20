extends Node

const SETTINGS_PATH := "user://settings.json"
const DEFAULT_SETTINGS := {
	"fullscreen_enabled": false,
	"pause_on_event": true,
	"font_scale": 1.0,
	"colorblind_mode": false,
	"map_filter": "all",
	"locale": "pt_BR",
}

var _settings: Dictionary = DEFAULT_SETTINGS.duplicate(true)


func _ready() -> void:
	load_settings()


func get_setting(key: StringName, default_value = null):
	var normalized_key := String(key)
	if _settings.has(normalized_key):
		return _settings[normalized_key]
	if DEFAULT_SETTINGS.has(normalized_key):
		return DEFAULT_SETTINGS[normalized_key]
	return default_value


func set_setting(key: StringName, value, persist: bool = true) -> void:
	_settings[String(key)] = value
	if persist:
		save_settings()


func load_settings() -> Dictionary:
	_settings = DEFAULT_SETTINGS.duplicate(true)
	if not FileAccess.file_exists(SETTINGS_PATH):
		return _settings

	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return _settings
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK or not json.data is Dictionary:
		return _settings

	for key in Dictionary(json.data).keys():
		_settings[String(key)] = Dictionary(json.data)[key]
	return _settings


func save_settings() -> Dictionary:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://"))
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "path": SETTINGS_PATH}
	file.store_string(JSON.stringify(_settings, "\t"))
	file.close()
	return {"ok": true, "path": SETTINGS_PATH}
