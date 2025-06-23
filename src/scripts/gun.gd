extends CharacterBody2D

var bullet_path=preload("res://src/scenes/bullets.tscn")

func _physics_process(delta: float) -> void:
	position = get_viewport().size / 2
	look_at(get_global_mouse_position())
	if Input.is_action_just_pressed("ui_accept"):
		fire()
func fire():
	var bullet=bullet_path.instantiate()
	bullet.dir=rotation
	bullet.pos=$Node2D.global_position
	bullet.rota=global_rotation
	get_parent().add_child(bullet)
