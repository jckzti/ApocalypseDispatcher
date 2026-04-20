extends RefCounted
class_name ModifierStack

var _modifiers: Array = []
var _next_serial: int = 1


func add_modifier(modifier: Dictionary) -> String:
	var normalized := {
		"id": String(modifier.get("id", "mod_%d" % _next_serial)),
		"stat": String(modifier.get("stat", "")),
		"op": String(modifier.get("op", "add")),
		"value": modifier.get("value", 0),
		"duration_minutes": int(modifier.get("duration_minutes", -1)),
		"scope": Dictionary(modifier.get("scope", {})).duplicate(true),
		"source_id": String(modifier.get("source_id", "")),
	}
	_next_serial += 1
	_modifiers.append(normalized)
	return String(normalized["id"])


func remove_modifier(modifier_id: String) -> void:
	_modifiers = _modifiers.filter(func(entry): return String(entry.get("id", "")) != modifier_id)


func remove_modifiers_by_source(source_id: String) -> void:
	_modifiers = _modifiers.filter(func(entry): return String(entry.get("source_id", "")) != source_id)


func remove_modifiers_by_source_prefix(prefix: String) -> void:
	_modifiers = _modifiers.filter(func(entry): return not String(entry.get("source_id", "")).begins_with(prefix))


func clear() -> void:
	_modifiers.clear()
	_next_serial = 1


func replace_from_array(modifiers: Array) -> void:
	clear()
	for modifier in modifiers:
		if not modifier is Dictionary:
			continue
		var normalized: Dictionary = Dictionary(modifier).duplicate(true)
		if String(normalized.get("id", "")).is_empty():
			normalized["id"] = "mod_%d" % _next_serial
		_modifiers.append(normalized)
		_next_serial += 1


func advance(minutes: int) -> void:
	if minutes <= 0:
		return
	var remaining: Array = []
	for modifier in _modifiers:
		var duration := int(modifier.get("duration_minutes", -1))
		if duration < 0:
			remaining.append(modifier)
			continue
		duration -= minutes
		if duration > 0:
			modifier["duration_minutes"] = duration
			remaining.append(modifier)
	_modifiers = remaining


func apply_value(stat_name: String, base_value: Variant, context: Dictionary = {}) -> Variant:
	var matching_modifiers := _matching_modifiers(stat_name, context)
	if matching_modifiers.is_empty():
		return base_value

	if base_value is bool:
		var bool_value := bool(base_value)
		for modifier in matching_modifiers:
			var op := String(modifier.get("op", "flag"))
			if op == "flag":
				bool_value = bool_value or bool(modifier.get("value", true))
			elif op == "set":
				bool_value = bool(modifier.get("value", bool_value))
		return bool_value

	var numeric_value := float(base_value)
	for modifier in matching_modifiers:
		var op := String(modifier.get("op", "add"))
		match op:
			"set":
				numeric_value = float(modifier.get("value", numeric_value))
			"add":
				numeric_value += float(modifier.get("value", 0.0))
			"multiply":
				numeric_value *= float(modifier.get("value", 1.0))
			"min":
				numeric_value = minf(numeric_value, float(modifier.get("value", numeric_value)))
			"max":
				numeric_value = maxf(numeric_value, float(modifier.get("value", numeric_value)))
			"flag":
				pass

	if base_value is int:
		return int(round(numeric_value))
	return numeric_value


func has_flag(stat_name: String, context: Dictionary = {}) -> bool:
	return bool(apply_value(stat_name, false, context))


func to_array() -> Array:
	return _modifiers.duplicate(true)


func _matching_modifiers(stat_name: String, context: Dictionary) -> Array:
	var matching: Array = []
	for modifier in _modifiers:
		if String(modifier.get("stat", "")) != stat_name:
			continue
		var scope := Dictionary(modifier.get("scope", {}))
		if not _scope_matches(scope, context):
			continue
		matching.append(modifier)
	return matching


func _scope_matches(scope: Dictionary, context: Dictionary) -> bool:
	for key in scope.keys():
		if not context.has(key) or context[key] != scope[key]:
			return false
	return true
