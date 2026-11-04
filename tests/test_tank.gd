extends "res://tests/test_case.gd"

const TANK_SCENE := "res://src/scenes/tank.tscn"


func _floor(top_y: float, x_from: float, x_to: float) -> StaticBody2D:
	var body := StaticBody2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(x_to - x_from, 200)
	shape.shape = rect
	shape.position = Vector2((x_from + x_to) / 2.0, top_y + 100)
	body.add_child(shape)
	add_child(body)
	return body


func _tank(pos: Vector2) -> Tank:
	var tank: Tank = load(TANK_SCENE).instantiate()
	tank.position = pos
	add_child(tank)
	return tank


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func test_falls_and_rests_on_floor():
	var floor_body := _floor(300.0, -500.0, 500.0)
	var tank := _tank(Vector2(0, 200))
	await _frames(90)
	var y1 := tank.position.y
	await _frames(10)
	check(y1 > 200.0 and y1 < 300.0, "tank fell onto floor, y=%s" % y1)
	check_near(tank.position.y, y1, 0.5, "tank at rest")
	floor_body.queue_free()
	tank.queue_free()


func test_drive_spends_fuel_and_stops_at_zero():
	var floor_body := _floor(300.0, -2000.0, 2000.0)
	var tank := _tank(Vector2(0, 280))
	await _frames(30)
	var x0 := tank.position.x
	tank.drive(1, 0.1)
	check(tank.position.x > x0, "drive moved right")
	check(tank.fuel < 100.0, "drive spent fuel")
	for i in 200:
		tank.drive(1, 0.1)
	check_eq(tank.fuel, 0.0, "fuel exhausted")
	var x1 := tank.position.x
	tank.drive(1, 0.1)
	check_eq(tank.position.x, x1, "no movement at 0 fuel")
	tank.refuel()
	check_eq(tank.fuel, 100.0, "refuel restores")
	tank.drive(-1, 0.1)
	check(tank.position.x < x1, "drive left after refuel")
	floor_body.queue_free()
	tank.queue_free()


func test_drives_up_one_tile_step():
	var low := _floor(300.0, -500.0, 0.0)
	var high := _floor(284.0, 0.0, 500.0)
	var tank := _tank(Vector2(-60, 280))
	await _frames(30)
	for i in 120:
		tank.drive(1, 0.1)
		await get_tree().physics_frame
	await _frames(20)
	check(tank.position.x > 30.0, "tank got over the step, x=%s" % tank.position.x)
	check(tank.position.y < 284.0, "tank rests on the higher floor, y=%s" % tank.position.y)
	low.queue_free()
	high.queue_free()
	tank.queue_free()


func _drive_for(tank: Tank, frames: int) -> void:
	for i in frames:
		tank.drive(1, 0.05)
		await get_tree().physics_frame


func test_tall_wall_blocks_tank():
	var low := _floor(300.0, -500.0, 500.0)
	var wall := _floor(268.0, 0.0, 500.0)
	var tank := _tank(Vector2(-60, 280))
	await _frames(30)
	var y0 := tank.position.y
	await _drive_for(tank, 80)
	check(tank.position.x < 0.0, "stopped before 32 px wall, x=%s" % tank.position.x)
	check_near(tank.position.y, y0, 0.5, "y stays on low floor")
	low.queue_free()
	wall.queue_free()
	tank.queue_free()


func test_step_with_low_ceiling_blocks_tank():
	var low := _floor(300.0, -500.0, 0.0)
	var high := _floor(284.0, 0.0, 500.0)
	var ceiling := _floor(68.0, 0.0, 500.0)  # underside y=268: 16 px above the step
	var tank := _tank(Vector2(-60, 280))
	await _frames(30)
	var y0 := tank.position.y
	await _drive_for(tank, 80)
	check(tank.position.x < 0.0, "did not pass under low ceiling, x=%s" % tank.position.x)
	check_near(tank.position.y, y0, 0.5, "y unchanged")
	low.queue_free()
	high.queue_free()
	ceiling.queue_free()
	tank.queue_free()


func test_no_steering_in_mid_air():
	var tank := _tank(Vector2(0, 100))
	await _frames(3)
	var x0 := tank.position.x
	tank.drive(1, 0.1)
	check_eq(tank.position.x, x0, "no drive while airborne")
	check_eq(tank.fuel, 100.0, "no fuel spent airborne")
	tank.queue_free()


func test_aim_and_power_clamp():
	var tank := _tank(Vector2.ZERO)
	tank.adjust_aim(1000.0)
	check_eq(tank.aim_deg, 90.0, "aim max")
	tank.adjust_aim(-1000.0)
	check_eq(tank.aim_deg, 0.0, "aim min")
	tank.adjust_power(1000.0)
	check_eq(tank.power_pct, 100.0, "power max")
	tank.adjust_power(-1000.0)
	check_eq(tank.power_pct, 10.0, "power min")
	tank.queue_free()


func test_launch_velocity_matches_ballistics():
	var tank := _tank(Vector2.ZERO)
	for f in [1, -1]:
		tank.facing = f
		check_eq(tank.launch_velocity(), Ballistics.launch_velocity(tank.aim_deg, f, tank.power_pct), "launch velocity facing %d" % f)
	tank.queue_free()


func test_damage_and_death():
	var tank := _tank(Vector2.ZERO)
	var hp_events: Array = []
	var deaths := [0]
	tank.hp_changed.connect(func(hp: int, max_hp: int) -> void: hp_events.append([hp, max_hp]))
	tank.died.connect(func() -> void: deaths[0] += 1)
	tank.take_damage(30)
	check_eq(tank.hp, 70, "hp lowered")
	check_eq(hp_events, [[70, 100]], "hp_changed emitted")
	check(not tank.is_dead(), "alive")
	tank.take_damage(500)
	tank.take_damage(10)
	check_eq(tank.hp, 0, "hp never negative")
	check(tank.is_dead(), "dead")
	check_eq(deaths[0], 1, "died exactly once")
	tank.queue_free()


func test_contains_point():
	var tank := _tank(Vector2(100, 100))
	check(tank.contains_point(Vector2(100, 100)), "centre inside")
	check(not tank.contains_point(Vector2(200, 100)), "100 px away outside")
	check(tank.contains_point(Vector2(117.5, 100)), "just inside right edge")
	check(not tank.contains_point(Vector2(118.5, 100)), "just outside right edge")
	check(tank.contains_point(Vector2(100, 108.5)), "just inside bottom edge")
	check(not tank.contains_point(Vector2(100, 109.5)), "just outside bottom edge")
	tank.queue_free()


func test_facing_flips_sprite_and_muzzle():
	var tank := _tank(Vector2(100, 100))
	var sprite: Sprite2D = tank.get_node("Sprite2D")
	tank.facing = 1
	check(not sprite.flip_h, "sprite not flipped facing right")
	check(tank.muzzle_position().x > tank.position.x, "muzzle right")
	tank.facing = -1
	check(sprite.flip_h, "sprite flipped facing left")
	check(tank.muzzle_position().x < tank.position.x, "muzzle left")
	tank.queue_free()
