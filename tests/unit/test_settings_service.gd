extends "res://addons/gut/test.gd"

const SettingsServiceScript = preload("res://scripts/autoload/SettingsService.gd")
const TEST_SETTINGS_PATH := "user://settings.json"


func test_settings_service_persists_accessibility_preferences() -> void:
	_cleanup_settings()

	var writer = SettingsServiceScript.new()
	writer.load_settings()
	writer.set_setting(&"pause_on_event", false)
	writer.set_setting(&"font_scale", 1.15)
	writer.set_setting(&"colorblind_mode", true)
	writer.set_setting(&"map_filter", "high_danger")
	writer.set_setting(&"locale", "en_US")

	var reader = SettingsServiceScript.new()
	reader.load_settings()

	assert_false(bool(reader.get_setting(&"pause_on_event", true)))
	assert_eq(float(reader.get_setting(&"font_scale", 1.0)), 1.15)
	assert_true(bool(reader.get_setting(&"colorblind_mode", false)))
	assert_eq(String(reader.get_setting(&"map_filter", "all")), "high_danger")
	assert_eq(String(reader.get_setting(&"locale", "pt_BR")), "en_US")

	writer.free()
	reader.free()
	_cleanup_settings()


func _cleanup_settings() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SETTINGS_PATH)
	if FileAccess.file_exists(TEST_SETTINGS_PATH):
		DirAccess.remove_absolute(absolute_path)
