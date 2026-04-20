extends "res://addons/gut/test.gd"

const SimulationClock = preload("res://scripts/sim/SimulationClock.gd")


func test_advance_updates_elapsed_time() -> void:
	var clock := SimulationClock.new()
	clock.advance(125)

	assert_eq(clock.elapsed_minutes, 125)
	assert_eq(clock.get_day(), 0)
	assert_eq(clock.get_hour_of_day(), 2)
	assert_eq(clock.get_minute_of_hour(), 5)


func test_day_rollover_is_stable() -> void:
	var clock := SimulationClock.new((24 * 60) - 1)
	clock.advance(2)

	assert_eq(clock.elapsed_minutes, 24 * 60 + 1)
	assert_eq(clock.get_day(), 1)
	assert_eq(clock.get_hour_of_day(), 0)
	assert_eq(clock.get_minute_of_hour(), 1)
