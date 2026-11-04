class_name Terrain
extends TileMapLayer

const TILE := 16
const MIN_SURFACE := 0.40
const MAX_SURFACE := 0.75
const PAD_CENTERS := [0.15, 0.85]
const PAD_HALF_WIDTH := 3
const TOP_TILE := Vector2i(0, 0)
const FILL_TILE := Vector2i(1, 1)

var _width := 0
var _height := 0


func generate(seed_value: int, width_tiles: int, height_tiles: int) -> void:
	clear()
	_width = width_tiles
	_height = height_tiles
	var rows := _surface_rows(seed_value)
	for col in _width:
		for row in range(rows[col], _height):
			set_cell(Vector2i(col, row), 0, TOP_TILE if row == rows[col] else FILL_TILE)


func is_solid(world_pos: Vector2) -> bool:
	return get_cell_source_id(_cell_of(world_pos)) != -1


func surface_y(world_x: float) -> float:
	var col := int(floorf(world_x / TILE))
	if col < 0 or col >= _width:
		return INF
	for row in _height:
		if get_cell_source_id(Vector2i(col, row)) != -1:
			return float(row * TILE)
	return INF


func destroy_circle(world_pos: Vector2, radius_px: float) -> void:
	var lo := _cell_of(world_pos - Vector2(radius_px, radius_px))
	var hi := _cell_of(world_pos + Vector2(radius_px, radius_px))
	for col in range(maxi(lo.x, 0), mini(hi.x, _width - 1) + 1):
		for row in range(maxi(lo.y, 0), mini(hi.y, _height - 1) + 1):
			var centre := Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
			if centre.distance_to(world_pos) <= radius_px:
				erase_cell(Vector2i(col, row))


func world_rect() -> Rect2:
	return Rect2(0, 0, _width * TILE, _height * TILE)


func _cell_of(world_pos: Vector2) -> Vector2i:
	return Vector2i(floori(world_pos.x / TILE), floori(world_pos.y / TILE))


## Surface row per column: sum of sines (random phase) clamped to the band, pads flattened.
func _surface_rows(seed_value: int) -> PackedInt32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var phases := [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
	var lo := int(ceilf(_height * MIN_SURFACE))
	var hi := int(floorf(_height * MAX_SURFACE))
	var mid := (lo + hi) / 2.0
	var amp := (hi - lo) / 2.0
	var rows := PackedInt32Array()
	for col in _width:
		var wave := 0.55 * sin(col * 0.07 + phases[0]) + 0.3 * sin(col * 0.17 + phases[1]) + 0.15 * sin(col * 0.37 + phases[2])
		rows.append(clampi(roundi(mid + amp * wave), lo, hi))
	_flatten_pads(rows)
	return rows


func _flatten_pads(rows: PackedInt32Array) -> void:
	for frac in PAD_CENTERS:
		var centre := roundi(_width * frac)
		var level := rows[centre]
		for col in range(centre - PAD_HALF_WIDTH, centre + PAD_HALF_WIDTH):
			rows[col] = level
