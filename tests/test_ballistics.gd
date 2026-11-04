extends "res://tests/test_case.gd"

const BOUNDS := Rect2(-5000, -5000, 10000, 10000)


func _ground(pos: Vector2) -> bool:
	return pos.y >= 0.0


func test_45_degree_shot_lands_at_v_squared_over_g():
	var vel := Ballistics.launch_velocity(45.0, 1, 60.0)
	var expected := vel.length_squared() / Ballistics.GRAVITY
	var result := Ballistics.first_hit(Vector2.ZERO, vel, 0.0, _ground, BOUNDS)
	check(result["hit"], "shell hits flat ground")
	check_near(result["position"].x, expected, expected * 0.02, "range is v^2/g")


func test_positive_wind_moves_landing_right():
	var vel := Ballistics.launch_velocity(45.0, 1, 60.0)
	var calm := Ballistics.first_hit(Vector2.ZERO, vel, 0.0, _ground, BOUNDS)
	var windy := Ballistics.first_hit(Vector2.ZERO, vel, 80.0, _ground, BOUNDS)
	check(windy["position"].x > calm["position"].x + 10.0, "tailwind lands further right")


func test_trajectory_starts_at_start_and_falls():
	var start := Vector2(10, 20)
	var path := Ballistics.trajectory(start, Vector2(100, 0), 0.0, 1.0, 1.0 / 60.0)
	check(path.size() > 1, "trajectory has points")
	check_eq(path[0], start, "first point is start")
	check(path[path.size() - 1].y > start.y + 100.0, "gravity pulls the path down")
	check(path[path.size() - 1].x > start.x, "moves along initial velocity")


func test_first_hit_misses_when_leaving_bounds():
	var vel := Ballistics.launch_velocity(45.0, 1, 100.0)
	var small := Rect2(-100, -100, 200, 200)
	var result := Ballistics.first_hit(Vector2.ZERO, vel, 0.0, func(_p): return false, small)
	check_eq(result["hit"], false, "leaving bounds is not a hit")
