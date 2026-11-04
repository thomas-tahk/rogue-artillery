## Picks (elevation, power) by simulating shots with the same Ballistics the shell flies.
class_name EnemyAI
extends RefCounted

const COARSE_STEP := 10.0
const REFINE_ROUNDS := 5
const GOOD_ENOUGH_PX := 4.0
const GROUND_SCAN_START := 300.0
const GROUND_SCAN_STEP := 8.0
const UNREACHABLE_MIN_PX := 40.0
const MISS_SCORE := 1.0e9

var is_hit: Callable
var bounds: Rect2
var aim_error_px := 60.0
var rng := RandomNumberGenerator.new()


static func facing_for(from: Vector2, target: Vector2) -> int:
	return 1 if target.x >= from.x else -1


## Returns Vector2(elevation_deg 0..90, power_pct 10..100). ~200 first_hit calls per solve.
## If the offset aim point is unreachable (e.g. shooter in a pit), re-solves at the target itself.
func choose_shot(from: Vector2, target: Vector2, wind_accel: float) -> Vector2:
	var query := _query(from, target, wind_accel, _aim_point(target))
	var best := _solve(query)
	if query["aim_at"] != target and _score_shot(query, best) > maxf(aim_error_px, UNREACHABLE_MIN_PX):
		best = _solve(_query(from, target, wind_accel, target))
	return best


func _query(from: Vector2, target: Vector2, wind_accel: float, aim_at: Vector2) -> Dictionary:
	return {"from": from, "facing": facing_for(from, target), "wind": wind_accel, "aim_at": aim_at}


func _solve(query: Dictionary) -> Vector2:
	var step := COARSE_STEP
	var best := _best_on_grid(query, {
		"elevation": Vector2(5.0, 85.0), "power": Vector2(Ballistics.MIN_POWER, Ballistics.MAX_POWER), "step": step})
	for round in REFINE_ROUNDS:
		if _score_shot(query, best) <= GOOD_ENOUGH_PX:
			break
		best = _best_on_grid(query, {
			"elevation": Vector2(best.x - step, best.x + step),
			"power": Vector2(best.y - step, best.y + step), "step": step / 2.0})
		step /= 2.0
	return best


func _aim_point(target: Vector2) -> Vector2:
	if aim_error_px <= 0.0:
		return target
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	var dx := side * rng.randf_range(0.5, 1.0) * aim_error_px
	return _ground_below(Vector2(target.x + dx, target.y - GROUND_SCAN_START))


func _ground_below(start: Vector2) -> Vector2:
	var y := maxf(start.y, bounds.position.y)
	while y > bounds.position.y and is_hit.call(Vector2(start.x, y)):
		y -= GROUND_SCAN_STEP
	while y < bounds.end.y:
		if is_hit.call(Vector2(start.x, y)):
			return Vector2(start.x, y)
		y += GROUND_SCAN_STEP / 2.0
	return start


## grid: {elevation: Vector2(min,max), power: Vector2(min,max), step: float}
func _best_on_grid(query: Dictionary, grid: Dictionary) -> Vector2:
	var best := Vector2(45.0, 60.0)
	var best_score := INF
	var elev: float = grid["elevation"].x
	while elev <= grid["elevation"].y + 0.0001:
		var power: float = grid["power"].x
		while power <= grid["power"].y + 0.0001:
			var shot := Vector2(clampf(elev, 0.0, Ballistics.MAX_ELEVATION), clampf(power, Ballistics.MIN_POWER, Ballistics.MAX_POWER))
			var score := _score_shot(query, shot)
			if score < best_score:
				best_score = score
				best = shot
			power += grid["step"]
		elev += grid["step"]
	return best


func _score_shot(query: Dictionary, shot: Vector2) -> float:
	var vel := Ballistics.launch_velocity(shot.x, query["facing"], shot.y)
	var result := Ballistics.first_hit(query["from"], vel, query["wind"], is_hit, bounds)
	if not result["hit"]:
		return MISS_SCORE
	return result["position"].distance_to(query["aim_at"])
