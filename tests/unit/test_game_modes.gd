extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const DeterministicRng = preload("res://scripts/core/DeterministicRng.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const CardOfferGenerator = preload("res://scripts/sim/CardOfferGenerator.gd")


func test_runtime_scenario_inherits_mode_metadata() -> void:
	var content_db = ContentDbScript.new()
	assert_true(content_db.load_content("res://data"))

	var scenario_def = content_db.get_runtime_scenario("infinito_colapso_total")
	assert_not_null(scenario_def)
	assert_eq("infinite_waves", scenario_def.game_mode_id)
	assert_true(bool(scenario_def.metadata.get("infinite_mode", false)))
	assert_eq("Modo Infinito", String(scenario_def.metadata.get("game_mode_name", "")))

	content_db.free()


func test_challenge_mode_limits_card_offer_to_allowed_cards() -> void:
	var content_db = ContentDbScript.new()
	assert_true(content_db.load_content("res://data"))

	var scenario_def = content_db.get_runtime_scenario("desafio_combustivel_zero")
	assert_not_null(scenario_def)
	assert_true(Array(scenario_def.allowed_card_ids).size() > 0)

	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = 4242
	var state = GameState.create_initial(run_config)
	var rng = DeterministicRng.new(run_config.seed)
	var offer_generator = CardOfferGenerator.new()
	var offer: Array = offer_generator.generate_offer(state, content_db.cards, rng, scenario_def)

	assert_eq(3, offer.size())
	for card_id in offer:
		assert_true(scenario_def.allowed_card_ids.has(String(card_id)), "Carta fora do deck permitido do modo: %s" % String(card_id))

	content_db.free()
