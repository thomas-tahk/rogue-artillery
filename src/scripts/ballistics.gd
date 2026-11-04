## Pure projectile maths shared by Projectile (flight) and EnemyAI (aim search).
## Same function on both paths → the AI predicts exactly what the shell does.
class_name Ballistics
extends RefCounted

const GRAVITY := 980.0
const SPEED_PER_POWER := 12.0
const WIND_ACCEL_PER_UNIT := 8.0


static func launch_velocity(elevation_deg: float, facing: int, power_pct: float) -> Vector2:
	var rad := deg_to_rad(elevation_deg)
	return Vector2(cos(rad) * facing, -sin(rad)) * power_pct * SPEED_PER_POWER


## Semi-implicit Euler. Returns [new_pos, new_vel].
static func step(pos: Vector2, vel: Vector2, wind_accel: float, dt: float) -> PackedVector2Array:
	var new_vel := vel + Vector2(wind_accel, GRAVITY) * dt
	return PackedVector2Array([pos + new_vel * dt, new_vel])


## Substeps needed so one frame never moves more than MAX_STEP_PX (no tunnelling).
const MAX_STEP_PX := 8.0
const FRAME_DT := 1.0 / 60.0
const MAX_FLIGHT_FRAMES := 1800  # 30 s; shared cap for first_hit and Projectile


## Out = left, right or below bounds. Above the top is NOT out (lobs come back down).
static func is_out(pos: Vector2, bounds: Rect2) -> bool:
	return pos.x < bounds.position.x or pos.x > bounds.end.x or pos.y > bounds.end.y


static func substeps(vel: Vector2, dt: float) -> int:
	return maxi(1, ceili(vel.length() * dt / MAX_STEP_PX))


## Points sampled every dt from start, for max_time seconds (includes start).
static func trajectory(start: Vector2, vel: Vector2, wind_accel: float, max_time: float, dt: float) -> PackedVector2Array:
	var points := PackedVector2Array([start])
	var pos := start
	var v := vel
	for i in ceili(max_time / dt):
		var s := step(pos, v, wind_accel, dt)
		pos = s[0]
		v = s[1]
		points.append(pos)
	return points


## Flies the shell in 1/60 s frames, sub-stepped to <= MAX_STEP_PX.
## {hit: true, position} at the first point where is_hit is true;
## {hit: false, position} if it leaves bounds or times out.
static func first_hit(start: Vector2, vel: Vector2, wind_accel: float, is_hit: Callable, bounds: Rect2) -> Dictionary:
	var pos := start
	var v := vel
	for frame in MAX_FLIGHT_FRAMES:
		var n := substeps(v, FRAME_DT)
		for i in n:
			var s := step(pos, v, wind_accel, FRAME_DT / n)
			pos = s[0]
			v = s[1]
			if is_out(pos, bounds):
				return {"hit": false, "position": pos}
			if is_hit.call(pos):
				return {"hit": true, "position": pos}
	return {"hit": false, "position": pos}
