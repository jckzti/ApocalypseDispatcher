extends RefCounted
class_name CardOfferGenerator

const RARITY_BASE_WEIGHTS := {
	"common": 60.0,
	"uncommon": 25.0,
	"rare": 10.0,
	"epic": 4.0,
	"legendary": 1.0,
	"anomalous": 0.25,
}

const RARE_PLUS_RARITIES := ["rare", "epic", "legendary", "anomalous"]


func generate_offer(state, card_defs: Dictionary, rng, scenario_def = null, previous_offer_ids: Array = []) -> Array:
	var candidates: Array = _build_candidates(state, card_defs, scenario_def, previous_offer_ids)
	var selected: Array = []

	while selected.size() < 3 and not candidates.is_empty():
		var weights: Array = []
		for candidate in candidates:
			weights.append(float(candidate.get("weight", 0.0)))
		var picked_index: int = rng.pick_index(weights)
		if picked_index < 0 or picked_index >= candidates.size():
			break
		var picked: Dictionary = candidates[picked_index]
		selected.append(String(picked["id"]))
		candidates.remove_at(picked_index)

	return selected


func _build_candidates(state, card_defs: Dictionary, scenario_def, previous_offer_ids: Array) -> Array:
	var candidates: Array = []
	var card_ids: Array = card_defs.keys()
	card_ids.sort()
	for card_id in card_ids:
		var card_def = card_defs[card_id]
		if not _is_available(card_def, state, scenario_def):
			continue
		var weight := _compute_weight(card_def, state)
		if previous_offer_ids.has(card_def.id) and card_defs.size() > 3:
			weight *= 0.05
		if weight <= 0.0:
			continue
		candidates.append({
			"id": card_def.id,
			"weight": weight,
		})
	return candidates


func _is_available(card_def, state, scenario_def) -> bool:
	if state.crisis_level < card_def.min_crisis_level:
		return false
	if scenario_def != null and scenario_def.allowed_card_ids.size() > 0 and not scenario_def.allowed_card_ids.has(card_def.id):
		return false
	if scenario_def != null and scenario_def.allowed_card_classes.size() > 0 and not scenario_def.allowed_card_classes.has(card_def.card_class):
		return false
	if card_def.exclusive_group != null and not String(card_def.exclusive_group).is_empty():
		for owned_card_id in state.owned_cards.keys():
			var owned_card = null
			if state.run_flags.has("content_cards") and state.run_flags["content_cards"] is Dictionary:
				owned_card = state.run_flags["content_cards"].get(owned_card_id)
			if owned_card != null and owned_card.exclusive_group == card_def.exclusive_group and owned_card.id != card_def.id:
				return false
	return true


func _compute_weight(card_def, state) -> float:
	var infinite_state := _infinite_state(state)
	var rarity_weight := _rarity_weight(card_def.rarity, state.crisis_level + int(infinite_state.get("late_rarity_bonus", 0)))
	var synergy_weight := 1.0 + minf(0.35, _matching_tag_count(card_def, state) * 0.05)
	var duplicate_weight := 1.0
	var current_level := int(state.owned_cards.get(card_def.id, 0))
	if current_level > 0:
		if bool(infinite_state.get("enabled", false)):
			var duplicate_bonus := float(infinite_state.get("duplicate_weight_bonus", 0.0))
			duplicate_weight = (1.2 + duplicate_bonus) if current_level < card_def.max_level else (0.9 + duplicate_bonus)
		else:
			duplicate_weight = 1.15 if current_level < card_def.max_level else 0.25

	var pity_bonus := 1.0
	if RARE_PLUS_RARITIES.has(card_def.rarity):
		pity_bonus += float(state.run_flags.get("card_offer_pity", 0)) * 0.15

	return rarity_weight * synergy_weight * duplicate_weight * pity_bonus


func _rarity_weight(rarity: String, crisis_level: int) -> float:
	var base_weight := float(RARITY_BASE_WEIGHTS.get(rarity, 0.0))
	match rarity:
		"common":
			return maxf(5.0, base_weight - (float(crisis_level) * 8.0))
		"uncommon":
			return base_weight + (float(crisis_level) * 3.0)
		"rare":
			return base_weight + (float(crisis_level) * 4.0)
		"epic":
			return base_weight + (float(crisis_level) * 2.5)
		"legendary":
			return base_weight + maxf(0.0, float(crisis_level - 2)) * 1.5
		"anomalous":
			return base_weight + maxf(0.0, float(crisis_level - 3)) * 0.5
		_:
			return base_weight


func _matching_tag_count(card_def, state) -> float:
	var owned_tags: Dictionary = {}
	for owned_card_id in state.owned_cards.keys():
		if not state.run_flags.has("content_cards"):
			continue
		var cards_dict: Dictionary = state.run_flags["content_cards"]
		if not cards_dict is Dictionary:
			continue
		var owned_card = cards_dict.get(owned_card_id)
		if owned_card == null:
			continue
		for tag in owned_card.tags:
			owned_tags[String(tag)] = true

	var matches := 0.0
	for tag in card_def.tags:
		if owned_tags.has(String(tag)):
			matches += 1.0
	return matches


func _infinite_state(state) -> Dictionary:
	var infinite_state: Variant = state.run_flags.get("infinite_mode", {})
	if infinite_state is Dictionary:
		return Dictionary(infinite_state)
	return {}
