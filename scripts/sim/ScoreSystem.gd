extends RefCounted
class_name ScoreSystem

const GameConstants = preload("res://scripts/core/GameConstants.gd")
const GameEnums = preload("res://scripts/core/GameEnums.gd")


func evaluate_run(state, scenario_def = null, city_graph = null, content_db = null) -> Dictionary:
	var end_state: Dictionary = evaluate_end_conditions(state, scenario_def, city_graph)
	var infinite_state := _infinite_state(state)
	var scenario_metadata := {} if scenario_def == null else Dictionary(scenario_def.metadata)
	var weighted_saved: float = _weighted_saved_population(state, city_graph)
	var weighted_deaths: float = _weighted_deaths(state, city_graph)
	var cards_score: int = _cards_score(state)
	var events_score: int = state.event_history.size() * 6
	var wave_score := int(infinite_state.get("wave_score", 0))
	var resource_score := int(round(
		float(state.global_resources.get("budget", 0)) * 1.2
		+ float(state.global_resources.get("fuel", 0)) * 0.05
		+ float(state.global_resources.get("trust", 0)) * 2.0
		+ float(state.global_resources.get("communication", 0)) * 1.25
	))
	var time_penalty := int(round(float(state.elapsed_minutes) * 0.65))
	var score: int = int(round(weighted_saved - (weighted_deaths * 2.0))) + cards_score + events_score + resource_score + wave_score - time_penalty
	var grade: String = _score_grade(score)

	var report := {
		"scenario_id": state.scenario_id,
		"scenario_name": "" if scenario_def == null else String(scenario_def.name),
		"seed": state.seed,
		"daily_key": String(scenario_metadata.get("daily_key", "")),
		"daily_mode": bool(scenario_metadata.get("daily_mode", false)),
		"daily_source_scenario_id": String(scenario_metadata.get("daily_source_scenario_id", "")),
		"daily_source_scenario_name": String(scenario_metadata.get("daily_source_scenario_name", "")),
		"daily_modifier_labels": Array(scenario_metadata.get("daily_modifier_labels", [])).duplicate(true),
		"elapsed_minutes": state.elapsed_minutes,
		"score": score,
		"grade": grade,
		"title": _report_title(score, grade, end_state),
		"end_reason": String(end_state.get("reason", "")),
		"run_over": bool(end_state.get("run_over", false)),
		"saved_population": int(state.global_metrics.get("saved_population", 0)),
		"dead_population": int(state.global_metrics.get("dead_population", 0)),
		"weighted_saved_score": int(round(weighted_saved)),
		"weighted_death_penalty": int(round(weighted_deaths * 2.0)),
		"cards_score": cards_score,
		"events_score": events_score,
		"wave_score": wave_score,
		"wave_reached": int(infinite_state.get("wave", 0)),
		"resource_score": resource_score,
		"time_penalty": time_penalty,
		"highlight_cards": _highlight_cards(state, content_db),
		"highlight_events": _highlight_events(state),
		"remaining_population": _remaining_population(city_graph),
		"collapsed_districts": _collapsed_districts(city_graph),
	}

	state.score_state = {
		"score": score,
		"run_over": bool(end_state.get("run_over", false)),
		"end_reason": String(end_state.get("reason", "")),
		"grade": grade,
	}
	return report


func evaluate_end_conditions(state, scenario_def = null, city_graph = null) -> Dictionary:
	if bool(state.score_state.get("run_over", false)):
		return {
			"run_over": true,
			"reason": String(state.score_state.get("end_reason", "restored_finished_run")),
		}

	var end_conditions: Dictionary = {} if scenario_def == null else scenario_def.end_conditions
	var infinite_mode := _is_infinite_mode(state, scenario_def)
	if int(end_conditions.get("max_minutes", -1)) >= 0 and state.elapsed_minutes >= int(end_conditions.get("max_minutes", -1)):
		return {"run_over": true, "reason": "time_limit"}
	if bool(end_conditions.get("command_center_lost", false)) and _is_command_center_lost(city_graph):
		return {"run_over": true, "reason": "command_center_lost"}
	if bool(end_conditions.get("all_shelters_lost", false)) and _all_shelters_lost(city_graph):
		return {"run_over": true, "reason": "all_shelters_lost"}
	if int(end_conditions.get("saved_population_at_least", -1)) >= 0 and int(state.global_metrics.get("saved_population", 0)) >= int(end_conditions.get("saved_population_at_least", -1)):
		return {"run_over": true, "reason": "tutorial_complete"}
	if int(end_conditions.get("event_history_count_at_least", -1)) >= 0 and state.event_history.size() >= int(end_conditions.get("event_history_count_at_least", -1)):
		return {"run_over": true, "reason": "scripted_events_complete"}
	if not infinite_mode and _all_evacuees_resolved(city_graph):
		return {"run_over": true, "reason": "all_population_resolved"}

	return {"run_over": false, "reason": ""}


