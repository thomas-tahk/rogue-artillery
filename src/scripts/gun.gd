extends CharacterBody2D

@onready var power_bar = $"../UI/PowerBar"

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
	bullet.launch(direction, power)
