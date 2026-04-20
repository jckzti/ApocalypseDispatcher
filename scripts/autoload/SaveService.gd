extends Node

const GameConstants = preload("res://scripts/core/GameConstants.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const SimulationRunner = preload("res://scripts/sim/SimulationRunner.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const BusUnit = preload("res://scripts/sim/BusUnit.gd")
const DistrictState = preload("res://scripts/sim/DistrictState.gd")
const EvacuationOrder = preload("res://scripts/sim/EvacuationOrder.gd")
const RoadState = preload("res://scripts/sim/RoadState.gd")
const ShelterState = preload("res://scripts/sim/ShelterState.gd")

const SAVE_DIR := "user://saves"
const RUN_SAVE_PATH := SAVE_DIR + "/current_run.json"
const AUTOSAVE_PATH := SAVE_DIR + "/autosave.json"
const PROFILE_PATH := "user://profile.json"
const HISTORY_LIMIT := 12


func is_available() -> bool:
	return true


func ensure_storage() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))


func get_manual_save_path() -> String:
	return RUN_SAVE_PATH


func get_autosave_path() -> String:
	return AUTOSAVE_PATH


func has_manual_save() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)


func has_autosave() -> bool:
	return FileAccess.file_exists(AUTOSAVE_PATH)


func build_run_payload(runner, scenario_def, ui_state: Dictionary = {}) -> Dictionary:
	var snapshot: Dictionary = {}
	if runner != null and runner.has_method("create_snapshot"):
		snapshot = runner.create_snapshot()
	return {
		"save_version": GameConstants.SAVE_VERSION,
		"game_version": GameConstants.GAME_VERSION,
		"saved_at_utc": Time.get_datetime_string_from_system(true, true),
		"scenario_id": "" if scenario_def == null else String(scenario_def.id),
		"scenario_name": "" if scenario_def == null else String(scenario_def.name),
		"run_config": {} if runner == null else runner.config.to_dictionary(),
		"state": snapshot,
		"ui_state": ui_state.duplicate(true),
	}


func save_run_payload(payload: Dictionary, path: String = RUN_SAVE_PATH) -> Dictionary:
	ensure_storage()
	return _write_json_file(path, _migrate_save_payload(payload))


func save_current_run(runner, scenario_def, ui_state: Dictionary = {}, path: String = RUN_SAVE_PATH) -> Dictionary:
	return save_run_payload(build_run_payload(runner, scenario_def, ui_state), path)


func autosave_current_run(runner, scenario_def, ui_state: Dictionary = {}) -> Dictionary:
	return save_current_run(runner, scenario_def, ui_state, AUTOSAVE_PATH)


func load_run_payload(path: String = RUN_SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "save_not_found", "path": path}
	var parsed := _read_json_file(path)
	if not bool(parsed.get("ok", false)):
		return parsed
	var save_data: Variant = parsed.get("data", {})
	if not save_data is Dictionary:
		return {"ok": false, "reason": "invalid_save_payload", "path": path}
	return {
		"ok": true,
		"path": path,
		"data": _migrate_save_payload(Dictionary(save_data)),
	}


func load_preferred_run_payload() -> Dictionary:
	if has_manual_save():
		var manual_result := load_run_payload(RUN_SAVE_PATH)
		if bool(manual_result.get("ok", false)):
			return manual_result
	if has_autosave():
		return load_run_payload(AUTOSAVE_PATH)
	return {"ok": false, "reason": "save_not_found"}


