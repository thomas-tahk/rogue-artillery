extends "res://tests/test_case.gd"


func test_runner_reports_passing_check():
	check(true, "always passes")


func test_awaiting_physics_frame_works():
	await get_tree().physics_frame
	check(is_inside_tree(), "suite is in the scene tree")
