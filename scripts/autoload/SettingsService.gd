extends Node

var fullscreen_enabled := false

func get_setting(key: StringName, default_value = null):
	if key == &"fullscreen_enabled":
		return fullscreen_enabled
	return default_value
