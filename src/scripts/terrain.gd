class_name Terrain
extends TileMapLayer

const TILE := 16
const MIN_SURFACE := 0.40
const MAX_SURFACE := 0.75
const PAD_CENTERS: Array[float] = [0.15, 0.85]
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
	var col := _cell_of(Vector2(world_x, 0)).x
	if col < 0 or col >= _width:
		return INF
	for row in _height:
		if get_cell_source_id(Vector2i(col, row)) != -1:
			return to_global(Vector2(0, row * TILE)).y
	return INF


func destroy_circle(world_pos: Vector2, radius_px: float) -> void:
	var local := to_local(world_pos)
	var lo := _local_cell(local - Vector2(radius_px, radius_px))
	var hi := _local_cell(local + Vector2(radius_px, radius_px))
	for col in range(maxi(lo.x, 0), mini(hi.x, _width - 1) + 1):
		for row in range(maxi(lo.y, 0), mini(hi.y, _height - 1) + 1):
			var centre := Vector2(col * TILE + TILE / 2.0, row * TILE + TILE / 2.0)
			if centre.distance_to(local) <= radius_px:
				erase_cell(Vector2i(col, row))


func world_rect() -> Rect2:
	return Rect2(to_global(Vector2.ZERO), Vector2(_width * TILE, _height * TILE))


func _cell_of(world_pos: Vector2) -> Vector2i:
	return _local_cell(to_local(world_pos))


func _local_cell(local_pos: Vector2) -> Vector2i:
	return Vector2i(floori(local_pos.x / TILE), floori(local_pos.y / TILE))


## Surface row per column: sum of sines (random phase) clamped to the band, pads flattened.
func _surface_rows(seed_value: int) -> PackedInt32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var phases: Array[float] = [rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU]
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
	var pad := {}
	for frac: float in PAD_CENTERS:
		var centre := clampi(roundi(_width * frac), 0, _width - 1)
		var level := rows[centre]
		for col in range(maxi(centre - PAD_HALF_WIDTH, 0), mini(centre + PAD_HALF_WIDTH, _width)):
			rows[col] = level
			pad[col] = true
	_limit_steps(rows, pad)


## Make neighbouring columns differ by <= 1 row (tanks climb 1-tile steps). Pad columns stay fixed:
## first confine every column to the +-distance envelope of each pad, then sweep both ways.
func _limit_steps(rows: PackedInt32Array, pad: Dictionary) -> void:
	for col in _width:
		if pad.has(col):
			continue
		for pad_col: int in pad:
			var dist := absi(col - pad_col)
			rows[col] = clampi(rows[col], rows[pad_col] - dist, rows[pad_col] + dist)
	for col in range(1, _width):
		if not pad.has(col):
			rows[col] = clampi(rows[col], rows[col - 1] - 1, rows[col - 1] + 1)
	for col in range(_width - 2, -1, -1):
		if not pad.has(col):
			rows[col] = clampi(rows[col], rows[col + 1] - 1, rows[col + 1] + 1)
