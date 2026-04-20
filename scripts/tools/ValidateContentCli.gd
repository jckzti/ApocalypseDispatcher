extends SceneTree

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")


func _initialize() -> void:
	var root_path := _normalize_root_path(_parse_root_arg())
	var content_db = ContentDbScript.new()
	var ok := content_db.load_content(root_path)
	if not ok:
		for error_message in content_db.get_last_errors():
			printerr(error_message)
		content_db.free()
		quit(1)
		return

	print("Conteudo valido em %s." % root_path)
	print("Cards: %d | Events: %d | GameModes: %d | Maps: %d | Scenarios: %d" % [
		content_db.cards.size(),
		content_db.events.size(),
		content_db.game_modes.size(),
		content_db.maps.size(),
		content_db.scenarios.size(),
	])
	content_db.free()
	quit(0)


func _parse_root_arg() -> String:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--root="):
			return arg.trim_prefix("--root=")
	return "data"


func _normalize_root_path(value: String) -> String:
	if value.is_empty():
		return "res://data"
	if value.begins_with("res://"):
		return value
	if value.begins_with("res:/"):
		return value.replace("res:/", "res://")
	return "res://%s" % value.trim_prefix("/")
