extends Node

const DEFAULT_LOCALE := "pt_BR"
const LOCALE_FILES := {
	"pt_BR": "res://data/localization/pt_BR.json",
	"en_US": "res://data/localization/en_US.json",
}

var _locale: String = DEFAULT_LOCALE
var _catalogs: Dictionary = {}


func _ready() -> void:
	_ensure_catalog_loaded(DEFAULT_LOCALE)
	var configured_locale := DEFAULT_LOCALE
	if SettingsService != null:
		configured_locale = String(SettingsService.get_setting(&"locale", DEFAULT_LOCALE))
	set_locale(configured_locale, false)


func get_supported_locales() -> Array:
	var locales: Array = LOCALE_FILES.keys()
	locales.sort()
	return locales


func get_locale() -> String:
	return _locale


func set_locale(locale: String, persist: bool = true) -> String:
	var normalized := locale if LOCALE_FILES.has(locale) else DEFAULT_LOCALE
	_ensure_catalog_loaded(DEFAULT_LOCALE)
	_ensure_catalog_loaded(normalized)
	_locale = normalized
	if persist and SettingsService != null:
		SettingsService.set_setting(&"locale", normalized)
	return _locale


func text(key: String, placeholders: Dictionary = {}) -> String:
	var current_catalog: Dictionary = Dictionary(_catalogs.get(_locale, {}))
	var fallback_catalog: Dictionary = Dictionary(_catalogs.get(DEFAULT_LOCALE, {}))
	var value := String(current_catalog.get(key, fallback_catalog.get(key, key)))
	for placeholder_key in placeholders.keys():
		value = value.replace("{%s}" % String(placeholder_key), str(placeholders[placeholder_key]))
	return value


func _ensure_catalog_loaded(locale: String) -> void:
	if _catalogs.has(locale):
		return
	var path := String(LOCALE_FILES.get(locale, ""))
	var catalog: Dictionary = {}
	if not path.is_empty() and FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var json := JSON.new()
			if json.parse(file.get_as_text()) == OK and json.data is Dictionary:
				catalog = Dictionary(json.data).duplicate(true)
			file.close()
	_catalogs[locale] = catalog
