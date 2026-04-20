extends RefCounted
class_name SimulationClock

const GameConstants = preload("res://scripts/core/GameConstants.gd")

var elapsed_minutes: int = 0


func _init(start_minutes: int = 0) -> void:
	elapsed_minutes = maxi(0, start_minutes)


func advance(minutes: int) -> int:
	if minutes < 0:
		push_error("SimulationClock.advance recebeu valor negativo.")
		return elapsed_minutes
	elapsed_minutes += minutes
	return elapsed_minutes


func set_elapsed_minutes(value: int) -> void:
	elapsed_minutes = maxi(0, value)


func get_day() -> int:
	return int(elapsed_minutes / GameConstants.MINUTES_PER_DAY)


func get_hour_of_day() -> int:
	return int((elapsed_minutes / GameConstants.MINUTES_PER_HOUR) % GameConstants.HOURS_PER_DAY)


func get_minute_of_hour() -> int:
	return int(elapsed_minutes % GameConstants.MINUTES_PER_HOUR)


func to_dictionary() -> Dictionary:
	return {
		"elapsed_minutes": elapsed_minutes,
		"day": get_day(),
		"hour": get_hour_of_day(),
		"minute": get_minute_of_hour(),
	}
