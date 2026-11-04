## Headless test runner. Usage:
##   godot --headless --path . -s res://tests/run_tests.gd
## Runs every `test_*` method in every res://tests/test_*.gd file.
## A test fails on a failed `check*()`. Exit code 1 on any failure.
## Script errors don't change the exit code here: use tests/run.sh, which also fails on them.
extends SceneTree

const TEST_DIR := "res://tests/"

var _failures: Array[String] = []
var _current := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	var passed := 0
	for path in _test_files():
		var suite: Object = load(path).new()
		if suite is Node:
			root.add_child(suite)
		for method in suite.get_method_list():
			var name: String = method["name"]
			if not name.begins_with("test_"):
				continue
			_current = "%s::%s" % [path.get_file(), name]
			var before := _failures.size()
			suite.set("runner", self)
			await suite.call(name)
			if _failures.size() == before:
				passed += 1
				print("  PASS ", _current)
		if suite is Node:
			suite.queue_free()
	print("\n%d passed, %d failed" % [passed, _failures.size()])
	for f in _failures:
		print("  FAIL ", f)
	quit(1 if _failures.size() > 0 else 0)


func _test_files() -> Array[String]:
	var files: Array[String] = []
	for f in DirAccess.get_files_at(TEST_DIR):
		if f.begins_with("test_") and f.ends_with(".gd"):
			files.append(TEST_DIR + f)
	files.sort()
	return files


func record_failure(message: String) -> void:
	_failures.append("%s: %s" % [_current, message])
