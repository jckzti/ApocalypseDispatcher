extends RefCounted
class_name InfiniteModeDirector

const GameEnums = preload("res://scripts/core/GameEnums.gd")

var metadata: Dictionary = {}
var rng = null


func _init(metadata_override: Dictionary = {}, rng_override = null) -> void:
	metadata = Dictionary(metadata_override).duplicate(true)
	rng = rng_override


func is_enabled() -> bool:
	return bool(metadata.get("infinite_mode", false))


func ensure_state(state) -> Dictionary:
	if not is_enabled():
		return {}

	var infinite_state: Dictionary = Dictionary(state.run_flags.get("infinite_mode", {})).duplicate(true)
	infinite_state["enabled"] = true
	infinite_state["wave"] = maxi(0, int(infinite_state.get("wave", 0)))
	infinite_state["wave_interval_minutes"] = maxi(5, int(infinite_state.get("wave_interval_minutes", metadata.get("wave_interval_minutes", 15))))
	infinite_state["population_spawn_base"] = maxi(0, int(infinite_state.get("population_spawn_base", metadata.get("population_spawn_base", 220))))
	infinite_state["population_spawn_growth"] = maxi(0, int(infinite_state.get("population_spawn_growth", metadata.get("population_spawn_growth", 55))))
	infinite_state["districts_per_wave"] = maxi(1, int(infinite_state.get("districts_per_wave", metadata.get("districts_per_wave", 3))))
	infinite_state["danger_per_wave"] = float(infinite_state.get("danger_per_wave", metadata.get("danger_per_wave", 4.0)))
	infinite_state["panic_per_wave"] = float(infinite_state.get("panic_per_wave", metadata.get("panic_per_wave", 2.5)))
	infinite_state["collapse_per_wave"] = float(infinite_state.get("collapse_per_wave", metadata.get("collapse_per_wave", 1.5)))
	infinite_state["wave_score"] = maxi(0, int(infinite_state.get("wave_score", 0)))
	infinite_state["late_rarity_bonus"] = maxi(0, int(infinite_state.get("late_rarity_bonus", 0)))
	infinite_state["duplicate_weight_bonus"] = float(infinite_state.get("duplicate_weight_bonus", 0.0))
	infinite_state["extraction_unlocked"] = bool(infinite_state.get("extraction_unlocked", false))

	var next_wave_default := int(infinite_state.get("wave_interval_minutes", 15))
	if infinite_state.has("last_wave_minute"):
		next_wave_default = int(infinite_state.get("last_wave_minute", 0)) + int(infinite_state.get("wave_interval_minutes", 15))
	infinite_state["next_wave_minute"] = maxi(1, int(infinite_state.get("next_wave_minute", next_wave_default)))

	state.run_flags["infinite_mode"] = infinite_state
	return infinite_state


func update(state, city_graph, _minutes: int = 1) -> Dictionary:
	if not is_enabled():
		return {}

	var infinite_state := ensure_state(state)
	var last_wave_result: Dictionary = {}
	while state.elapsed_minutes >= int(infinite_state.get("next_wave_minute", 999999)):
		last_wave_result = _advance_wave(state, city_graph, infinite_state)
	state.run_flags["infinite_mode"] = infinite_state
	return last_wave_result


func _advance_wave(state, city_graph, infinite_state: Dictionary) -> Dictionary:
	var wave := int(infinite_state.get("wave", 0)) + 1
	infinite_state["wave"] = wave
	infinite_state["last_wave_minute"] = state.elapsed_minutes
	infinite_state["next_wave_minute"] = state.elapsed_minutes + int(infinite_state.get("wave_interval_minutes", 15))
	infinite_state["extraction_unlocked"] = true
	infinite_state["wave_score"] = int(infinite_state.get("wave_score", 0)) + (wave * 100)
	infinite_state["late_rarity_bonus"] = int(floor(float(wave) / 2.0))
	infinite_state["duplicate_weight_bonus"] = minf(1.5, float(wave) * 0.12)

	var spawned_population := _spawn_population_wave(city_graph, wave, infinite_state)
	_apply_wave_pressure(city_graph, wave, infinite_state)
	state.crisis_level = maxi(state.crisis_level + 1, 1 + int(floor(float(wave) / 2.0)))
	state.run_flags["infinite_mode"] = infinite_state

	return {
		"wave": wave,
		"spawned_population": spawned_population,
		"next_wave_minute": int(infinite_state.get("next_wave_minute", state.elapsed_minutes)),
	}


