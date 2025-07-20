extends RigidBody2D

# detecting bullet impact
signal exploded(position)

func _ready():
	# Enable gravity (1.0 = normal Earth gravity)
	gravity_scale = 1.0
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body):
	print("Bullet hit something: ", body.name, " Type: ", body.get_class())
	if body.name.contains("TileMapLayer") or body.is_in_group("terrain"):
		print("Terrain hit detected!!") 
		exploded.emit(global_position)
		queue_free() # Remove bullet
	else:
		print("Not terrain - continuing...")
	
func launch(direction: Vector2, power: float):
	# Apply impulse = instant force applied once
	apply_impulse(direction * power)
