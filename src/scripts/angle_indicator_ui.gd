# angle_indicator_ui.gd
# Fixed version - corrected positioning and angle clamping

extends Node2D

var angle_arc: Line2D
var angle_needle: Line2D
var tank_reference: Node2D
var current_angle: float = 0.0
var indicator_visible: bool = true
var is_player_turn: bool = true
var is_initialized: bool = false

func _ready():
	print("AngleIndicatorUI: _ready() called")
	
	# Create the visual components
	angle_arc = Line2D.new()
	angle_needle = Line2D.new()
	
	add_child(angle_arc)
	add_child(angle_needle)
	
	# Style the arc (shows possible range)
	angle_arc.width = 4
	angle_arc.default_color = Color.RED
	angle_arc.z_index = 100
	
	# Style the needle (shows current aim)
	angle_needle.width = 6
	angle_needle.default_color = Color.CYAN
	angle_needle.z_index = 101
	
	is_initialized = true
	visible = false
	print("AngleIndicatorUI: Initialization complete")

func setup_for_tank(tank: Node2D):
	print("AngleIndicatorUI: setup_for_tank called")
	tank_reference = tank
	visible = true
	
	# FIXED: Set position immediately
	global_position = tank_reference.global_position
	print("AngleIndicatorUI: Set position to: ", global_position)
	
	if is_initialized:
		update_display()

func update_angle(new_angle: float):
	# FIXED: Clamp the angle to prevent crazy values
	current_angle = clamp(new_angle, -PI/2, PI/2)
	print("AngleIndicatorUI: update_angle - input: ", rad_to_deg(new_angle), " clamped: ", rad_to_deg(current_angle))
	
	if is_initialized:
		update_display()

func _process(_delta):
	if tank_reference and visible:
		# FIXED: Always keep synced with tank position
		var new_pos = tank_reference.global_position
		if global_position != new_pos:
			global_position = new_pos
			print("AngleIndicatorUI: Position updated to: ", global_position)

func update_display():
	if not is_initialized or not angle_arc or not angle_needle:
		print("AngleIndicatorUI: update_display - not ready")
		return
		
	if not indicator_visible or not is_player_turn:
		print("AngleIndicatorUI: update_display - hiding")
		angle_arc.visible = false
		angle_needle.visible = false
		return
	
	print("AngleIndicatorUI: update_display - drawing at position: ", global_position)
	
	angle_arc.visible = true
	angle_needle.visible = true
	
	# Clear both lines
	angle_arc.clear_points()
	angle_needle.clear_points()
	
	# Draw arc
	var radius = 50
	var arc_points = 5
	
	for i in range(arc_points):
		var arc_angle_deg = -90 + (i * 45)
		var arc_angle_rad = deg_to_rad(arc_angle_deg)
		var point = Vector2(cos(arc_angle_rad), sin(arc_angle_rad)) * radius
		angle_arc.add_point(point)
	
	# Draw needle with CLAMPED angle
	var needle_length = 40
	var needle_tip = Vector2(cos(current_angle), sin(current_angle)) * needle_length
	
	angle_needle.add_point(Vector2.ZERO)
	angle_needle.add_point(needle_tip)
	print("AngleIndicatorUI: Needle angle: ", rad_to_deg(current_angle), " tip at: ", needle_tip)

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
