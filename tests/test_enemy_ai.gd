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
	var facing := EnemyAI.facing_for(from, target)
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


func test_facing_for_follows_target_side():
	check_eq(EnemyAI.facing_for(Vector2(0, 0), Vector2(10, 0)), 1, "target right")
	check_eq(EnemyAI.facing_for(Vector2(10, 0), Vector2(0, 0)), -1, "target left")


func test_choose_shot_is_fast_on_heightmap_terrain():
	var heights := PackedFloat32Array()
	for col in 100:
		heights.append(400.0 + 60.0 * sin(col * 0.2))
	var ai := _ai(0.0)
	ai.is_hit = func(pos: Vector2) -> bool:
		var col := clampi(int(pos.x / 16.0), 0, 99)
		return pos.y >= heights[col]
	var started := Time.get_ticks_usec()
	ai.choose_shot(Vector2(100, 300), Vector2(1400, heights[87]), 40.0)
	var ms := (Time.get_ticks_usec() - started) / 1000.0
	print("    choose_shot took %.1f ms" % ms)
	check(ms < 100.0, "choose_shot took %.1f ms" % ms)


## Real generated terrain: the AI aims at ground to one side of the tank, so large errors really miss.
## "Miss" here means "not a direct hit": splash from the blast can still hurt the tank.
func _miss_rate(error_px: float) -> float:
	var terrain: Terrain = load("res://src/scenes/terrain.tscn").instantiate()
	add_child(terrain)
	terrain.generate(3, 100, 40)
	var from := Vector2(terrain.pad_center_x(0) + 25.0, terrain.surface_y(terrain.pad_center_x(0)) - 20.0)
	var centre := Vector2(terrain.pad_center_x(1), terrain.surface_y(terrain.pad_center_x(1)) - 14.0)
	var box := Rect2(centre - Vector2(27, 13.5), Vector2(54, 27))
	var is_hit := func(p: Vector2) -> bool: return terrain.is_solid(p) or box.has_point(p)
	var ai := EnemyAI.new()
	ai.is_hit = is_hit
	ai.bounds = terrain.world_rect()
	ai.aim_error_px = error_px
	var misses := 0
	for i in 100:
		ai.rng.seed = i
		var shot := ai.choose_shot(from, centre, 0.0)
		var result := Ballistics.first_hit(from, Ballistics.launch_velocity(shot.x, 1, shot.y), 0.0, is_hit, ai.bounds)
		if not (result["hit"] and box.has_point(result["position"])):
			misses += 1
	terrain.free()
	return misses / 100.0


func test_error_at_battle_start_nearly_never_direct_hits():
	var rate := _miss_rate(Battle.AIM_ERROR_START)
	check(rate >= 0.8, "miss rate at start error %s" % rate)


func test_error_at_floor_still_often_no_direct_hit():
	var rate := _miss_rate(Battle.AIM_ERROR_FLOOR)
	check(rate >= 0.3, "miss rate at floor error %s" % rate)


## Aim points inside narrow deep trenches beside the target are unreachable (no shell can descend that steeply).
## The AI must then aim at the target itself instead of repeating the shot nearest to the unreachable point.
const TRENCH_OFFSET := 33.0
const TRENCH_HALF_WIDTH := 12.0
const TRENCH_DEPTH := 300.0
const TRENCH_TARGET_X := 1100.0


func _trench_hit(pos: Vector2) -> bool:
	var in_trench := absf(absf(pos.x - TRENCH_TARGET_X) - TRENCH_OFFSET) <= TRENCH_HALF_WIDTH
	return pos.y >= GROUND_Y + (TRENCH_DEPTH if in_trench else 0.0)


func test_unreachable_offset_falls_back_to_target():
	var from := Vector2(100, GROUND_Y - 20)
	var target := Vector2(TRENCH_TARGET_X, GROUND_Y)
	var worst := 0.0
	for s in range(1, 41):
		var ai := _ai(45.0, s)
		ai.is_hit = _trench_hit
		var shot := ai.choose_shot(from, target, 0.0)
		var vel := Ballistics.launch_velocity(shot.x, 1, shot.y)
		var land: Vector2 = Ballistics.first_hit(from, vel, 0.0, _trench_hit, BOUNDS)["position"]
		worst = maxf(worst, absf(land.x - target.x))
	check(worst <= 15.0, "every shot lands at the target, worst miss %s px" % worst)