func _weighted_saved_population(state, city_graph) -> float:
	if city_graph == null:
		return float(state.global_metrics.get("saved_population", 0))
	var total := 0.0
	for shelter in city_graph.shelter_states.values():
		for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
			total += float(shelter.occupants_by_cohort.get(cohort_key, 0)) * float(GameConstants.COHORT_SCORE_WEIGHT.get(cohort_key, 1.0))
	return total


func _weighted_deaths(state, city_graph) -> float:
	var total := 0.0
	if city_graph == null:
		return float(state.global_metrics.get("dead_population", 0))
	for district in city_graph.district_states.values():
		for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
			total += float(district.deaths_by_cohort.get(cohort_key, 0)) * float(GameConstants.COHORT_SCORE_WEIGHT.get(cohort_key, 1.0))
	return total


func _cards_score(state) -> int:
	var total := 0
	for level in state.owned_cards.values():
		total += int(level) * 8
	return total


func _highlight_cards(state, content_db = null) -> Array:
	var highlights: Array = []
	var card_ids: Array = state.owned_cards.keys()
	card_ids.sort()
	for card_id in card_ids:
		var level := int(state.owned_cards[card_id])
		if level <= 0:
			continue
		var label := "%s Nv.%d" % [String(card_id), level]
		if content_db != null:
			var card_def = content_db.get_card(String(card_id))
			if card_def != null:
				label = "%s Nv.%d" % [card_def.name, level]
		highlights.append(label)
	return highlights


func _highlight_events(state) -> Array:
	var highlights: Array = []
	for entry in state.event_history:
		if not entry is Dictionary:
			continue
		highlights.append("%s -> %s" % [
			String(entry.get("title", entry.get("event_id", "evento"))),
			String(entry.get("option_label", entry.get("option_id", "opcao"))),
		])
	return highlights


func _remaining_population(city_graph) -> int:
	if city_graph == null:
		return 0
	var total := 0
	for district in city_graph.district_states.values():
		if district.is_shelter:
			continue
		total += district.total_population()
	return total


func _collapsed_districts(city_graph) -> int:
	if city_graph == null:
		return 0
	var total := 0
	for district in city_graph.district_states.values():
		if district.is_collapsed():
			total += 1
	return total


func _report_title(score: int, grade: String, end_state: Dictionary) -> String:
	var end_reason := String(end_state.get("reason", ""))
	if end_reason == "tutorial_complete":
		return "Despachante Aprovado"
	if end_reason == "player_retired":
		return "Extracao Confirmada"
	if grade == "S":
		return "Arquivista do Fim"
	if grade == "A":
		return "Condutor do Ultimo Turno"
	if grade == "B":
		return "Chefe de Evacuacao"
	if grade == "C":
		return "Operador Exausto"
	if score < 0:
		return "Relatorio da Queda"
	return "Despachante da Ultima Linha"


func _score_grade(score: int) -> String:
	if score >= 2600:
		return "S"
	if score >= 1900:
		return "A"
	if score >= 1300:
		return "B"
	if score >= 750:
		return "C"
	return "D"


func _is_command_center_lost(city_graph) -> bool:
	if city_graph == null:
		return false
	for district in city_graph.district_states.values():
		if district.tags.has("command_center") and district.is_collapsed():
			return true
	return false


func _all_shelters_lost(city_graph) -> bool:
	if city_graph == null or city_graph.shelter_states.is_empty():
		return false
	for shelter_id in city_graph.shelter_states.keys():
		var district = city_graph.get_district(String(shelter_id))
		if district != null and not district.is_collapsed():
			return false
	return true


func _all_evacuees_resolved(city_graph) -> bool:
	if city_graph == null:
		return false
	for district in city_graph.district_states.values():
		if district.is_shelter:
			continue
		if district.total_population() > 0:
			return false
	return true


func _is_infinite_mode(state, scenario_def = null) -> bool:
	if scenario_def != null:
		return bool(Dictionary(scenario_def.metadata).get("infinite_mode", false))
	return bool(_infinite_state(state).get("enabled", false))


func _infinite_state(state) -> Dictionary:
	var infinite_state: Variant = state.run_flags.get("infinite_mode", {})
	if infinite_state is Dictionary:
		return Dictionary(infinite_state)
	return {}