func _spawn_population_wave(city_graph, wave: int, infinite_state: Dictionary) -> int:
	if city_graph == null:
		return 0

	var eligible_ids: Array = []
	var district_ids: Array = city_graph.district_states.keys()
	district_ids.sort()
	for district_id in district_ids:
		var district = city_graph.get_district(String(district_id))
		if district == null or district.is_shelter or district.is_collapsed():
			continue
		eligible_ids.append(district.id)
	if eligible_ids.is_empty():
		return 0

	var selected_ids := _pick_wave_districts(eligible_ids, city_graph, int(infinite_state.get("districts_per_wave", 3)))
	var total_spawn := int(infinite_state.get("population_spawn_base", 220)) + ((wave - 1) * int(infinite_state.get("population_spawn_growth", 55)))
	var total_added := 0
	for index in range(selected_ids.size()):
		var district = city_graph.get_district(String(selected_ids[index]))
		if district == null:
			continue
		var share := total_spawn / selected_ids.size()
		if index == 0:
			share += total_spawn % selected_ids.size()
		var package := _build_population_package(share, wave)
		total_added += district.add_population(package)
	return total_added


func _pick_wave_districts(eligible_ids: Array, city_graph, desired_count: int) -> Array:
	if eligible_ids.size() <= desired_count:
		return eligible_ids.duplicate(true)

	var pool: Array = eligible_ids.duplicate(true)
	var picked: Array = []
	while picked.size() < desired_count and not pool.is_empty():
		if rng == null:
			picked.append(String(pool.pop_front()))
			continue
		var weights: Array = []
		for district_id in pool:
			var district = city_graph.get_district(String(district_id))
			var weight := 1.0
			if district != null:
				weight += float(district.danger) * 0.03
				weight += float(district.panic) * 0.02
				weight += float(district.total_population()) / 1200.0
			weights.append(weight)
		var picked_index: int = rng.pick_index(weights)
		if picked_index < 0 or picked_index >= pool.size():
			picked.append(String(pool.pop_front()))
			continue
		picked.append(String(pool[picked_index]))
		pool.remove_at(picked_index)
	return picked


func _build_population_package(total: int, wave: int) -> Dictionary:
	var remaining := maxi(0, total)
	var package := GameEnums.create_empty_population()
	var weights := {
		"adults": 0.48,
		"children": 0.18,
		"elderly": 0.12,
		"patients": 0.06,
		"essential_staff": 0.08,
		"volunteer_drivers": 0.04,
		"high_influence": 0.04,
	}
	for cohort_key in GameEnums.POPULATION_COHORT_KEYS:
		var amount := int(floor(float(total) * float(weights.get(cohort_key, 0.0))))
		package[cohort_key] = amount
		remaining -= amount
	var fallback_order := [
		"adults",
		"children",
		"essential_staff",
		"elderly",
		"patients",
		"volunteer_drivers",
		"high_influence",
	]
	var offset := wave % fallback_order.size()
	while remaining > 0:
		var target_key: String = String(fallback_order[offset % fallback_order.size()])
		package[target_key] = int(package.get(target_key, 0)) + 1
		offset += 1
		remaining -= 1
	return package


func _apply_wave_pressure(city_graph, wave: int, infinite_state: Dictionary) -> void:
	if city_graph == null:
		return

	var danger_delta := float(infinite_state.get("danger_per_wave", 4.0)) + (float(wave - 1) * 0.6)
	var panic_delta := float(infinite_state.get("panic_per_wave", 2.5)) + (float(wave - 1) * 0.35)
	var collapse_delta := float(infinite_state.get("collapse_per_wave", 1.5)) + (float(wave - 1) * 0.25)

	for district in city_graph.district_states.values():
		if district.is_shelter:
			district.danger = clampf(district.danger + (danger_delta * 0.45), 0.0, 100.0)
			district.panic = clampf(district.panic + (panic_delta * 0.25), 0.0, 100.0)
			continue
		district.danger = clampf(district.danger + danger_delta, 0.0, 100.0)
		district.panic = clampf(district.panic + panic_delta, 0.0, 100.0)
		if district.total_population() > 0:
			district.collapse = clampf(district.collapse + collapse_delta, 0.0, 100.0)

	for road in city_graph.road_states.values():
		road.danger = clampf(road.danger + (0.6 + float(wave) * 0.08), 0.0, 100.0)
		road.blockade = clampf(road.blockade + (0.5 + float(wave) * 0.12), 0.0, 100.0)
