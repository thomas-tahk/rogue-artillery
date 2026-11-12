extends Node2D
# Additive layer: drawing is delegated to the parent so glow stacks as light.
func _draw() -> void:
	get_parent().draw_glow(self)
