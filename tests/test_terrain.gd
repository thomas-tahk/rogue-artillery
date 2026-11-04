extends "res://tests/test_case.gd"

const W := 100
const H := 40


func _make(seed_value: int) -> Terrain:
	var t: Terrain = load("res://src/scenes/terrain.tscn").instantiate()
	add_child(t)
	t.generate(seed_value, W, H)
	return t


func _tiles(t: Terrain) -> Array:
	var cells: Array = t.get_used_cells()
	cells.sort()
	return cells


func test_same_seed_identical_different_seed_differs() -> void:
	var a := _make(42)
	var b := _make(42)
	var c := _make(43)
	check(_tiles(a).size() > 0, "terrain has tiles")
	check(_tiles(a) == _tiles(b), "same seed gives identical tiles")
	check(_tiles(a) != _tiles(c), "different seed gives different tiles")
	for n in [a, b, c]:
		n.queue_free()


func test_surface_within_band_and_pads_flat() -> void:
	for seed_value in [1, 2, 3, 99, 12345]:
		var t := _make(seed_value)
		for col in W:
			var y := t.surface_y(col * 16 + 8)
			check(y >= 0.40 * H * 16 and y <= 0.75 * H * 16, "seed %d col %d surface in 40-75%%, got %s" % [seed_value, col, y])
		for centre in [15, 85]:
			var ref := t.surface_y((centre - 3) * 16 + 8)
			for col in range(centre - 3, centre + 3):
				check_eq(t.surface_y(col * 16 + 8), ref, "seed %d pad %d col %d flat" % [seed_value, centre, col])
		t.queue_free()


func test_destroy_circle_removes_inside_keeps_outside() -> void:
	var t := _make(7)
	var centre := Vector2(50 * 16 + 8, t.surface_y(50 * 16 + 8) + 24)
	var radius := 40.0
	var before := _tiles(t)
	t.destroy_circle(centre, radius)
	var after := _tiles(t)
	for cell in before:
		var tile_centre := Vector2(cell.x * 16 + 8, cell.y * 16 + 8)
		var inside := tile_centre.distance_to(centre) <= radius
		check_eq(after.has(cell), not inside, "cell %s survival" % [cell])
	check(after.size() < before.size(), "something was carved")
	t.queue_free()


func test_is_solid_agrees_with_tiles() -> void:
	var t := _make(5)
	for cell in t.get_used_cells():
		check(t.is_solid(Vector2(cell.x * 16 + 8, cell.y * 16 + 8)), "tile %s solid" % [cell])
	check(not t.is_solid(Vector2(8, 8)), "sky is not solid")
	check(not t.is_solid(Vector2(-5, 400)), "left of world")
	check(not t.is_solid(Vector2(1700, 400)), "right of world")
	check(not t.is_solid(Vector2(400, -5)), "above world")
	check(not t.is_solid(Vector2(400, 700)), "below world")
	t.queue_free()


func test_surface_y_inf_for_emptied_column_and_world_rect() -> void:
	var t := _make(5)
	t.destroy_circle(Vector2(30 * 16 + 8, 320), 2000.0)
	check_eq(t.surface_y(30 * 16 + 8), INF, "emptied column is INF")
	check_eq(t.world_rect(), Rect2(0, 0, 1600, 640), "world rect")
	t.queue_free()