func rebuild_runtime_from_save(save_data: Dictionary, content_db) -> Dictionary:
	if content_db == null:
		return {"ok": false, "reason": "missing_content_db"}

	var migrated := _migrate_save_payload(save_data)
	var saved_state: Variant = migrated.get("state", {})
	if not saved_state is Dictionary:
		return {"ok": false, "reason": "missing_state"}

	var scenario_id := String(migrated.get("scenario_id", ""))
	var saved_run_config := Dictionary(migrated.get("run_config", {}))
	var saved_metadata := Dictionary(saved_run_config.get("metadata", {}))
	var scenario_context := {
		"daily_key": String(saved_metadata.get("daily_key", "")),
		"daily_seed": int(saved_metadata.get("daily_seed", 0)),
		"daily_source_scenario_id": String(saved_metadata.get("daily_source_scenario_id", "")),
	}
	var scenario_def = content_db.get_runtime_scenario(scenario_id, scenario_context)
	if scenario_def == null:
		return {"ok": false, "reason": "scenario_not_found", "scenario_id": scenario_id}

	var state := GameState.new(Dictionary(saved_state))
	state.district_states = _rehydrate_state_dictionary(Dictionary(saved_state.get("district_states", {})), DistrictState)
	state.road_states = _rehydrate_state_dictionary(Dictionary(saved_state.get("road_states", {})), RoadState)
	state.shelter_states = _rehydrate_state_dictionary(Dictionary(saved_state.get("shelter_states", {})), ShelterState)
	state.bus_units = _rehydrate_state_dictionary(Dictionary(saved_state.get("bus_units", {})), BusUnit)
	state.evacuation_orders = _rehydrate_state_dictionary(Dictionary(saved_state.get("evacuation_orders", {})), EvacuationOrder)

	if Array(state.run_flags.get("allowed_event_ids", [])).is_empty() and not scenario_def.allowed_event_ids.is_empty():
		state.run_flags["allowed_event_ids"] = scenario_def.allowed_event_ids.duplicate(true)

	var map_id := String(state.map_id if not state.map_id.is_empty() else scenario_def.map_id)
	var map_def = content_db.get_map(map_id)
	if map_def == null:
		return {"ok": false, "reason": "map_not_found", "map_id": map_id}

	var graph := CityGraph.new(map_def.to_dictionary())
	graph.district_states = state.district_states.duplicate(false)
	graph.road_states = state.road_states.duplicate(false)
	graph.shelter_states = state.shelter_states.duplicate(false)

	var modifier_stack := ModifierStack.new()
	modifier_stack.replace_from_array(Array(state.active_modifiers))

	var run_config_data := _merge_config_with_scenario(saved_run_config, scenario_def)
	var runner := SimulationRunner.new(RunConfig.new(run_config_data), state)
	runner.configure_runtime(graph, modifier_stack, null, null, null, null, content_db)

	return {
		"ok": true,
		"runner": runner,
		"graph": graph,
		"modifier_stack": modifier_stack,
		"scenario_def": scenario_def,
		"ui_state": Dictionary(migrated.get("ui_state", {})).duplicate(true),
		"save_data": migrated,
	}


func load_preferred_runtime(content_db) -> Dictionary:
	var payload_result := load_preferred_run_payload()
	if not bool(payload_result.get("ok", false)):
		return payload_result
	return rebuild_runtime_from_save(Dictionary(payload_result.get("data", {})), content_db)


func get_default_profile(content_db = null) -> Dictionary:
	var tutorial_id := _find_tutorial_scenario_id(content_db)
	var unlocked: Array = []
	if tutorial_id.is_empty():
		if content_db != null:
			unlocked = content_db.scenarios.keys()
			unlocked.sort()
	else:
		unlocked = [tutorial_id]
	return {
		"save_version": GameConstants.SAVE_VERSION,
		"game_version": GameConstants.GAME_VERSION,
		"tutorial_completed": false,
		"completed_runs": 0,
		"highest_score": 0,
		"unlocked_scenarios": unlocked,
		"seed_leaderboards": {},
		"daily_leaderboards": {},
		"run_history": [],
	}


func load_profile(content_db = null) -> Dictionary:
	ensure_storage()
	if not FileAccess.file_exists(PROFILE_PATH):
		return _normalize_profile(get_default_profile(content_db), content_db)
	var parsed := _read_json_file(PROFILE_PATH)
	if not bool(parsed.get("ok", false)):
		return _normalize_profile(get_default_profile(content_db), content_db)
	var profile_data: Variant = parsed.get("data", {})
	if not profile_data is Dictionary:
		return _normalize_profile(get_default_profile(content_db), content_db)
	return _normalize_profile(Dictionary(profile_data), content_db)


