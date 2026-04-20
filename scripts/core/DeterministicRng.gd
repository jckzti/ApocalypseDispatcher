extends RefCounted
class_name DeterministicRng

const MODULUS := 0x100000000
const MULTIPLIER := 1664525
const INCREMENT := 1013904223

var _seed: int = 1
var _state: int = 1


func _init(seed_value: int = 1) -> void:
	set_seed(seed_value)


func set_seed(seed_value: int) -> void:
	_seed = _normalize_state(seed_value)
	_state = _seed


func get_seed() -> int:
	return _seed


func set_state(state_value: int) -> void:
	_state = _normalize_state(state_value)


func get_state() -> int:
	return _state


func next_u32() -> int:
	_state = int((MULTIPLIER * int(_state) + INCREMENT) % MODULUS)
	return _state


func randf() -> float:
	return float(next_u32()) / float(MODULUS)


func randf_range(min_value: float, max_value: float) -> float:
	if is_equal_approx(min_value, max_value):
		return min_value
	return lerpf(min_value, max_value, randf())


func randi_range(min_value: int, max_value: int) -> int:
	if min_value > max_value:
		push_error("DeterministicRng.randi_range recebeu min maior que max.")
		return min_value
	if min_value == max_value:
		return min_value
	var span := (max_value - min_value) + 1
	return min_value + int(next_u32() % span)


func pick_index(weights: Array) -> int:
	if weights.is_empty():
		return -1

	var total_weight := 0.0
	for weight in weights:
		var normalized_weight: float = maxf(0.0, float(weight))
		total_weight += normalized_weight

	if total_weight <= 0.0:
		return 0

	var roll: float = randf() * total_weight
	var cumulative := 0.0
	for index in range(weights.size()):
		cumulative += maxf(0.0, float(weights[index]))
		if roll <= cumulative:
			return index
	return weights.size() - 1


func shuffle(values: Array) -> Array:
	var shuffled := values.duplicate(true)
	for index in range(shuffled.size() - 1, 0, -1):
		var swap_index: int = randi_range(0, index)
		var temp: Variant = shuffled[index]
		shuffled[index] = shuffled[swap_index]
		shuffled[swap_index] = temp
	return shuffled


func snapshot() -> Dictionary:
	return {
		"seed": _seed,
		"state": _state,
	}


func restore(data: Dictionary) -> void:
	if data.has("seed"):
		_seed = _normalize_state(int(data["seed"]))
	if data.has("state"):
		_state = _normalize_state(int(data["state"]))
	else:
		_state = _seed


func _normalize_state(value: int) -> int:
	var normalized := int(value % MODULUS)
	if normalized < 0:
		normalized += MODULUS
	if normalized == 0:
		return 1
	return normalized
