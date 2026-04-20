extends RefCounted

var _runner = null


func set_runner(runner: Object) -> void:
	_runner = runner


func before_all() -> void:
	pass


func after_all() -> void:
	pass


func before_each() -> void:
	pass


func after_each() -> void:
	pass


func fail_test(message: String) -> void:
	if _runner != null:
		_runner.report_failure(message)
	else:
		push_error(message)


func assert_true(value: Variant, message: String = "") -> void:
	if not bool(value):
		fail_test(_format_message(message, "Esperado valor verdadeiro."))


func assert_false(value: Variant, message: String = "") -> void:
	if bool(value):
		fail_test(_format_message(message, "Esperado valor falso."))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual != expected:
		fail_test(_format_message(message, "Esperado %s, obtido %s." % [var_to_str(expected), var_to_str(actual)]))


func assert_ne(actual: Variant, expected: Variant, message: String = "") -> void:
	if actual == expected:
		fail_test(_format_message(message, "Valores nao deveriam ser iguais: %s." % var_to_str(actual)))


func assert_almost_eq(actual: float, expected: float, tolerance: float = 0.00001, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		fail_test(_format_message(message, "Esperado %.6f, obtido %.6f (tol=%.6f)." % [expected, actual, tolerance]))


func assert_null(value: Variant, message: String = "") -> void:
	if value != null:
		fail_test(_format_message(message, "Esperado valor nulo."))


func assert_not_null(value: Variant, message: String = "") -> void:
	if value == null:
		fail_test(_format_message(message, "Esperado valor nao nulo."))


func _format_message(message: String, fallback: String) -> String:
	if message.is_empty():
		return fallback
	return "%s %s" % [message, fallback]
