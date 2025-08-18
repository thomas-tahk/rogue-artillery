# REPLACE your angle_indicator_ui.gd with this:

extends Node2D

var angle_arc: Line2D
var angle_needle: Line2D
var tank_reference: Node2D
var current_angle: float = 0.0
var indicator_visible: bool = true
var is_player_turn: bool = true
var is_initialized: bool = false

# Positioning controls
var indicator_offset: Vector2 = Vector2(20, -5)  # Offset from tank center (up 40 pixels)
var arc_radius: float = 26                       # Size of the arc
var needle_length: float = 5                   # Length of the needle

func _ready():
	print("AngleIndicatorUI: Starting initialization...")
	
	# Create visual components
	angle_arc = Line2D.new()
	angle_needle = Line2D.new()
	
	add_child(angle_arc)
	add_child(angle_needle)
	
	# Style the arc - VERY VISIBLE for testing
	angle_arc.width = 5
	angle_arc.default_color = Color.RED
	angle_arc.z_index = 100
	
	# Style the needle - VERY VISIBLE for testing  
	angle_needle.width = 8
	angle_needle.default_color = Color.CYAN
	angle_needle.z_index = 101
	
	is_initialized = true
	visible = false
	print("AngleIndicatorUI: Initialization complete")

func setup_for_tank(tank: Node2D):
	print("AngleIndicatorUI: setup_for_tank called with: ", tank.name)
	tank_reference = tank
	visible = true
	
	# Set position immediately
	global_position = tank_reference.global_position
	print("AngleIndicatorUI: Positioned at: ", global_position)
	
	if is_initialized:
		update_display()

func update_angle(new_angle: float):
	current_angle = clamp(new_angle, -PI/2, PI/2)
	if is_initialized:
		update_display()

func _process(_delta):
	if tank_reference and visible:
		update_position()
		
func update_position():
	"""Position the indicator relative to the tank with offset"""
	if tank_reference:
		global_position = tank_reference.global_position + indicator_offset

func update_display():
	if not is_initialized or not angle_arc or not angle_needle:
		return
		
	if not indicator_visible or not is_player_turn:
		angle_arc.visible = false
		angle_needle.visible = false
		return
	
	angle_arc.visible = true
	angle_needle.visible = true
	
	# Clear both lines
	angle_arc.clear_points()
	angle_needle.clear_points()
	
	# Draw arc - BIGGER for visibility
	var arc_points = 5
	
	for i in range(arc_points):
		var arc_angle_deg = -90 + (i * 45)  # -90, -45, 0, 45, 90
		var arc_angle_rad = deg_to_rad(arc_angle_deg)
		var point = Vector2(cos(arc_angle_rad), sin(arc_angle_rad)) * arc_radius
		angle_arc.add_point(point)
	
	# Draw needle - BIGGER for visibility
	var needle_length = 40
	var needle_tip = Vector2(cos(current_angle), sin(current_angle)) * needle_length
	
	angle_needle.add_point(Vector2.ZERO)
	angle_needle.add_point(needle_tip)

func set_indicator_offset(offset: Vector2):
	"""Move the indicator relative to tank (e.g., Vector2(0, -50) = 50 pixels above tank)"""
	indicator_offset = offset
	if tank_reference:
		update_position()

func set_indicator_size(radius: float, needle_len: float):
	"""Change the size of the arc and needle"""
	arc_radius = radius
	needle_length = needle_len
	if is_initialized:
		update_display()

func show_indicator():
	indicator_visible = true
	if is_initialized:
		update_display()

func hide_indicator():
	indicator_visible = false
	if is_initialized and angle_arc and angle_needle:
		angle_arc.visible = false
		angle_needle.visible = false

func set_player_turn(is_turn: bool):
	is_player_turn = is_turn
	if is_initialized:
		update_display()
