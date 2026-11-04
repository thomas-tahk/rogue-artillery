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


func _top_row(t: Terrain, col: int) -> int:
	var best := 9999
	for cell in t.get_used_cells():
		if cell.x == col:
			best = mini(best, cell.y)
	return best


func test_surface_y_exact_and_solid_boundary() -> void:
	var t := _make(11)
	for col in W:
		var x := col * 16 + 8
		var top := _top_row(t, col)
		check_eq(t.surface_y(x), float(top * 16), "col %d surface_y" % col)
		check(t.is_solid(Vector2(x, top * 16 + 1)), "col %d solid just below surface" % col)
		check(not t.is_solid(Vector2(x, top * 16 - 1)), "col %d empty just above surface" % col)
	t.queue_free()


func test_adjacent_columns_differ_by_at_most_one_row() -> void:
	for seed_value in 50:
		var t := _make(seed_value)
		for col in W - 1:
			var d := absf(t.surface_y(col * 16 + 8) - t.surface_y((col + 1) * 16 + 8))
			check(d <= 16.0, "seed %d cols %d/%d step %s" % [seed_value, col, col + 1, d])
		t.queue_free()


func test_narrow_world_does_not_crash() -> void:
	var t: Terrain = load("res://src/scenes/terrain.tscn").instantiate()
	add_child(t)
	t.generate(1, 10, 40)
	check_eq(t.world_rect(), Rect2(0, 0, 160, 640), "narrow world rect")
	t.queue_free()


func test_offset_node_uses_world_coordinates() -> void:
	var t := _make(5)
	t.position = Vector2(100, 50)
	var x := 100.0 + 30 * 16 + 8
	check_eq(t.surface_y(x), float(_top_row(t, 30) * 16) + 50.0, "offset surface_y")
	check(t.is_solid(Vector2(x, t.surface_y(x) + 1)), "offset is_solid")
	check_eq(t.world_rect(), Rect2(100, 50, 1600, 640), "offset world_rect")
	t.destroy_circle(Vector2(x, t.surface_y(x) + 8), 4.0)
	check(not t.is_solid(Vector2(x, t.surface_y(x) - 1)), "offset destroy")
	t.queue_free()
