extends Node

@onready var terrain_layer = $"../TileMapLayer"  # Adjust path to your terrain

func _ready():
	# Connect to bullet explosions - you'll need to do this when creating bullets
	print("TerrainDestroyer ready")
	if terrain_layer:
		print("Terrain layer found: ", terrain_layer.name)
	else:
		print("ERROR: Terrain layer not found!")

func explode_terrain(world_pos: Vector2, radius: int = 2):
	# Convert world position to tile coordinates
	var center_tile = terrain_layer.local_to_map(terrain_layer.to_local(world_pos))
	
	# Create circular explosion
	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var distance = Vector2(x, y).length()
			if distance <= radius:
				var tile_pos = center_tile + Vector2i(x, y)
				terrain_layer.set_cell(tile_pos, -1)  # Remove tile
	
	# Simple explosion effect
	create_explosion_effect(world_pos)

func create_explosion_effect(pos: Vector2):
	# Very basic explosion - just print for now
	print("BOOM at ", pos)
	# TODO: Add particles, screen shake, etc.
