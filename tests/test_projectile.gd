extends "res://tests/test_case.gd"

const BOUNDS := Rect2(-2000, -2000, 6000, 4000)


func _make(velocity: Vector2, is_hit: Callable, bounds: Rect2 = BOUNDS) -> Projectile:
	var p: Projectile = load("res://src/scenes/projectile.tscn").instantiate()
	add_child(p)
	p.setup(Vector2.ZERO, velocity, {"wind_accel": 0.0, "is_hit": is_hit, "bounds": bounds})
	return p


func _record(p: Projectile) -> Array:
	var events := []
	p.landed.connect(func(pos, exploded): events.append([pos, exploded]))
	return events


func test_emits_exploded_when_hit_and_frees():
	var state := {"hit": false}
	var p := _make(Vector2(100, -100), func(_pos): return state["hit"])
	var events := _record(p)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check_eq(events.size(), 0, "no landing before hit")
	state["hit"] = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	check_eq(events.size(), 1, "one landed signal")
	check(events.size() == 1 and events[0][1] == true, "exploded true")
	check(not is_instance_valid(p) or p.is_queued_for_deletion(), "frees itself")


func test_emits_not_exploded_when_leaving_bounds():
	var p := _make(Vector2(2000, 0), func(_pos): return false, Rect2(-50, -50, 100, 100))
	var events := _record(p)
	for i in 10:
		await get_tree().physics_frame
	check_eq(events.size(), 1, "one landed signal")
	check(events.size() == 1 and events[0][1] == false, "exploded false")
	check(not is_instance_valid(p) or p.is_queued_for_deletion(), "frees itself")


func test_full_power_never_tunnels_through_thin_wall():
	var wall := Rect2(500, -1000, 16, 2000)
	var p := _make(Vector2(1200, 0), func(pos): return wall.has_point(pos))
	var events := _record(p)
	for i in 60:
		await get_tree().physics_frame
	check_eq(events.size(), 1, "landed once")
	check(events.size() == 1 and events[0][1] == true, "stopped by wall")
	check(events.size() == 1 and events[0][0].x < 516.0, "did not pass the wall")
