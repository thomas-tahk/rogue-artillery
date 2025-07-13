extends RigidBody2D

#var launch_power = 800.0  # You can adjust this value

func _ready():
	# Enable gravity (1.0 = normal Earth gravity)
	gravity_scale = 1.0
	
func launch(direction: Vector2, power: float):
	# Apply impulse = instant force applied once
	apply_impulse(direction * power)
