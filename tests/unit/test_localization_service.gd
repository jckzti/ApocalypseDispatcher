extends "res://addons/gut/test.gd"

const LocalizationServiceScript = preload("res://scripts/autoload/LocalizationService.gd")


func test_localization_service_switches_locale_and_falls_back() -> void:
	var service = LocalizationServiceScript.new()
	assert_eq("en_US", service.set_locale("en_US", false))
	assert_eq("Save", service.text("ui.save"))
	assert_eq("missing.key", service.text("missing.key"))

	assert_eq("pt_BR", service.set_locale("unknown_locale", false))
	assert_eq("Salvar", service.text("ui.save"))

	service.free()
