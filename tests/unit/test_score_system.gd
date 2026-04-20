extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const ScoreSystem = preload("res://scripts/sim/ScoreSystem.gd")


func test_score_is_reproducible_for_same_state() -> void:
	var runtime_a = _create_runtime()
	var runtime_b = _create_runtime()
	var score_system = ScoreSystem.new()

	var report_a = score_system.evaluate_run(runtime_a["state"], runtime_a["scenario_def"], runtime_a["graph"], runtime_a["content_db"])
	var report_b = score_system.evaluate_run(runtime_b["state"], runtime_b["scenario_def"], runtime_b["graph"], runtime_b["content_db"])

	assert_eq(int(report_a.get("score", 0)), int(report_b.get("score", 0)))
	assert_eq(String(report_a.get("grade", "")), String(report_b.get("grade", "")))
	assert_eq(String(report_a.get("title", "")), String(report_b.get("title", "")))

	runtime_a["content_db"].free()
	runtime_b["content_db"].free()


func test_tutorial_end_condition_produces_complete_report() -> void:
	var runtime = _create_runtime()
	var score_system = ScoreSystem.new()

	var end_state = score_system.evaluate_end_conditions(runtime["state"], runtime["scenario_def"], runtime["graph"])
	assert_true(bool(end_state.get("run_over", false)))
	assert_eq(String(end_state.get("reason", "")), "tutorial_complete")

	var report = score_system.evaluate_run(runtime["state"], runtime["scenario_def"], runtime["graph"], runtime["content_db"])
	assert_true(bool(report.get("run_over", false)))
	assert_eq(String(report.get("end_reason", "")), "tutorial_complete")
	assert_eq(404, int(report.get("seed", 0)))
	assert_true(int(report.get("score", 0)) > 0)
	assert_true(not Array(report.get("highlight_cards", [])).is_empty())

	runtime["content_db"].free()


func _create_runtime() -> Dictionary:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)

	var scenario_def = content_db.get_runtime_scenario("campanha_tutorial_primeiras_rotas")
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = 404
	var state = GameState.create_initial(run_config)
	state.event_history = [
		{"event_id": "event_tutorial_radio_call", "title": "Radio da Defesa Civil", "option_id": "broadcast", "option_label": "Transmitir a mensagem oficial"}
	]
	state.owned_cards = {
		"card_public_map": 1,
		"card_tutorial_clipboards": 2,
	}
	state.global_metrics["saved_population"] = 130
	state.global_metrics["dead_population"] = 4
	state.elapsed_minutes = 9

	var graph = CityGraph.new(content_db.get_map(scenario_def.map_id).to_dictionary())
	graph.apply_to_game_state(state)
	graph.get_shelter("ginasio_seguro").occupants_by_cohort["children"] = 50
	graph.get_shelter("ginasio_seguro").occupants_by_cohort["adults"] = 62
	graph.get_shelter("ginasio_seguro").occupants_by_cohort["elderly"] = 12
	graph.get_shelter("ginasio_seguro").occupants_by_cohort["patients"] = 6
	graph.get_district("bairro_vista").deaths_by_cohort["elderly"] = 2
	graph.get_district("clinica_leste").deaths_by_cohort["patients"] = 2

	return {
		"content_db": content_db,
		"scenario_def": scenario_def,
		"state": state,
		"graph": graph,
	}