func save_profile(profile: Dictionary, content_db = null) -> Dictionary:
	ensure_storage()
	return _write_json_file(PROFILE_PATH, _normalize_profile(profile, content_db))


func unlock_scenario(scenario_id: String, content_db = null) -> Dictionary:
	var profile := load_profile(content_db)
	var unlocked: Array = Array(profile.get("unlocked_scenarios", [])).duplicate(true)
	if not unlocked.has(scenario_id):
		unlocked.append(scenario_id)
		unlocked.sort()
		profile["unlocked_scenarios"] = unlocked
	return save_profile(profile, content_db)


func mark_tutorial_completed(content_db = null, unlock_ids: Array = []) -> Dictionary:
	var profile := load_profile(content_db)
	profile["tutorial_completed"] = true
	var unlocked: Array = Array(profile.get("unlocked_scenarios", [])).duplicate(true)
	for unlock_id in unlock_ids:
		if not unlocked.has(String(unlock_id)):
			unlocked.append(String(unlock_id))
	unlocked.sort()
	profile["unlocked_scenarios"] = unlocked
	return save_profile(profile, content_db)


func record_run_result(report: Dictionary, content_db = null) -> Dictionary:
	var profile := load_profile(content_db)
	profile["completed_runs"] = int(profile.get("completed_runs", 0)) + 1
	profile["highest_score"] = maxi(int(profile.get("highest_score", 0)), int(report.get("score", 0)))

	var history: Array = Array(profile.get("run_history", [])).duplicate(true)
	history.insert(0, {
		"scenario_id": String(report.get("scenario_id", "")),
		"scenario_name": String(report.get("scenario_name", "")),
		"seed": int(report.get("seed", 0)),
		"daily_key": String(report.get("daily_key", "")),
		"score": int(report.get("score", 0)),
		"grade": String(report.get("grade", "")),
		"title": String(report.get("title", "")),
		"end_reason": String(report.get("end_reason", "")),
		"ended_at_utc": Time.get_datetime_string_from_system(true, true),
	})
	while history.size() > HISTORY_LIMIT:
		history.pop_back()
	profile["run_history"] = history
	profile["seed_leaderboards"] = _record_seed_leaderboard_entry(Dictionary(profile.get("seed_leaderboards", {})), report)
	profile["daily_leaderboards"] = _record_daily_leaderboard_entry(Dictionary(profile.get("daily_leaderboards", {})), report)

	return save_profile(profile, content_db)


func get_available_scenario_ids(content_db) -> Array:
	if content_db == null:
		return []
	var profile := load_profile(content_db)
	if bool(profile.get("tutorial_completed", false)):
		var all_ids: Array = content_db.scenarios.keys()
		all_ids.sort()
		return all_ids
	var unlocked: Array = Array(profile.get("unlocked_scenarios", [])).duplicate(true)
	var available: Array = []
	var scenario_ids: Array = content_db.scenarios.keys()
	scenario_ids.sort()
	for scenario_id in scenario_ids:
		if unlocked.is_empty() or unlocked.has(scenario_id):
			available.append(scenario_id)
	return available


func get_preferred_scenario_id(content_db) -> String:
	var available: Array = get_available_scenario_ids(content_db)
	if available.is_empty():
		return ""
	var tutorial_id := _find_tutorial_scenario_id(content_db)
	var profile := load_profile(content_db)
	if not bool(profile.get("tutorial_completed", false)) and not tutorial_id.is_empty() and available.has(tutorial_id):
		return tutorial_id
	return String(available[0])


