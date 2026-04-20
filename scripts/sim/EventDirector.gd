extends RefCounted
class_name EventDirector

var content_db = null
var rng = null


func _init(content_db_override = null, rng_override = null) -> void:
	content_db = content_db_override
	rng = rng_override


func update(state, city_graph = null) -> Dictionary:
	if content_db == null or rng == null:
		return {}
	if not state.scheduled_events.is_empty():
		return {}

	var candidates := _eligible_events(state, city_graph)
	if candidates.is_empty():
		return {}

	var weights: Array = []
	for event_def in candidates:
		weights.append(float(event_def.weight))
	var picked_index: int = rng.pick_index(weights)
	if picked_index < 0 or picked_index >= candidates.size():
		return {}

	var event_def = candidates[picked_index]
	var queued_event := {
		"event_id": event_def.id,
		"title": event_def.title,
		"body": event_def.body,
		"options": event_def.options.duplicate(true),
		"queued_at": state.elapsed_minutes,
	}
	state.scheduled_events.append(queued_event)
	return queued_event


func choose_option(state, event_id: String, option_id: String, city_graph = null) -> Dictionary:
	if content_db == null:
		return {"ok": false, "reason": "missing_content_db"}
	var event_def = content_db.get_event(event_id)
	if event_def == null:
		return {"ok": false, "reason": "event_not_found"}

	var option = _find_option(event_def.options, option_id)
	if option.is_empty():
		return {"ok": false, "reason": "option_not_found"}
	if not _requirements_met(Dictionary(option.get("requirements", {})), state):
		return {"ok": false, "reason": "requirements_not_met"}

	_apply_effects(Dictionary(option.get("effects", {})), state, city_graph)
	_remove_queued_event(state, event_id)
	_store_cooldown(state, event_def)
	state.event_history.append({
		"event_id": event_def.id,
		"title": event_def.title,
		"option_id": option_id,
		"option_label": String(option.get("label", option_id)),
		"resolved_at": state.elapsed_minutes,
	})
	return {
		"ok": true,
		"event_id": event_def.id,
		"option_id": option_id,
	}


func _eligible_events(state, city_graph) -> Array:
	var eligible: Array = []
	var allowed_event_ids: Array = Array(state.run_flags.get("allowed_event_ids", [])).duplicate(true)
	var event_ids: Array = content_db.events.keys()
	event_ids.sort()
	for event_id in event_ids:
		var event_def = content_db.get_event(String(event_id))
		if event_def == null:
			continue
		if not allowed_event_ids.is_empty() and not allowed_event_ids.has(event_def.id):
			continue
		if state.crisis_level < event_def.min_crisis_level:
			continue
		if _is_on_cooldown(state, event_def.id):
			continue
		if not _trigger_matches(event_def, state, city_graph):
			continue
		eligible.append(event_def)
	return eligible


func _trigger_matches(event_def, state, city_graph) -> bool:
	var trigger: Dictionary = event_def.trigger
	if trigger.is_empty():
		return true
	if trigger.has("min_elapsed_minutes") and state.elapsed_minutes < int(trigger["min_elapsed_minutes"]):
		return false
	if trigger.has("max_elapsed_minutes") and state.elapsed_minutes > int(trigger["max_elapsed_minutes"]):
		return false
	if trigger.has("min_crisis_level") and state.crisis_level < int(trigger["min_crisis_level"]):
		return false
	if trigger.has("max_crisis_level") and state.crisis_level > int(trigger["max_crisis_level"]):
		return false
	if trigger.has("min_population_remaining"):
		var remaining_population := _total_population(city_graph)
		if remaining_population < int(trigger["min_population_remaining"]):
			return false
	return true


func _requirements_met(requirements: Dictionary, state) -> bool:
	for requirement_key in requirements.keys():
		var minimum_value := float(requirements[requirement_key])
		var current_value := float(state.global_resources.get(String(requirement_key), 0))
		if current_value < minimum_value:
			return false
	return true


func _apply_effects(effects: Dictionary, state, city_graph) -> void:
	for effect_key in effects.keys():
		var key := String(effect_key)
		var value = effects[effect_key]
		if key.ends_with("_add"):
			var stat_name := key.trim_suffix("_add")
			if state.global_resources.has(stat_name):
				state.global_resources[stat_name] = float(state.global_resources.get(stat_name, 0)) + float(value)
				continue
			if state.global_metrics.has(stat_name):
				state.global_metrics[stat_name] = float(state.global_metrics.get(stat_name, 0)) + float(value)
				continue
			if stat_name == "panic":
				_adjust_all_districts(city_graph, "panic", float(value))


func _adjust_all_districts(city_graph, field_name: String, delta: float) -> void:
	if city_graph == null:
		return
	for district in city_graph.district_states.values():
		district.set(field_name, district.get(field_name) + delta)


func _store_cooldown(state, event_def) -> void:
	if not state.run_flags.has("event_cooldowns") or not state.run_flags["event_cooldowns"] is Dictionary:
		state.run_flags["event_cooldowns"] = {}
	var cooldowns: Dictionary = state.run_flags["event_cooldowns"]
	cooldowns[event_def.id] = state.elapsed_minutes + event_def.cooldown_minutes
	state.run_flags["event_cooldowns"] = cooldowns


func _is_on_cooldown(state, event_id: String) -> bool:
	if not state.run_flags.has("event_cooldowns") or not state.run_flags["event_cooldowns"] is Dictionary:
		return false
	var cooldowns: Dictionary = state.run_flags["event_cooldowns"]
	return int(cooldowns.get(event_id, -1)) > state.elapsed_minutes


func _remove_queued_event(state, event_id: String) -> void:
	var remaining: Array = []
	for scheduled in state.scheduled_events:
		if String(scheduled.get("event_id", "")) != event_id:
			remaining.append(scheduled)
	state.scheduled_events = remaining


func _find_option(options: Array, option_id: String) -> Dictionary:
	for option in options:
		if option is Dictionary and String(option.get("id", "")) == option_id:
			return option
	return {}


func _total_population(city_graph) -> int:
	if city_graph == null:
		return 0
	var total := 0
	for district in city_graph.district_states.values():
		total += district.total_population()
	return total
