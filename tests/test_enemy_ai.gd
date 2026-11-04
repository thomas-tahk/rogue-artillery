extends "res://tests/test_case.gd"

const BOUNDS := Rect2(-200, -2500, 2200, 3500)
const GROUND_Y := 500.0


func _is_hit(pos: Vector2) -> bool:
	if pos.y >= GROUND_Y:
		return true
	return pos.x > 500.0 and pos.x < 700.0 and pos.y >= GROUND_Y - 150.0


func _ai(error_px: float, seed_value: int = 1) -> EnemyAI:
	var ai := EnemyAI.new()
	ai.is_hit = _is_hit
	ai.bounds = BOUNDS
	ai.aim_error_px = error_px
	ai.rng.seed = seed_value
	return ai


func _land(ai: EnemyAI, from: Vector2, target: Vector2, wind: float) -> Vector2:
	var shot := ai.choose_shot(from, target, wind)
	var facing := 1 if target.x > from.x else -1
	var vel := Ballistics.launch_velocity(shot.x, facing, shot.y)
	var result := Ballistics.first_hit(from, vel, wind, _is_hit, BOUNDS)
	check(result["hit"], "shot lands")
	return result["position"]


func test_exact_aim_lands_near_target_over_hill():
	for wind in [0.0, 80.0, -80.0]:
		var target := Vector2(1100, GROUND_Y)
		var land := _land(_ai(0.0), Vector2(100, GROUND_Y - 20), target, wind)
		check(land.distance_to(target) <= 20.0, "wind %s off by %s" % [wind, land.distance_to(target)])


func test_works_facing_left():
	for wind in [0.0, 80.0, -80.0]:
		var target := Vector2(100, GROUND_Y)
		var land := _land(_ai(0.0), Vector2(1100, GROUND_Y - 20), target, wind)
		check(land.distance_to(target) <= 20.0, "left wind %s off by %s" % [wind, land.distance_to(target)])


func test_aim_error_varies_with_seed_but_is_bounded():
	var target := Vector2(1100, GROUND_Y)
	var xs := {}
	for s in range(1, 9):
		var land := _land(_ai(60.0, s), Vector2(100, GROUND_Y - 20), target, 0.0)
		xs[snappedf(land.x, 1.0)] = true
		check(land.distance_to(target) <= 120.0, "seed %s off by %s" % [s, land.distance_to(target)])
	check(xs.size() > 1, "different seeds give different shots")


func test_shot_values_in_range():
	for t in [Vector2(1100, GROUND_Y), Vector2(300, GROUND_Y), Vector2(100, GROUND_Y)]:
		var shot := _ai(60.0).choose_shot(Vector2(700, GROUND_Y - 170), t, 40.0)
		check(shot.x >= 0.0 and shot.x <= 90.0, "elevation %s in 0..90" % shot.x)
		check(shot.y >= 10.0 and shot.y <= 100.0, "power %s in 10..100" % shot.y)
