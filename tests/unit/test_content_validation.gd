extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const ContentValidator = preload("res://scripts/data/ContentValidator.gd")


func test_valid_content_loads_from_data_root() -> void:
	var content_db = ContentDbScript.new()
	var ok := content_db.load_content("res://data")

	assert_true(ok, "O conteudo padrao precisa carregar sem erro.")
	assert_true(content_db.has_loaded_content())
	assert_true(content_db.game_modes.size() >= 5)
	assert_not_null(content_db.get_map("tiny_map"))
	assert_not_null(content_db.get_scenario("campanha_tiny_map"))
	assert_not_null(content_db.get_scenario("desafio_diario"))
	assert_not_null(content_db.get_game_mode("campaign_standard"))
	assert_not_null(content_db.get_game_mode("daily_ops"))
	content_db.free()


func test_duplicate_ids_fail_with_clear_message() -> void:
	var result: Dictionary = ContentValidator.load_and_validate("res://tests/fixtures/content_invalid_duplicate")

	assert_false(bool(result.get("is_valid", false)))
	assert_true(_errors_joined(result).contains("id duplicado 'dup_card'"), "Duplicata de id deve ser reportada.")


func test_missing_references_fail_validation() -> void:
	var result: Dictionary = ContentValidator.load_and_validate("res://tests/fixtures/content_invalid_missing_refs")
	var error_blob := _errors_joined(result)

	assert_false(bool(result.get("is_valid", false)))
	assert_true(error_blob.contains("map_id inexistente 'map_inexistente'"))
	assert_true(error_blob.contains("carta inexistente 'card_inexistente'"))
	assert_true(error_blob.contains("evento inexistente 'event_inexistente'"))
	assert_true(error_blob.contains("game_mode_id inexistente 'modo_inexistente'"))


func test_invalid_json_reports_file_and_parse_error() -> void:
	var result: Dictionary = ContentValidator.load_and_validate("res://tests/fixtures/content_invalid_json")
	var error_blob := _errors_joined(result)

	assert_false(bool(result.get("is_valid", false)))
	assert_true(error_blob.contains("broken.json: JSON invalido"), "Erro de parse precisa citar o arquivo quebrado.")


func _errors_joined(result: Dictionary) -> String:
	return "\n".join(Array(result.get("errors", [])))
