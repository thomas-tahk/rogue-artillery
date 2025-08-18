extends CharacterBody2D

@onready var power_bar = $"../UI/PowerBar"

@onready var angle_arc: Line2D
@onready var angle_needle: Line2D
var indicator_visible: bool = true
var is_player_turn: bool = true

func _ready():
	# Set up power bar
	power_bar.min_value = min_power
	power_bar.max_value = max_power
	power_bar.value = min_power
	power_bar.visible = false  # Hide until charging
	
	# Position at bottom center of screen
	power_bar.anchor_left = 0.5
	power_bar.anchor_right = 0.5
	power_bar.anchor_top = 1.0
	power_bar.anchor_bottom = 1.0
	power_bar.offset_left = -100  # Half the width (200px bar)
	power_bar.offset_right = 100
	power_bar.offset_top = -50    # 50px from bottom
	power_bar.offset_bottom = -20
	
	# Style it
	power_bar.show_percentage = false  # Remove that % text
	
	# angle indicator setup via 2 line2D nodes
	angle_arc = Line2D.new()
	angle_needle = Line2D.new()
	
	add_child(angle_arc)
	add_child(angle_needle)
	
	# style the needle (background gauge)
	angle_needle.width = 3
	angle_needle.default_color = Color.YELLOW
	angle_needle.z_index = 10
	
	# style the arc (current aim direction)
	angle_arc.width = 2
	angle_arc.default_color = Color.WHITE
	angle_arc.z_index = 9
	
	update_angle_indicator()

var bullet_path=preload("res://src/scenes/bullets.tscn")
var aim_angle = 0.0  # Angle in radians
var power = 0.0
var min_power = 200.0
var max_power = 1200.0
var charging = false

func _physics_process(delta: float) -> void:
	position = get_viewport().size / 2
	# Angle control with arrow keys
	if Input.is_action_pressed("ui_left"):
		aim_angle -= 1.0 * delta  # Adjust speed as needed
	if Input.is_action_pressed("ui_right"):
		aim_angle += 1.0 * delta

	# Clamp angle (for semblance of realistic artillery limits)
	aim_angle = clamp(aim_angle, -PI/2, PI/2)  # -90 to +90 degrees
	# Update visual rotation
	rotation = aim_angle

	if Input.is_action_just_pressed("ui_accept"):
		charging = true
		power = min_power
		print("Started charging") 

	# Power charging
	if Input.is_action_pressed("ui_accept") and charging:
		power = min(power + 800.0 * delta, max_power)
		power_bar.value = power
		power_bar.visible = true
	if Input.is_action_just_released("ui_accept") and charging:
		print("fired with %d" % power)
		fire()
		charging = false
		power_bar.visible = false  # Hide after firing	
	

func fire():
	var bullet = bullet_path.instantiate()
	bullet.global_position = $Node2D.global_position + Vector2(30, 0).rotated(aim_angle)
	
	# Calculate direction from angle
	var direction = Vector2(cos(aim_angle), sin(aim_angle))
	
	get_parent().add_child(bullet)
	
	# connect explosion signal
	bullet.exploded.connect(_on_bullet_exploded)
	
	bullet.launch(direction, power)
	
func _on_bullet_exploded(explosion_pos: Vector2):
	# call terrain destruction
	print("Explosion signal received at: ", explosion_pos)
	var terrain_destroyer = get_parent().get_node("TerrainDestroyer")
	if terrain_destroyer:
		print("TerrainDestroyer found")
		terrain_destroyer.explode_terrain(explosion_pos, 2)
	else:
		print("ERROR: TerrainDestroyer not found!")

func update_angle_indicator():
	if not indicator_visible or not is_player_turn:
		angle_arc.visible = false
		angle_needle.visible = false
		return
		
	angle_arc.visible = true
	angle_needle.visible = true
	
	# Clear both lines
	angle_arc.clear_points()
	angle_needle.clear_points()
	
	# Draw the background arc (gauge)
	var radius = 25
	var arc_points = 5
	
	for i in range(arc_points):
		var arc_angle_deg = -90 + (i * 45)  # -90, -45, 0, 45, 90 degrees
		var arc_angle_rad = deg_to_rad(arc_angle_deg)
		var point = Vector2(cos(arc_angle_rad), sin(arc_angle_rad)) * radius
		angle_arc.add_point(point)
	
	# Draw the needle (separate line, no crazy jumps)
	var needle_length = 20
	var needle_tip = Vector2(cos(aim_angle), sin(aim_angle)) * needle_length
	
	angle_needle.add_point(Vector2.ZERO)  # Start at center
	angle_needle.add_point(needle_tip)    # End at tip

# Functions to control indicator visibility (for future turn system)
func show_angle_indicator():
	indicator_visible = true
	update_angle_indicator()

func hide_angle_indicator():
	indicator_visible = false
	angle_arc.visible = false
	angle_needle.visible = false

func set_player_turn(is_turn: bool):
	is_player_turn = is_turn
	update_angle_indicator()
