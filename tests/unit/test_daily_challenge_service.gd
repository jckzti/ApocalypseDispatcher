extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const DailyChallengeService = preload("res://scripts/core/DailyChallengeService.gd")


func test_daily_challenge_runtime_is_stable_for_same_date() -> void:
	var content_db = ContentDbScript.new()
	assert_true(content_db.load_content("res://data"))

	var first = content_db.get_runtime_scenario("desafio_diario", {"daily_key": "2026-04-20"})
	var second = content_db.get_runtime_scenario("desafio_diario", {"daily_key": "2026-04-20"})

	assert_not_null(first)
	assert_not_null(second)
	assert_eq("daily_ops", String(first.game_mode_id))
	assert_true(bool(first.metadata.get("daily_mode", false)))
	assert_eq("2026-04-20", String(first.metadata.get("daily_key", "")))
	assert_eq(String(first.metadata.get("daily_source_scenario_id", "")), String(second.metadata.get("daily_source_scenario_id", "")))
	assert_eq(Array(first.metadata.get("daily_modifier_labels", [])), Array(second.metadata.get("daily_modifier_labels", [])))
	assert_eq(int(first.metadata.get("daily_seed", 0)), int(second.metadata.get("daily_seed", 0)))
	assert_eq(
		int(first.metadata.get("daily_seed", 0)),
		DailyChallengeService.resolve_seed_for_scenario(first, 999)
	)

	content_db.free()


func test_daily_challenge_can_rotate_by_date() -> void:
	var content_db = ContentDbScript.new()
	assert_true(content_db.load_content("res://data"))

	var today = content_db.get_runtime_scenario("desafio_diario", {"daily_key": "2026-04-20"})
	var tomorrow = content_db.get_runtime_scenario("desafio_diario", {"daily_key": "2026-04-21"})

	assert_not_null(today)
	assert_not_null(tomorrow)
	assert_ne(String(today.metadata.get("daily_key", "")), String(tomorrow.metadata.get("daily_key", "")))
	assert_ne(int(today.metadata.get("daily_seed", 0)), int(tomorrow.metadata.get("daily_seed", 0)))
	assert_true(Array(today.metadata.get("daily_modifier_labels", [])).size() >= 1)
	assert_true(Array(tomorrow.metadata.get("daily_modifier_labels", [])).size() >= 1)

	content_db.free()
