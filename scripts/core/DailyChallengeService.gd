extends RefCounted
class_name DailyChallengeService

const ScenarioDef = preload("res://scripts/data/ScenarioDef.gd")

const HASH_MOD := 2147483629
const DEFAULT_MODIFIERS_PER_DAY := 2


static func build_daily_key(date_dict: Dictionary = {}) -> String:
	var resolved := date_dict.duplicate(true)
	if resolved.is_empty():
		resolved = Time.get_datetime_dict_from_system(true)
	return "%04d-%02d-%02d" % [
		int(resolved.get("year", 1970)),
		int(resolved.get("month", 1)),
		int(resolved.get("day", 1)),
	]


static func normalize_daily_key(raw_value: String) -> String:
	var candidate := raw_value.strip_edges()
	if candidate.length() == 10 and candidate[4] == "-" and candidate[7] == "-":
		return candidate
	return build_daily_key()


static func resolve_seed_for_scenario(scenario_def, fallback_seed: int = 1) -> int:
	if scenario_def == null:
		return maxi(1, fallback_seed)
	var metadata := Dictionary(scenario_def.metadata)
	if bool(metadata.get("daily_mode", false)):
		return maxi(1, int(metadata.get("daily_seed", _hash_to_seed("%s|%s" % [
			String(scenario_def.id),
			String(metadata.get("daily_key", build_daily_key())),
		]))))
	if scenario_def.starting_seed_mode == "fixed":
		return maxi(1, int(metadata.get("fixed_seed", fallback_seed)))
	return maxi(1, fallback_seed)


static func resolve_runtime_scenario(content_db, scenario_def, context: Dictionary = {}):
	if scenario_def == null:
		return null

	var wrapper_data: Dictionary = scenario_def.to_dictionary()
	var wrapper_metadata := Dictionary(wrapper_data.get("metadata", {})).duplicate(true)
	var daily_key := normalize_daily_key(String(context.get("daily_key", wrapper_metadata.get("daily_key", ""))))
	var source_pool: Array = Array(wrapper_metadata.get("daily_source_pool", [])).duplicate(true)
	var source_scenario_id := String(context.get("daily_source_scenario_id", ""))
	if source_scenario_id.is_empty():
		source_scenario_id = String(wrapper_metadata.get("daily_source_scenario_id", ""))
	if source_scenario_id.is_empty():
		source_scenario_id = _pick_daily_source_id(source_pool, daily_key, String(scenario_def.id))

	var base_scenario = null
	if content_db != null and not source_scenario_id.is_empty():
		base_scenario = content_db.get_runtime_scenario(source_scenario_id, {"skip_daily": true})
	if base_scenario == null:
		base_scenario = ScenarioDef.new(wrapper_data)

	var runtime_data: Dictionary = base_scenario.to_dictionary()
	runtime_data["id"] = String(scenario_def.id)
	runtime_data["name"] = String(scenario_def.name)
	runtime_data["game_mode_id"] = String(scenario_def.game_mode_id)
	runtime_data["starting_seed_mode"] = "daily"
	runtime_data["starting_resources"] = Dictionary(base_scenario.starting_resources).duplicate(true)
	runtime_data["starting_buses"] = Array(base_scenario.starting_buses).duplicate(true)
	runtime_data["starting_cards"] = _merge_unique_array(base_scenario.starting_cards, scenario_def.starting_cards)
	runtime_data["allowed_card_ids"] = _merge_unique_array(base_scenario.allowed_card_ids, scenario_def.allowed_card_ids)
	runtime_data["allowed_card_classes"] = _merge_unique_array(base_scenario.allowed_card_classes, scenario_def.allowed_card_classes)
	runtime_data["allowed_event_ids"] = _merge_unique_array(base_scenario.allowed_event_ids, scenario_def.allowed_event_ids)
	runtime_data["objectives"] = _merge_array_copy(base_scenario.objectives, scenario_def.objectives)
	runtime_data["end_conditions"] = _merge_dictionary_copy(base_scenario.end_conditions, scenario_def.end_conditions)
	runtime_data["tutorial_steps"] = Array(base_scenario.tutorial_steps).duplicate(true)

	var runtime_metadata := Dictionary(base_scenario.metadata).duplicate(true)
	_deep_merge_dictionary(runtime_metadata, wrapper_metadata)

	var modifier_pool: Array = Array(runtime_metadata.get("daily_modifier_pool", [])).duplicate(true)
	var modifiers_per_day := maxi(0, int(runtime_metadata.get("daily_modifiers_per_run", DEFAULT_MODIFIERS_PER_DAY)))
	var selected_modifiers := _pick_modifier_templates(modifier_pool, daily_key, String(scenario_def.id), modifiers_per_day)
	_apply_modifier_templates(runtime_data, runtime_metadata, selected_modifiers)

	var modifier_ids: Array = []
	var modifier_labels: Array = []
	for raw_modifier in selected_modifiers:
		var modifier: Dictionary = Dictionary(raw_modifier)
		modifier_ids.append(String(modifier.get("id", "daily_modifier")))
		modifier_labels.append(String(modifier.get("label", modifier.get("id", "Mutador"))))

	var daily_seed := int(context.get("daily_seed", runtime_metadata.get("daily_seed", _hash_to_seed("%s|%s|%s|%s" % [
		String(scenario_def.id),
		daily_key,
		source_scenario_id,
		"|".join(modifier_ids),
	]))))

	runtime_metadata["daily_mode"] = true
	runtime_metadata["daily_key"] = daily_key
	runtime_metadata["daily_seed"] = daily_seed
	runtime_metadata["daily_source_scenario_id"] = source_scenario_id
	runtime_metadata["daily_source_scenario_name"] = String(base_scenario.name)
	runtime_metadata["daily_modifier_ids"] = modifier_ids
	runtime_metadata["daily_modifier_labels"] = modifier_labels
	if not runtime_metadata.has("mode_label"):
		runtime_metadata["mode_label"] = "Desafio Diario"

	runtime_data["metadata"] = runtime_metadata
	return ScenarioDef.new(runtime_data)


