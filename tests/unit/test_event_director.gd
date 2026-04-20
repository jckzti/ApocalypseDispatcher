extends "res://addons/gut/test.gd"

const ContentDbScript = preload("res://scripts/autoload/ContentDb.gd")
const DeterministicRng = preload("res://scripts/core/DeterministicRng.gd")
const RunConfig = preload("res://scripts/core/RunConfig.gd")
const GameState = preload("res://scripts/core/GameState.gd")
const CityGraph = preload("res://scripts/sim/CityGraph.gd")
const EventDirector = preload("res://scripts/sim/EventDirector.gd")


func test_event_with_false_trigger_does_not_fire() -> void:
	var runtime = _create_runtime(5)
	var director = EventDirector.new(runtime["content_db"], runtime["rng"])

	var queued = director.update(runtime["state"], runtime["graph"])

	assert_eq(queued, {})
	assert_eq(runtime["state"].scheduled_events.size(), 0)
	runtime["content_db"].free()


func test_event_with_true_trigger_can_fire() -> void:
	var runtime = _create_runtime(10)
	var director = EventDirector.new(runtime["content_db"], runtime["rng"])

	var queued = director.update(runtime["state"], runtime["graph"])

	assert_eq(String(queued.get("event_id", "")), "event_supply_drop")
	assert_eq(runtime["state"].scheduled_events.size(), 1)
	runtime["content_db"].free()


func test_cooldown_prevents_immediate_repeat() -> void:
	var runtime = _create_runtime(10)
	var director = EventDirector.new(runtime["content_db"], runtime["rng"])

	director.update(runtime["state"], runtime["graph"])
	director.choose_option(runtime["state"], "event_supply_drop", "accept", runtime["graph"])
	runtime["state"].elapsed_minutes = 20
	var blocked = director.update(runtime["state"], runtime["graph"])
	assert_eq(blocked, {})

	runtime["state"].elapsed_minutes = 41
	var queued_again = director.update(runtime["state"], runtime["graph"])
	assert_eq(String(queued_again.get("event_id", "")), "event_supply_drop")
	runtime["content_db"].free()


func test_option_alters_state() -> void:
	var runtime = _create_runtime(10)
	var director = EventDirector.new(runtime["content_db"], runtime["rng"])
	var initial_fuel = float(runtime["state"].global_resources.get("fuel", 0))
	var initial_trust = float(runtime["state"].global_resources.get("trust", 0))
	director.update(runtime["state"], runtime["graph"])

	var result = director.choose_option(runtime["state"], "event_supply_drop", "accept", runtime["graph"])

	assert_true(bool(result.get("ok", false)))
	assert_true(float(runtime["state"].global_resources["fuel"]) > initial_fuel)
	assert_true(float(runtime["state"].global_resources["trust"]) > initial_trust)
	assert_eq(runtime["state"].scheduled_events.size(), 0)
	assert_eq(runtime["state"].event_history.size(), 1)
	runtime["content_db"].free()


func _create_runtime(elapsed_minutes: int) -> Dictionary:
	var content_db = ContentDbScript.new()
	var ok = content_db.load_content("res://data")
	assert_true(ok)
	var scenario_def = content_db.get_runtime_scenario("campanha_tiny_map")
	var run_config = RunConfig.new(scenario_def.to_dictionary())
	run_config.seed = 123
	var state = GameState.create_initial(run_config)
	state.elapsed_minutes = elapsed_minutes
	state.run_flags["allowed_event_ids"] = scenario_def.allowed_event_ids.duplicate(true)
	var graph = CityGraph.new(content_db.get_map("tiny_map").to_dictionary())
	graph.apply_to_game_state(state)
	var rng = DeterministicRng.new(123)
	return {
		"content_db": content_db,
		"state": state,
		"graph": graph,
		"rng": rng,
	}
