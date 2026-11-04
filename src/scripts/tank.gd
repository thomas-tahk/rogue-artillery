## Reusable tank: HP, gravity, fuel-limited driving, aim/power, aim line and HP bar.
## Input is not handled here; Battle reads keys and calls drive/adjust_*.
class_name Tank
extends CharacterBody2D

signal hp_changed(hp: int, max_hp: int)
signal died

const TILE := 16.0
const DRIVE_SPEED := 60.0  # px per second
const MUZZLE_OFFSET := Vector2(17.0, -3.0)  # barrel tip, facing right
const HALF_SIZE := Vector2(19.0, 10.0)
const AIM_LINE_MIN := 20.0
const AIM_LINE_PER_POWER := 0.6
const BAR_SIZE := Vector2(30.0, 4.0)
const BAR_OFFSET_Y := -22.0

@export var team := "player"
@export var facing := 1:
	set(value):
		facing = value
		_apply_facing()

var max_hp := 100
var hp := 100
var aim_deg := 45.0
var power_pct := 60.0
var fuel := 100.0
var show_aim := false:
	set(value):
		show_aim = value
		queue_redraw()

var _died_emitted := false


func _ready() -> void:
	_apply_facing()


func _physics_process(delta: float) -> void:
	velocity.y += Ballistics.GRAVITY * delta
	move_and_slide()


func refuel() -> void:
	fuel = 100.0


func adjust_aim(delta_deg: float) -> void:
	aim_deg = clampf(aim_deg + delta_deg, 0.0, 90.0)
	queue_redraw()


func adjust_power(delta: float) -> void:
	power_pct = clampf(power_pct + delta, 10.0, 100.0)
	queue_redraw()


## Moves up to DRIVE_SPEED * delta px, capped by fuel; spends fuel per px moved.
func drive(direction: int, delta: float) -> void:
	var distance := minf(DRIVE_SPEED * delta, fuel)
	if distance <= 0.0 or direction == 0:
		return
	var motion := Vector2(signf(direction) * distance, 0.0)
	if test_move(global_transform, motion) and not _try_step_up(motion):
		return
	var before := position.x
	move_and_collide(motion)
	fuel = maxf(fuel - absf(position.x - before), 0.0)


func muzzle_position() -> Vector2:
	return global_position + Vector2(MUZZLE_OFFSET.x * facing, MUZZLE_OFFSET.y)


func launch_velocity() -> Vector2:
	return Ballistics.launch_velocity(aim_deg, facing, power_pct)


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(hp - amount, 0)
	hp_changed.emit(hp, max_hp)
	queue_redraw()
	if hp == 0 and not _died_emitted:
		_died_emitted = true
		died.emit()


func is_dead() -> bool:
	return hp <= 0


func contains_point(world_pos: Vector2) -> bool:
	var local := world_pos - global_position
	return absf(local.x) <= HALF_SIZE.x and absf(local.y) <= HALF_SIZE.y


func _try_step_up(motion: Vector2) -> bool:
	var lift := Vector2(0.0, -(TILE + 1.0))
	var raised := global_transform.translated(lift)
	if test_move(global_transform, lift) or test_move(raised, motion):
		return false
	global_position += lift
	return true


func _apply_facing() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.flip_h = facing < 0
	queue_redraw()


func _draw() -> void:
	if show_aim:
		var length := AIM_LINE_MIN + power_pct * AIM_LINE_PER_POWER
		var dir := Vector2(cos(deg_to_rad(aim_deg)) * facing, -sin(deg_to_rad(aim_deg)))
		var start := Vector2(MUZZLE_OFFSET.x * facing, MUZZLE_OFFSET.y)
		draw_line(start, start + dir * length, Color.YELLOW, 2.0)
	_draw_hp_bar()


func _draw_hp_bar() -> void:
	var origin := Vector2(-BAR_SIZE.x / 2.0, BAR_OFFSET_Y)
	var fraction := float(hp) / float(max_hp)
	draw_rect(Rect2(origin, BAR_SIZE), Color(0.1, 0.1, 0.1, 0.8))
	draw_rect(Rect2(origin, Vector2(BAR_SIZE.x * fraction, BAR_SIZE.y)), Color.LIME_GREEN)