static func _pick_daily_source_id(source_pool: Array, daily_key: String, salt: String) -> String:
	if source_pool.is_empty():
		return ""
	var ordered := source_pool.duplicate(true)
	ordered.sort()
	var index := int(_hash_to_seed("%s|%s" % [salt, daily_key]) % ordered.size())
	return String(ordered[index])


static func _pick_modifier_templates(pool: Array, daily_key: String, salt: String, count: int) -> Array:
	if pool.is_empty() or count <= 0:
		return []
	var ordered: Array = pool.duplicate(true)
	ordered.sort_custom(func(a, b): return String(Dictionary(a).get("id", "")) < String(Dictionary(b).get("id", "")))
	var max_count := mini(count, ordered.size())
	var selected: Array = []
	var selected_ids: Array = []
	var cursor := _hash_to_seed("%s|%s|modifiers" % [salt, daily_key])
	while selected.size() < max_count:
		var index := int(cursor % ordered.size())
		var candidate: Dictionary = Dictionary(ordered[index]).duplicate(true)
		var candidate_id := String(candidate.get("id", "modifier_%d" % index))
		if not selected_ids.has(candidate_id):
			selected.append(candidate)
			selected_ids.append(candidate_id)
		cursor = int((cursor * 1103515245 + 12345 + selected.size() * 37) % HASH_MOD)
	return selected


