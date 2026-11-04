## Artillery shell. Deterministic flight via Ballistics.step (no physics body).
class_name Projectile
extends Node2D

signal landed(position: Vector2, exploded: bool)

var velocity := Vector2.ZERO
var wind_accel := 0.0
var is_hit: Callable
var bounds := Rect2()
var _done := false


func setup(start: Vector2, start_velocity: Vector2, config: Dictionary) -> void:
	position = start
	velocity = start_velocity
	wind_accel = config["wind_accel"]
	is_hit = config["is_hit"]
	bounds = config["bounds"]
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	advance(delta)


func advance(dt: float) -> void:
	if _done:
		return
	var n := Ballistics.substeps(velocity, dt)
	for i in n:
		var s := Ballistics.step(position, velocity, wind_accel, dt / n)
		position = s[0]
		velocity = s[1]
		if _finish_if_landed():
			return
	rotation = velocity.angle()


func _finish_if_landed() -> bool:
	var left_bounds := not bounds.has_point(position)
	if not left_bounds and not is_hit.call(position):
		return false
	_done = true
	landed.emit(position, not left_bounds)
	queue_free()
	return true
