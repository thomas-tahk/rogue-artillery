extends CharacterBody2D

@onready var power_bar = $"../UI/PowerBar"
@onready var angle_indicator_ui = $"../AngleIndicatorUI"

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
	
	# DEBUG: Print camera and tank positions
	print("=== POSITION DEBUG ===")
	print("Tank position: ", global_position)
	print("Viewport size: ", get_viewport().size)
	print("Viewport center: ", get_viewport().size / 2)
	
	# DEBUG: Draw a big visible marker at tank position
	var debug_marker = Line2D.new()
	get_parent().add_child(debug_marker)
	debug_marker.global_position = global_position
	debug_marker.width = 10
	debug_marker.default_color = Color.MAGENTA
	debug_marker.z_index = 200
	# Draw a big X
	debug_marker.add_point(Vector2(-100, -100))
	debug_marker.add_point(Vector2(100, 100))
	debug_marker.add_point(Vector2(999, 999))  # Break
	debug_marker.add_point(Vector2(-100, 100))
	debug_marker.add_point(Vector2(100, -100))
	
	if angle_indicator_ui:
		angle_indicator_ui.setup_for_tank(self)

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
		aim_angle -= 1.0 * delta
		
	if Input.is_action_pressed("ui_right"):
		aim_angle += 1.0 * delta

	# MOVED: Clamp angle BEFORE sending to indicator
	aim_angle = clamp(aim_angle, -PI/2, PI/2)  # -90 to +90 degrees
	
	# NOW send the properly clamped angle to indicator
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		if angle_indicator_ui:
			angle_indicator_ui.update_angle(aim_angle)
	
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
		power_bar.visible = false
	

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