static func _apply_modifier_templates(runtime_data: Dictionary, runtime_metadata: Dictionary, selected_modifiers: Array) -> void:
	for raw_modifier in selected_modifiers:
		var modifier: Dictionary = Dictionary(raw_modifier)
		if modifier.is_empty():
			continue

		var resource_delta := Dictionary(modifier.get("starting_resources_delta", {}))
		if not resource_delta.is_empty():
			runtime_data["starting_resources"] = _apply_resource_delta(Dictionary(runtime_data.get("starting_resources", {})), resource_delta)

		var resource_multiplier := Dictionary(modifier.get("starting_resources_multiplier", {}))
		if not resource_multiplier.is_empty():
			runtime_data["starting_resources"] = _apply_resource_multiplier(Dictionary(runtime_data.get("starting_resources", {})), resource_multiplier)

		var metadata_overrides := Dictionary(modifier.get("metadata_overrides", {}))
		if not metadata_overrides.is_empty():
			_deep_merge_dictionary(runtime_metadata, metadata_overrides)

		var end_overrides := Dictionary(modifier.get("end_conditions_overrides", {}))
		if not end_overrides.is_empty():
			runtime_data["end_conditions"] = _merge_dictionary_copy(Dictionary(runtime_data.get("end_conditions", {})), end_overrides)

		var objectives_add := Array(modifier.get("objectives_add", [])).duplicate(true)
		if not objectives_add.is_empty():
			var merged_objectives := Array(runtime_data.get("objectives", [])).duplicate(true)
			merged_objectives.append_array(objectives_add)
			runtime_data["objectives"] = merged_objectives

		runtime_data["starting_cards"] = _merge_unique_array(Array(runtime_data.get("starting_cards", [])), Array(modifier.get("starting_cards_add", [])))
		runtime_data["allowed_card_ids"] = _merge_unique_array(Array(runtime_data.get("allowed_card_ids", [])), Array(modifier.get("allowed_card_ids_add", [])))
		runtime_data["allowed_card_classes"] = _merge_unique_array(Array(runtime_data.get("allowed_card_classes", [])), Array(modifier.get("allowed_card_classes_add", [])))
		runtime_data["allowed_event_ids"] = _merge_unique_array(Array(runtime_data.get("allowed_event_ids", [])), Array(modifier.get("allowed_event_ids_add", [])))

		var remove_event_ids: Array = Array(modifier.get("allowed_event_ids_remove", [])).duplicate(true)
		if not remove_event_ids.is_empty():
			var filtered_events: Array = []
			for event_id in Array(runtime_data.get("allowed_event_ids", [])):
				if not remove_event_ids.has(String(event_id)):
					filtered_events.append(String(event_id))
			runtime_data["allowed_event_ids"] = filtered_events


static func _apply_resource_delta(base_values: Dictionary, delta_values: Dictionary) -> Dictionary:
	var merged := Dictionary(base_values).duplicate(true)
	for key in delta_values.keys():
		merged[String(key)] = maxi(0.0, float(merged.get(String(key), 0.0)) + float(delta_values[key]))
	return merged


static func _apply_resource_multiplier(base_values: Dictionary, multiplier_values: Dictionary) -> Dictionary:
	var merged := Dictionary(base_values).duplicate(true)
	for key in multiplier_values.keys():
		merged[String(key)] = maxi(0.0, float(merged.get(String(key), 0.0)) * float(multiplier_values[key]))
	return merged


static func _merge_resource_dictionary(base_values: Dictionary, override_values: Dictionary) -> Dictionary:
	var merged := Dictionary(base_values).duplicate(true)
	for key in override_values.keys():
		merged[String(key)] = override_values[key]
	return merged


static func _merge_array_copy(base_values: Array, override_values: Array) -> Array:
	var merged: Array = Array(base_values).duplicate(true)
	merged.append_array(Array(override_values).duplicate(true))
	return merged


static func _merge_unique_array(base_values: Array, override_values: Array) -> Array:
	var merged: Array = []
	for raw_value in Array(base_values) + Array(override_values):
		var normalized := String(raw_value)
		if merged.has(normalized):
			continue
		merged.append(normalized)
	return merged


static func _merge_dictionary_copy(base_values: Dictionary, override_values: Dictionary) -> Dictionary:
	var merged: Dictionary = Dictionary(base_values).duplicate(true)
	_deep_merge_dictionary(merged, Dictionary(override_values))
	return merged


static func _deep_merge_dictionary(target: Dictionary, values: Dictionary) -> void:
	for key in values.keys():
		var existing = target.get(key)
		var incoming = values[key]
		if existing is Dictionary and incoming is Dictionary:
			var nested := Dictionary(existing).duplicate(true)
			_deep_merge_dictionary(nested, Dictionary(incoming))
			target[key] = nested
			continue
		target[key] = incoming


static func _hash_to_seed(text: String) -> int:
	var value := 216613626
	for index in range(text.length()):
		value = int((value * 16777619 + text.unicode_at(index)) % HASH_MOD)
	return maxi(1, value)
