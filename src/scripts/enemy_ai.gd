## Picks (elevation, power) by simulating shots with the same Ballistics the shell flies.
class_name EnemyAI
extends RefCounted

const MIN_POWER := 10.0
const MAX_POWER := 100.0
const MAX_ELEVATION := 90.0
const REFINE_ROUNDS := 3
const MISS_SCORE := 1.0e9

var is_hit: Callable
var bounds: Rect2
var aim_error_px := 60.0
var rng := RandomNumberGenerator.new()


## Returns Vector2(elevation_deg 0..90, power_pct 10..100). ~700 first_hit calls.
func choose_shot(from: Vector2, target: Vector2, wind_accel: float) -> Vector2:
	var facing := 1 if target.x >= from.x else -1
	var aim_at := target + _random_offset()
	var elev_step := 4.0
	var power_step := 4.0
	var best := _best_on_grid(from, facing, wind_accel, aim_at,
			[5.0, 85.0, elev_step, MIN_POWER, MAX_POWER, power_step])
	for round in REFINE_ROUNDS:
		var window := [best.x - elev_step, best.x + elev_step, elev_step / 4.0,
				best.y - power_step, best.y + power_step, power_step / 4.0]
		best = _best_on_grid(from, facing, wind_accel, aim_at, window)
		elev_step /= 4.0
		power_step /= 4.0
	return best


func _random_offset() -> Vector2:
	if aim_error_px <= 0.0:
		return Vector2.ZERO
	return Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(0.0, aim_error_px)


## grid = [elev_min, elev_max, elev_step, power_min, power_max, power_step]
func _best_on_grid(from: Vector2, facing: int, wind_accel: float, aim_at: Vector2, grid: Array) -> Vector2:
	var best := Vector2(45.0, 60.0)
	var best_score := INF
	var elev: float = grid[0]
	while elev <= grid[1] + 0.0001:
		var power: float = grid[3]
		while power <= grid[4] + 0.0001:
			var e := clampf(elev, 0.0, MAX_ELEVATION)
			var p := clampf(power, MIN_POWER, MAX_POWER)
			var score := _score(from, Ballistics.launch_velocity(e, facing, p), wind_accel, aim_at)
			if score < best_score:
				best_score = score
				best = Vector2(e, p)
			power += grid[5]
		elev += grid[2]
	return best


func _score(from: Vector2, vel: Vector2, wind_accel: float, aim_at: Vector2) -> float:
	var result := Ballistics.first_hit(from, vel, wind_accel, is_hit, bounds)
	if not result["hit"]:
		return MISS_SCORE
	return result["position"].distance_to(aim_at)
