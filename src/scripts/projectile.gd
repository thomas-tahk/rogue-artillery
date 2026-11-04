## Artillery shell. Deterministic flight via Ballistics.step (no physics body).
class_name Projectile
extends Node2D

signal landed(position: Vector2, exploded: bool)

var velocity := Vector2.ZERO
var wind_accel := 0.0
var is_hit: Callable
var bounds := Rect2()
var _done := false
var _frames := 0


func setup(start: Vector2, start_velocity: Vector2, config: Dictionary) -> void:
	position = start
	velocity = start_velocity
	wind_accel = config["wind_accel"]
	is_hit = config["is_hit"]
	bounds = config["bounds"]
	rotation = velocity.angle()


func _physics_process(_delta: float) -> void:
	advance()


## One fixed Ballistics.FRAME_DT frame (physics delta ignored → matches first_hit exactly).
func advance() -> void:
	if _done:
		return
	var n := Ballistics.substeps(velocity, Ballistics.FRAME_DT)
	for i in n:
		var s := Ballistics.step(position, velocity, wind_accel, Ballistics.FRAME_DT / n)
		position = s[0]
		velocity = s[1]
		if _finish_if_landed():
			return
	_frames += 1
	if _frames >= Ballistics.MAX_FLIGHT_FRAMES:
		_finish(false)
		return
	rotation = velocity.angle()


func _finish_if_landed() -> bool:
	var out := Ballistics.is_out(position, bounds)
	if not out and not is_hit.call(position):
		return false
	_finish(not out)
	return true


func _finish(exploded: bool) -> void:
	_done = true
	landed.emit(position, exploded)
	queue_free()
