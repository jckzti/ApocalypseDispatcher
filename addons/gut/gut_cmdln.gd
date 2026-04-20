extends SceneTree

var _failures: Array[String] = []
var _current_test_label := ""


func _initialize() -> void:
	var options := _parse_args()
	var test_dir := _normalize_dir_path(String(options.get("gdir", "tests/unit")))
	var exit_when_finished := bool(options.get("gexit", false))
	var files := _collect_test_files(test_dir)

	if files.is_empty():
		printerr("Nenhum teste encontrado em %s." % test_dir)
		if exit_when_finished:
			quit(1)
		return

	var passed := 0
	var failed := 0

	for file_path in files:
		var result := _run_test_file(file_path)
		passed += int(result.get("passed", 0))
		failed += int(result.get("failed", 0))

	print("Testes em %s: %d ok, %d falhas." % [test_dir, passed, failed])
	if failed > 0:
		for failure in _failures:
			printerr(failure)
		quit(1)
		return

	if exit_when_finished:
		quit(0)


func report_failure(message: String) -> void:
	var label := _current_test_label if not _current_test_label.is_empty() else "teste_desconhecido"
	_failures.append("%s :: %s" % [label, message])


func _run_test_file(file_path: String) -> Dictionary:
	var script: Script = load(file_path)
	if script == null or not script.can_instantiate():
		_failures.append("%s :: falha ao carregar script." % file_path)
		return {"passed": 0, "failed": 1}

	var instance = script.new()
	if instance == null:
		_failures.append("%s :: falha ao instanciar script." % file_path)
		return {"passed": 0, "failed": 1}

	if instance.has_method("set_runner"):
		instance.set_runner(self)
	if instance.has_method("before_all"):
		instance.before_all()

	var passed := 0
	var failed := 0
	var methods: Array = instance.get_method_list()
	for method_info in methods:
		var method_name := String(method_info.get("name", ""))
		if not method_name.begins_with("test_"):
			continue

		var failures_before := _failures.size()
		_current_test_label = "%s::%s" % [file_path, method_name]
		if instance.has_method("before_each"):
			instance.before_each()
		instance.call(method_name)
		if instance.has_method("after_each"):
			instance.after_each()
		if _failures.size() == failures_before:
			passed += 1
		else:
			failed += 1

	_current_test_label = ""
	if instance.has_method("after_all"):
		instance.after_all()

	return {"passed": passed, "failed": failed}


func _collect_test_files(root_dir: String) -> Array:
	var files: Array = []
	_scan_dir(root_dir, files)
	files.sort()
	return files


func _scan_dir(dir_path: String, files: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry.is_empty():
			break
		if entry.begins_with("."):
			continue
		var full_path := "%s/%s" % [dir_path, entry]
		if dir.current_is_dir():
			_scan_dir(full_path, files)
		elif entry.ends_with(".gd"):
			files.append(full_path)
	dir.list_dir_end()


func _parse_args() -> Dictionary:
	var options := {}
	for arg in OS.get_cmdline_user_args():
		if arg == "-gexit":
			options["gexit"] = true
			continue
		if arg.begins_with("-gdir="):
			options["gdir"] = arg.trim_prefix("-gdir=")
	return options


func _normalize_dir_path(value: String) -> String:
	if value.is_empty():
		return "res://tests/unit"
	if value.begins_with("res://"):
		return value
	if value.begins_with("res:/"):
		return value.replace("res:/", "res://")
	return "res://%s" % value.trim_prefix("/")
