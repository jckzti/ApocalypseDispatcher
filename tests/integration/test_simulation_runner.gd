extends "res://addons/gut/test.gd"

const RunConfig = preload("res://scripts/core/RunConfig.gd")
const SimulationRunner = preload("res://scripts/sim/SimulationRunner.gd")


func test_advance_changes_time_correctly() -> void:
	var config := RunConfig.new({
		"seed": 42,
		"scenario_id": "integration",
		"starting_resources": {
			"fuel": 100,
			"budget": 5,
		},
	})
	var runner := SimulationRunner.new(config)
	var snapshot := runner.advance(17)

	assert_eq(snapshot["elapsed_minutes"], 17, "Advance deve refletir no snapshot.")
	assert_eq(runner.clock.elapsed_minutes, 17, "Clock interno deve acompanhar o snapshot.")
	assert_eq(snapshot["rng_state"], 42, "Sem uso de RNG, o estado deve permanecer deterministico.")


func test_same_seed_and_actions_keep_same_state() -> void:
	var config := RunConfig.new({
		"seed": 99,
		"scenario_id": "integration",
	})
	var runner_a := SimulationRunner.new(config)
	var runner_b := SimulationRunner.new(config)

	runner_a.submit_command({
		"type": "pause_simulation",
		"paused": true,
	})
	runner_b.submit_command({
		"type": "pause_simulation",
		"paused": true,
	})

	assert_eq(runner_a.advance(5), runner_b.advance(5), "Mesma seed e mesmas acoes devem gerar o mesmo estado.")
