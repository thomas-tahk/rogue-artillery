# REPLACE your gun.gd with this:

extends CharacterBody2D

@onready var power_bar = $"../UI/PowerBar"
@onready var angle_indicator_ui = $"../AngleIndicatorUI"
@onready var camera = $Camera2D

func _ready():
	# Set up power bar
	power_bar.min_value = min_power
	power_bar.max_value = max_power
	power_bar.value = min_power
	power_bar.visible = false
	
	# Position power bar at bottom center of screen
	power_bar.anchor_left = 0.5
	power_bar.anchor_right = 0.5
	power_bar.anchor_top = 1.0
	power_bar.anchor_bottom = 1.0
	power_bar.offset_left = -100
	power_bar.offset_right = 100
	power_bar.offset_top = -50
	power_bar.offset_bottom = -20
	power_bar.show_percentage = false
	
	# Position tank in world coordinates where your terrain is
	# Adjust this Vector2 to put tank ON your terrain
	global_position = Vector2(400, 300)  
	
	# Set up camera
	camera.enabled = true
	camera.make_current()
	
	# CRITICAL: Give the indicator time to initialize, then set it up
	call_deferred("setup_angle_indicator")

func setup_angle_indicator():
	if angle_indicator_ui:
		print("Setting up angle indicator...")
		angle_indicator_ui.setup_for_tank(self)
		# Force an initial update
		angle_indicator_ui.update_angle(aim_angle)

var bullet_path = preload("res://src/scenes/bullets.tscn")
var aim_angle = 0.0
var power = 0.0
var min_power = 200.0
var max_power = 1200.0
var charging = false

func _physics_process(delta: float) -> void:
	# Angle control with arrow keys
	if Input.is_action_pressed("ui_left"):
		aim_angle -= 1.0 * delta
		
	if Input.is_action_pressed("ui_right"):
		aim_angle += 1.0 * delta

	# Clamp angle
	aim_angle = clamp(aim_angle, -PI/2, PI/2)
	
	# Send angle to indicator when changing
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		if angle_indicator_ui and angle_indicator_ui.has_method("update_angle"):
			angle_indicator_ui.update_angle(aim_angle)
	
	# Update visual rotation
	rotation = aim_angle

	# Power charging
	if Input.is_action_just_pressed("ui_accept"):
		charging = true
		power = min_power
		print("Started charging") 

	if Input.is_action_pressed("ui_accept") and charging:
		power = min(power + 800.0 * delta, max_power)
		power_bar.value = power
		power_bar.visible = true
		
	if Input.is_action_just_released("ui_accept") and charging:
		print("fired with %d" % power)
		fire()
		charging = false
		power_bar.visible = false

func fire():
	var bullet = bullet_path.instantiate()
	bullet.global_position = $Node2D.global_position + Vector2(30, 0).rotated(aim_angle)
	
	var direction = Vector2(cos(aim_angle), sin(aim_angle))
	get_parent().add_child(bullet)
	bullet.exploded.connect(_on_bullet_exploded)
	bullet.launch(direction, power)
	
func _on_bullet_exploded(explosion_pos: Vector2):
	print("Explosion signal received at: ", explosion_pos)
	var terrain_destroyer = get_parent().get_node("TerrainDestroyer")
	if terrain_destroyer:
		print("TerrainDestroyer found")
		terrain_destroyer.explode_terrain(explosion_pos, 2)
	else:
		print("ERROR: TerrainDestroyer not found!")
