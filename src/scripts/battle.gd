## Main scene: terrain, two tanks, turn loop, wind, damage, win/lose, restart.
class_name Battle
extends Node2D

signal battle_ended(player_won: bool)

enum Phase { SPAWN, AIM, THINK, FLYING, SETTLE, OVER }

const TANK_SCENE := preload("res://src/scenes/tank.tscn")
const PROJECTILE_SCENE := preload("res://src/scenes/projectile.tscn")
const WORLD_TILES := Vector2i(100, 40)
const WORLD_PX := Vector2(WORLD_TILES * Terrain.TILE)
const BLAST_RADIUS := 40.0
const BLAST_DAMAGE := 50.0
const BLAST_FALLOFF_RADIUS := BLAST_RADIUS + 16.0
const THINK_TIME := 1.2
const SETTLE_TIME := 1.0
const AIM_ERROR_START := 150.0
const AIM_ERROR_DECAY := 0.7
const AIM_ERROR_FLOOR := 35.0
const FALL_MARGIN := 40.0
const HOLD_DELAY := 0.3
const AIM_RATE := 30.0
const POWER_RATE := 30.0
## key -> [property, direction]
const ADJUST_KEYS := {
	KEY_UP: ["aim", 1.0], KEY_DOWN: ["aim", -1.0], KEY_W: ["power", 1.0], KEY_S: ["power", -1.0],
}

@export var player_is_ai := false
@export var battle_seed := 0

var player: Tank
var enemy: Tank
var turn_count := 0
var wind := 0

var _phase := Phase.SPAWN
var _timer := 0.0
var _player_turn := true
var _generation := 0
var _held: Dictionary = {}
var _aim_error: Array[float] = [AIM_ERROR_START, AIM_ERROR_START]  # per side: 0 player, 1 enemy
var _trails := ShotTrails.new()
var _shell: Projectile
var _ai := EnemyAI.new()
var _rng := RandomNumberGenerator.new()

@onready var terrain: Terrain = $Terrain
@onready var _camera: Camera2D = $Camera2D
@onready var _hud: Hud = $Hud


func _ready() -> void:
	_trails.z_index = 5
	add_child(_trails)
	_read_debug_flags()
	_hud.restart_requested.connect(restart)
	get_viewport().size_changed.connect(_frame_world)
	_frame_world()
	start_battle(battle_seed)


func _physics_process(delta: float) -> void:
	if _phase == Phase.SPAWN or _phase == Phase.OVER:
		return
	_kill_fallen_tanks()
	_refresh_hud()
	match _phase:
		Phase.FLYING:
			_track_shell()
		Phase.AIM:
			_player_input(delta)
			_check_over()
		Phase.THINK:
			if _check_over():
				return
			_timer -= delta
			if _timer <= 0.0:
				_ai_fire()
		Phase.SETTLE:
			_timer -= delta
			if _timer <= 0.0 and not _check_over():
				_begin_turn(not _player_turn)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.keycode == KEY_R:
		restart()
	elif _human_aiming() and key.keycode == KEY_SPACE:
		_fire(player, _hit_test(enemy))
	elif _human_aiming() and ADJUST_KEYS.has(key.keycode):
		_held[key.keycode] = 0.0
		_adjust(key.keycode, 1.0, false)


func restart() -> void:
	start_battle(0)


func start_battle(seed_value: int) -> void:
	_generation += 1
	var generation := _generation
	_phase = Phase.SPAWN
	_hud.hide_result()
	_clear_actors()
	_trails.clear()
	_aim_error = [AIM_ERROR_START, AIM_ERROR_START]
	var used_seed := seed_value if seed_value != 0 else randi()
	_rng.seed = used_seed
	_ai.rng.seed = used_seed + 1
	terrain.generate(used_seed, WORLD_TILES.x, WORLD_TILES.y)
	player = _spawn_tank("player", 1)
	enemy = _spawn_tank("enemy", -1)
	turn_count = 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	if generation != _generation:
		return
	player.set_physics_process(true)
	enemy.set_physics_process(true)
	for i in 60:
		if player.is_on_floor() and enemy.is_on_floor():
			break
		await get_tree().physics_frame
	if generation == _generation:
		_begin_turn(true)


## Carves a crater and damages every tank in range (the shooter included).
func resolve_explosion(blast: Vector2) -> void:
	terrain.destroy_circle(blast, BLAST_RADIUS)
	for tank: Tank in [player, enemy]:
		var amount := _damage_at(tank, blast)
		if amount > 0:
			tank.take_damage(amount)


func _damage_at(tank: Tank, blast: Vector2) -> int:
	if tank.contains_point(blast):
		return roundi(BLAST_DAMAGE)
	var distance := tank.global_position.distance_to(blast)
	return maxi(roundi(BLAST_DAMAGE * (1.0 - distance / BLAST_FALLOFF_RADIUS)), 0)


func _clear_actors() -> void:
	if is_instance_valid(_shell):
		_shell.free()
	_shell = null
	for node in get_children():
		if node is Tank:
			node.queue_free()


func _spawn_tank(team: String, facing: int) -> Tank:
	var tank: Tank = TANK_SCENE.instantiate()
	var fraction := Terrain.PAD_CENTERS[0 if team == "player" else 1]
	var x := roundf(WORLD_TILES.x * fraction) * Terrain.TILE + Terrain.TILE / 2.0
	tank.team = team
	tank.facing = facing
	tank.position = Vector2(x, terrain.surface_y(x) - 16.0)
	tank.set_physics_process(false)
	tank.died.connect(_on_tank_died.bind(tank))
	add_child(tank)
	tank.set_tint(Color(0.2, 1.0, 0.3) if team == "player" else Color(1.0, 0.25, 0.2))
	return tank