func _normalize_profile(profile: Dictionary, content_db = null) -> Dictionary:
	var normalized := get_default_profile(content_db)
	for key in profile.keys():
		normalized[key] = profile[key]
	normalized["save_version"] = int(normalized.get("save_version", GameConstants.SAVE_VERSION))
	normalized["game_version"] = String(normalized.get("game_version", GameConstants.GAME_VERSION))
	normalized["tutorial_completed"] = bool(normalized.get("tutorial_completed", false))
	normalized["completed_runs"] = maxi(0, int(normalized.get("completed_runs", 0)))
	normalized["highest_score"] = maxi(0, int(normalized.get("highest_score", 0)))
	normalized["run_history"] = Array(normalized.get("run_history", [])).duplicate(true)
	normalized["seed_leaderboards"] = Dictionary(normalized.get("seed_leaderboards", {})).duplicate(true)
	normalized["daily_leaderboards"] = Dictionary(normalized.get("daily_leaderboards", {})).duplicate(true)

	var unlocked: Array = Array(normalized.get("unlocked_scenarios", [])).duplicate(true)
	if content_db != null:
		var known_ids: Array = content_db.scenarios.keys()
		known_ids.sort()
		if bool(normalized.get("tutorial_completed", false)):
			unlocked = known_ids.duplicate(true)
		else:
			unlocked = unlocked.filter(func(value): return known_ids.has(String(value)))
		if unlocked.is_empty():
			unlocked = get_default_profile(content_db)["unlocked_scenarios"]
	unlocked.sort()
	normalized["unlocked_scenarios"] = unlocked
	return normalized


func _find_tutorial_scenario_id(content_db) -> String:
	if content_db == null:
		return ""
	var scenario_ids: Array = content_db.scenarios.keys()
	scenario_ids.sort()
	for scenario_id in scenario_ids:
		var resolved = content_db.get_runtime_scenario(String(scenario_id))
		var mode_tags: Array = []
		if resolved != null:
			mode_tags = Array(Dictionary(resolved.metadata).get("game_mode_tags", []))
		if mode_tags.has("tutorial") or String(scenario_id).findn("tutorial") != -1:
			return String(scenario_id)
	return ""


func get_seed_leaderboard(content_db, scenario_id: String, limit: int = 5) -> Array:
	if scenario_id.is_empty():
		return []
	var profile := load_profile(content_db)
	var leaderboards: Dictionary = Dictionary(profile.get("seed_leaderboards", {}))
	var entries: Array = Array(leaderboards.get(scenario_id, [])).duplicate(true)
	if limit <= 0 or entries.size() <= limit:
		return entries
	return entries.slice(0, limit)


func get_daily_leaderboard(content_db, scenario_id: String, daily_key: String, limit: int = 5) -> Array:
	if scenario_id.is_empty() or daily_key.is_empty():
		return []
	var profile := load_profile(content_db)
	var leaderboards: Dictionary = Dictionary(profile.get("daily_leaderboards", {}))
	var entries: Array = Array(leaderboards.get(_daily_leaderboard_key(scenario_id, daily_key), [])).duplicate(true)
	if limit <= 0 or entries.size() <= limit:
		return entries
	return entries.slice(0, limit)


func _merge_config_with_scenario(saved_config: Dictionary, scenario_def) -> Dictionary:
	var merged: Dictionary = scenario_def.to_dictionary()
	merged["scenario_id"] = scenario_def.id
	for key in saved_config.keys():
		merged[key] = saved_config[key]
	if String(merged.get("scenario_id", "")).is_empty():
		merged["scenario_id"] = scenario_def.id
	if String(merged.get("map_id", "")).is_empty():
		merged["map_id"] = scenario_def.map_id
	return merged


func _record_seed_leaderboard_entry(existing_leaderboards: Dictionary, report: Dictionary) -> Dictionary:
	var scenario_id := String(report.get("scenario_id", ""))
	if scenario_id.is_empty():
		return existing_leaderboards

	var entries: Array = Array(existing_leaderboards.get(scenario_id, [])).duplicate(true)
	var candidate := {
		"scenario_id": scenario_id,
		"scenario_name": String(report.get("scenario_name", "")),
		"seed": int(report.get("seed", 0)),
		"score": int(report.get("score", 0)),
		"grade": String(report.get("grade", "")),
		"title": String(report.get("title", "")),
		"end_reason": String(report.get("end_reason", "")),
		"elapsed_minutes": int(report.get("elapsed_minutes", 0)),
		"ended_at_utc": Time.get_datetime_string_from_system(true, true),
	}

	var replaced := false
	for index in range(entries.size()):
		var entry: Dictionary = Dictionary(entries[index])
		if int(entry.get("seed", -1)) != int(candidate.get("seed", -2)):
			continue
		if _is_better_seed_entry(candidate, entry):
			entries[index] = candidate
		replaced = true
		break

	if not replaced:
		entries.append(candidate)

	entries.sort_custom(func(a, b): return _is_better_seed_entry(Dictionary(a), Dictionary(b)))
	while entries.size() > 10:
		entries.pop_back()
	existing_leaderboards[scenario_id] = entries
	return existing_leaderboards


