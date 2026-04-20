extends RefCounted
class_name CardSystem

const CardOfferGenerator = preload("res://scripts/sim/CardOfferGenerator.gd")

var content_db = null
var modifier_stack = null
var rng = null
var offer_generator = null


func _init(content_db_override = null, modifier_stack_override = null, rng_override = null, offer_generator_override = null) -> void:
	content_db = content_db_override
	modifier_stack = modifier_stack_override
	rng = rng_override
	offer_generator = offer_generator_override if offer_generator_override != null else CardOfferGenerator.new()


func generate_offer(state, scenario_def = null, previous_offer_ids: Array = []) -> Array:
	_cache_content_cards(state)
	var offer_ids: Array = offer_generator.generate_offer(state, content_db.cards, rng, scenario_def, previous_offer_ids)
	state.run_flags["current_card_offer"] = offer_ids.duplicate(true)
	_update_pity_counter(state, offer_ids)
	return offer_ids


func reroll_offer(state, scenario_def = null) -> Array:
	var reroll_cost := int(state.run_flags.get("card_reroll_cost", 1))
	var current_budget := int(state.global_resources.get("budget", 0))
	if current_budget < reroll_cost:
		return []

	state.global_resources["budget"] = current_budget - reroll_cost
	state.run_flags["card_reroll_cost"] = reroll_cost + 1
	var previous_offer_ids: Array = Array(state.run_flags.get("current_card_offer", [])).duplicate(true)
	return generate_offer(state, scenario_def, previous_offer_ids)


func choose_card(state, card_id: String) -> Dictionary:
	_cache_content_cards(state)
	var card_def = content_db.get_card(card_id)
	if card_def == null:
		return {"ok": false, "reason": "card_not_found"}

	var current_level := int(state.owned_cards.get(card_id, 0))
	var new_level := current_level + 1 if _is_infinite_mode(state) else mini(current_level + 1, card_def.max_level)
	state.owned_cards[card_id] = new_level
	_rebuild_card_modifiers(state)
	state.run_flags["current_card_offer"] = []

	return {
		"ok": true,
		"card_id": card_id,
		"previous_level": current_level,
		"new_level": new_level,
		"upgraded": current_level > 0 and new_level > current_level,
	}


func _rebuild_card_modifiers(state) -> void:
	if modifier_stack == null:
		return

	modifier_stack.remove_modifiers_by_source_prefix("card:")
	var owned_card_ids: Array = state.owned_cards.keys()
	owned_card_ids.sort()
	for card_id in owned_card_ids:
		var card_def = content_db.get_card(String(card_id))
		if card_def == null:
			continue
		var level := int(state.owned_cards[card_id])
		if level <= 0:
			continue
		var effect_map := _resolve_effect_map(card_def, level)
		if effect_map.is_empty():
			continue
		_apply_effect_map(card_def.id, effect_map)


func _apply_effect_map(card_id: String, effect_map: Dictionary) -> void:
	for effect_key in effect_map.keys():
		var effect_value = effect_map[effect_key]
		match String(effect_key):
			"bus_fuel_consumption_multiplier":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "bus_fuel_consumption",
					"op": "multiply",
					"value": 1.0 + float(effect_value),
				})
			"boarding_rate_multiplier":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "boarding_rate",
					"op": "multiply",
					"value": 1.0 + float(effect_value),
				})
			"district_panic_add":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "district_panic",
					"op": "add",
					"value": float(effect_value),
				})
			"district_danger_add":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "district_danger",
					"op": "add",
					"value": float(effect_value),
				})
			"collapse_base_threat_rate_multiplier":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "collapse_base_threat_rate",
					"op": "multiply",
					"value": 1.0 + float(effect_value),
				})
			"district_collapse_delta_multiplier":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "district_collapse_delta",
					"op": "multiply",
					"value": 1.0 + float(effect_value),
				})
			"road_blockade_from_collapse_multiplier":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "road_blockade_from_collapse",
					"op": "multiply",
					"value": 1.0 + float(effect_value),
				})
			"road_danger_from_collapse_multiplier":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "road_danger_from_collapse",
					"op": "multiply",
					"value": 1.0 + float(effect_value),
				})
			"attrition_multiplier":
				modifier_stack.add_modifier({
					"source_id": "card:%s" % card_id,
					"stat": "attrition_rate",
					"op": "multiply",
					"value": 1.0 + float(effect_value),
				})


func _update_pity_counter(state, offer_ids: Array) -> void:
	var found_rare_plus := false
	for card_id in offer_ids:
		var card_def = content_db.get_card(String(card_id))
		if card_def != null and CardOfferGenerator.RARE_PLUS_RARITIES.has(card_def.rarity):
			found_rare_plus = true
			break
	state.run_flags["card_offer_pity"] = 0 if found_rare_plus else int(state.run_flags.get("card_offer_pity", 0)) + 1


func _cache_content_cards(state) -> void:
	var cached_cards: Dictionary = {}
	for card_id in content_db.cards.keys():
		cached_cards[card_id] = content_db.cards[card_id]
	state.run_flags["content_cards"] = cached_cards


func _resolve_effect_map(card_def, level: int) -> Dictionary:
	var effect_index := mini(level, card_def.effects_by_level.size()) - 1
	if effect_index < 0:
		return {}
	var raw_effect_map = card_def.effects_by_level[effect_index]
	if not raw_effect_map is Dictionary:
		return {}

	var effect_map: Dictionary = Dictionary(raw_effect_map).duplicate(true)
	var extra_levels := maxi(0, level - card_def.max_level)
	if extra_levels <= 0:
		return effect_map

	var scale := 1.0 + (float(extra_levels) * 0.3)
	var scaled_map: Dictionary = {}
	for effect_key in effect_map.keys():
		var effect_value = effect_map[effect_key]
		if effect_value is int or effect_value is float:
			scaled_map[effect_key] = float(effect_value) * scale
		else:
			scaled_map[effect_key] = effect_value
	return scaled_map


func _is_infinite_mode(state) -> bool:
	var infinite_state: Variant = state.run_flags.get("infinite_mode", {})
	return infinite_state is Dictionary and bool(Dictionary(infinite_state).get("enabled", false))
