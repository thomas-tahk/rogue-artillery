# Headless check: the main scene loads and runs a few frames without errors.
# Run: godot --headless --path . --script res://tests/smoke_test.gd
extends SceneTree

const FRAMES := 10
var _frames := 0

func _initialize() -> void:
	var path: String = ProjectSettings.get_setting("application/run/main_scene", "")
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("main scene failed to load: %s" % path)
		quit(1)
		return
	root.add_child(packed.instantiate())

func _process(_delta: float) -> bool:
	_frames += 1
	if _frames >= FRAMES:
		print("smoke test passed")
		quit(0)
	return false