func _on_tank_died(tank: Tank) -> void:
	tank.get_node("Sprite2D").modulate = Color(0.2, 0.2, 0.2)
	tank.show_aim = false


func _begin_turn(player_side: bool) -> void:
	_player_turn = player_side
	turn_count += 1
	wind = _rng.randi_range(-10, 10)
	var active := _active()
	active.facing = EnemyAI.facing_for(active.global_position, _opponent().global_position)
	active.refuel()
	player.show_aim = player_side and not player_is_ai
	_timer = THINK_TIME
	_phase = Phase.AIM if player.show_aim else Phase.THINK
	_hud.set_wind(wind)
	_hud.set_turn(_turn_text())


func _turn_text() -> String:
	if _player_turn:
		return "PLAYER (AI) TURN" if player_is_ai else "YOUR TURN"
	return "ENEMY TURN"


func _active() -> Tank:
	return player if _player_turn else enemy


func _opponent() -> Tank:
	return enemy if _player_turn else player


func _human_aiming() -> bool:
	return _phase == Phase.AIM and not player_is_ai


func _player_input(delta: float) -> void:
	var direction := int(Input.is_key_pressed(KEY_RIGHT)) - int(Input.is_key_pressed(KEY_LEFT))
	if direction != 0:
		player.drive(direction, delta)
	for keycode: int in ADJUST_KEYS:
		_hold_adjust(keycode, delta)


func _hold_adjust(keycode: int, delta: float) -> void:
	if not Input.is_key_pressed(keycode):
		_held.erase(keycode)
		return
	_held[keycode] = _held.get(keycode, 0.0) + delta
	if _held[keycode] > HOLD_DELAY:
		_adjust(keycode, delta, true)


## A tap moves 1 unit; holding moves rate * seconds.
func _adjust(keycode: int, seconds: float, held: bool) -> void:
	var rule: Array = ADJUST_KEYS[keycode]
	var is_aim: bool = rule[0] == "aim"
	var amount: float = rule[1] * ((AIM_RATE if is_aim else POWER_RATE) * seconds if held else 1.0)
	if is_aim:
		player.adjust_aim(amount)
	else:
		player.adjust_power(amount)


func _hit_test(target: Tank) -> Callable:
	return func(point: Vector2) -> bool: return terrain.is_solid(point) or target.contains_point(point)


func _ai_fire() -> void:
	var shooter := _active()
	var target := _opponent()
	var hit := _hit_test(target)
	_ai.is_hit = hit
	_ai.bounds = terrain.world_rect()
	var side := 0 if _player_turn else 1
	_ai.aim_error_px = _aim_error[side]
	_aim_error[side] = maxf(_aim_error[side] * AIM_ERROR_DECAY, AIM_ERROR_FLOOR)
	var shot := _ai.choose_shot(shooter.muzzle_position(), target.global_position, wind * Ballistics.WIND_ACCEL_PER_UNIT)
	shooter.aim_deg = shot.x
	shooter.power_pct = shot.y
	_fire(shooter, hit)


func _fire(shooter: Tank, hit: Callable) -> void:
	_phase = Phase.FLYING
	shooter.show_aim = false
	_trails.begin(0 if _player_turn else 1)
	var shell: Projectile = PROJECTILE_SCENE.instantiate()
	add_child(shell)
	_shell = shell
	shell.setup(shooter.muzzle_position(), shooter.launch_velocity(), {
		"wind_accel": wind * Ballistics.WIND_ACCEL_PER_UNIT, "is_hit": hit, "bounds": terrain.world_rect()})
	shell.landed.connect(_on_shell_landed.bind(_generation))


func _track_shell() -> void:
	if is_instance_valid(_shell):
		_trails.add_point(_shell.global_position)


func _on_shell_landed(blast: Vector2, exploded: bool, generation: int) -> void:
	if generation != _generation or _phase != Phase.FLYING:
		return
	_trails.add_point(blast)
	_trails.finish()
	if exploded:
		resolve_explosion(blast)
	_timer = SETTLE_TIME
	_phase = Phase.SETTLE


func _kill_fallen_tanks() -> void:
	var limit := terrain.world_rect().end.y + FALL_MARGIN
	for tank: Tank in [player, enemy]:
		if tank.global_position.y > limit:
			tank.take_damage(tank.max_hp)


func _check_over() -> bool:
	if _phase == Phase.OVER:
		return true
	if not (player.is_dead() or enemy.is_dead()):
		return false
	_phase = Phase.OVER
	var player_won := enemy.is_dead() and not player.is_dead()
	_hud.show_result(player_won)
	battle_ended.emit(player_won)
	return true


func _refresh_hud() -> void:
	var active := _active()
	_hud.set_aim(active.aim_deg, active.power_pct)
	_hud.set_fuel(active.fuel)


func _frame_world() -> void:
	var view := get_viewport().get_visible_rect().size
	var fit := minf(view.x / WORLD_PX.x, view.y / WORLD_PX.y)
	_camera.zoom = Vector2(fit, fit)
	_camera.position = WORLD_PX / 2.0


## Debug-only web query flags: ?autoplay=1 (AI plays the player side), ?seed=N.
func _read_debug_flags() -> void:
	if not OS.has_feature("web"):
		return
	var query := str(JavaScriptBridge.eval("window.location.search"))
	if query.contains("autoplay=1"):
		player_is_ai = true
	for part in query.trim_prefix("?").split("&"):
		if part.begins_with("seed="):
			battle_seed = part.trim_prefix("seed=").to_int()
