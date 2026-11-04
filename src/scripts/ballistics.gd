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