func _record_daily_leaderboard_entry(existing_leaderboards: Dictionary, report: Dictionary) -> Dictionary:
	var scenario_id := String(report.get("scenario_id", ""))
	var daily_key := String(report.get("daily_key", ""))
	if scenario_id.is_empty() or daily_key.is_empty():
		return existing_leaderboards

	var storage_key := _daily_leaderboard_key(scenario_id, daily_key)
	var entries: Array = Array(existing_leaderboards.get(storage_key, [])).duplicate(true)
	var candidate := {
		"scenario_id": scenario_id,
		"scenario_name": String(report.get("scenario_name", "")),
		"seed": int(report.get("seed", 0)),
		"daily_key": daily_key,
		"score": int(report.get("score", 0)),
		"grade": String(report.get("grade", "")),
		"title": String(report.get("title", "")),
		"end_reason": String(report.get("end_reason", "")),
		"elapsed_minutes": int(report.get("elapsed_minutes", 0)),
		"ended_at_utc": Time.get_datetime_string_from_system(true, true),
	}

	var replaced := false
	for index in range(entries.size()):
		var entry: Dictionary = Dictionary(entries[index])
		if int(entry.get("seed", -1)) != int(candidate.get("seed", -2)):
			continue
		if _is_better_seed_entry(candidate, entry):
			entries[index] = candidate
		replaced = true
		break

	if not replaced:
		entries.append(candidate)

	entries.sort_custom(func(a, b): return _is_better_seed_entry(Dictionary(a), Dictionary(b)))
	while entries.size() > 10:
		entries.pop_back()
	existing_leaderboards[storage_key] = entries
	return existing_leaderboards


func _daily_leaderboard_key(scenario_id: String, daily_key: String) -> String:
	return "%s@%s" % [scenario_id, daily_key]


func _is_better_seed_entry(left: Dictionary, right: Dictionary) -> bool:
	var left_score := int(left.get("score", 0))
	var right_score := int(right.get("score", 0))
	if left_score != right_score:
		return left_score > right_score
	var left_time := int(left.get("elapsed_minutes", 0))
	var right_time := int(right.get("elapsed_minutes", 0))
	if left_time != right_time:
		return left_time < right_time
	return int(left.get("seed", 0)) < int(right.get("seed", 0))


func _migrate_save_payload(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	migrated["save_version"] = int(migrated.get("save_version", GameConstants.SAVE_VERSION))
	migrated["game_version"] = String(migrated.get("game_version", GameConstants.GAME_VERSION))
	if not migrated.has("scenario_id"):
		var run_config = Dictionary(migrated.get("run_config", {}))
		migrated["scenario_id"] = String(run_config.get("scenario_id", run_config.get("id", "")))
	if not migrated.has("ui_state") or not migrated["ui_state"] is Dictionary:
		migrated["ui_state"] = {}
	return migrated


func _rehydrate_state_dictionary(raw_data: Dictionary, script_resource) -> Dictionary:
	var hydrated: Dictionary = {}
	var keys: Array = raw_data.keys()
	keys.sort()
	for key in keys:
		var entry = raw_data[key]
		if not entry is Dictionary:
			continue
		hydrated[String(key)] = script_resource.new(Dictionary(entry))
	return hydrated


func _read_json_file(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "reason": "open_failed", "path": path}
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	var parse_error := json.parse(content)
	if parse_error != OK:
		return {"ok": false, "reason": "parse_failed", "path": path}
	return {"ok": true, "data": json.data}


func _write_json_file(path: String, payload: Dictionary) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "reason": "open_failed", "path": path}
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return {"ok": true, "path": path}
