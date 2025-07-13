extends CharacterBody2D

var bullet_path=preload("res://src/scenes/bullets.tscn")

func _physics_process(delta: float) -> void:
	position = get_viewport().size / 2
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("ui_accept"):
		fire()
		
func fire():
	var bullet = bullet_path.instantiate()
	bullet.global_position = $Node2D.global_position
	
	# Calculate direction to mouse
	var direction = (get_global_mouse_position() - $Node2D.global_position).normalized()
	
	get_parent().add_child(bullet)
	bullet.launch(direction)
