extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const DeterministicRng = preload("res://scripts/core/DeterministicRng.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const ModifierStack = preload("res://scripts/sim/ModifierStack.gd")
const CardOfferGenerator = preload("res://scripts/sim/CardOfferGenerator.gd")
const CardSystem = preload("res://scripts/sim/CardSystem.gd")


func test_offer_returns_three_distinct_cards() -> void:
	var runtime = _create_runtime(123)
	var card_system = CardSystem.new(runtime["content_db"], runtime["modifier_stack"], runtime["rng"], CardOfferGenerator.new())
	var offer = card_system.generate_offer(runtime["state"], runtime["scenario_def"])
	var unique_offer := {}
	for card_id in offer:
		unique_offer[String(card_id)] = true

	assert_eq(offer.size(), 3)
	assert_eq(unique_offer.keys().size(), 3)
	runtime["content_db"].free()


func test_high_crisis_increases_rare_plus_presence() -> void:
	var low_count := 0
	var high_count := 0
	for seed in range(1, 41):
		var low_runtime = _create_runtime(seed)
		low_runtime["state"].crisis_level = 0
		var low_system = CardSystem.new(low_runtime["content_db"], low_runtime["modifier_stack"], low_runtime["rng"], CardOfferGenerator.new())
		var low_offer = low_system.generate_offer(low_runtime["state"], low_runtime["scenario_def"])
		low_count += _count_rare_plus(low_offer, low_runtime["content_db"])
		low_runtime["content_db"].free()

		var high_runtime = _create_runtime(seed)
		high_runtime["state"].crisis_level = 4
		var high_system = CardSystem.new(high_runtime["content_db"], high_runtime["modifier_stack"], high_runtime["rng"], CardOfferGenerator.new())
		var high_offer = high_system.generate_offer(high_runtime["state"], high_runtime["scenario_def"])
		high_count += _count_rare_plus(high_offer, high_runtime["content_db"])
		high_runtime["content_db"].free()

	assert_true(high_count > low_count)


func test_reroll_consumes_budget() -> void:
	var runtime = _create_runtime(77)
	var card_system = CardSystem.new(runtime["content_db"], runtime["modifier_stack"], runtime["rng"], CardOfferGenerator.new())
	card_system.generate_offer(runtime["state"], runtime["scenario_def"])
	var initial_budget := int(runtime["state"].global_resources.get("budget", 0))

	var rerolled = card_system.reroll_offer(runtime["state"], runtime["scenario_def"])

	assert_eq(rerolled.size(), 3)
	assert_eq(int(runtime["state"].global_resources["budget"]), initial_budget - 1)
	runtime["content_db"].free()


func test_card_choice_applies_modifier_and_duplicate_upgrades_until_max() -> void:
	var runtime = _create_runtime(9)
	var card_system = CardSystem.new(runtime["content_db"], runtime["modifier_stack"], runtime["rng"], CardOfferGenerator.new())

	var first_pick = card_system.choose_card(runtime["state"], "card_fuel_rationing")
	assert_true(bool(first_pick.get("ok", false)))
	assert_true(float(runtime["modifier_stack"].apply_value("bus_fuel_consumption", 1.0)) < 1.0)

	card_system.choose_card(runtime["state"], "card_dispatch_training")
	card_system.choose_card(runtime["state"], "card_dispatch_training")
	card_system.choose_card(runtime["state"], "card_dispatch_training")
	card_system.choose_card(runtime["state"], "card_dispatch_training")

	assert_eq(int(runtime["state"].owned_cards["card_dispatch_training"]), 3)
	runtime["content_db"].free()


func test_infinite_mode_allows_overlevel_duplicates() -> void:
	var runtime = _create_runtime(11, "infinito_colapso_total")
	runtime["state"].run_flags["infinite_mode"] = {"enabled": true}
	var card_system = CardSystem.new(runtime["content_db"], runtime["modifier_stack"], runtime["rng"], CardOfferGenerator.new())

	card_system.choose_card(runtime["state"], "card_fuel_rationing")
	card_system.choose_card(runtime["state"], "card_fuel_rationing")

	assert_eq(int(runtime["state"].owned_cards["card_fuel_rationing"]), 3)
	assert_true(float(runtime["modifier_stack"].apply_value("bus_fuel_consumption", 1.0)) < 0.85)
	runtime["content_db"].free()


func _create_runtime(seed: int, scenario_id: String = "campanha_tiny_map") -> Dictionary:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)
	var scenario_def = content_db.get_runtime_scenario(scenario_id)
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = seed
	var state = GameState.create_initial(run_config)
	var modifier_stack = ModifierStack.new()
	var rng = DeterministicRng.new(seed)
	return {
		"content_db": content_db,
		"scenario_def": scenario_def,
		"state": state,
		"modifier_stack": modifier_stack,
		"rng": rng,
	}


func _count_rare_plus(offer: Array, content_db) -> int:
	var total := 0
	for card_id in offer:
		var card_def = content_db.get_card(String(card_id))
		if card_def != null and CardOfferGenerator.RARE_PLUS_RARITIES.has(card_def.rarity):
			total += 1
	return total
