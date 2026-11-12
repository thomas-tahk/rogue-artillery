extends RefCounted
## Procedural pixel-art helpers. Everything snaps to a shared palette.

const W := 640
const H := 360
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

const INK := Color("1b1030")
const SKY := ["2a1d54", "4a2a7a", "7a3a86", "b04a82", "e0685f", "ff9a62", "ffc578"]
const GRASS_HI := Color("c4f065")
const GRASS := Color("62c24a")
const GRASS_DK := Color("2f8a48")
const SOIL := ["9a6448", "74483c", "533340", "36213f"]
const CHAR := Color("2a1a2e")

static func bayer(x: int, y: int) -> float:
	return (BAYER[(y & 3) * 4 + (x & 3)] + 0.5) / 16.0

static func hash2(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65535.0

static func new_img(w: int, h: int) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	return img

static func put(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)

## Ordered-dither pick along a colour ramp. f in [0, n-1].
static func ramp(cols: Array, f: float, x: int, y: int) -> Color:
	f = clampf(f, 0.0, cols.size() - 1.001)
	var i := int(f)
	var c: Color = Color(cols[i + 1]) if (f - i) > bayer(x, y) else Color(cols[i])
	return c

# ---------------------------------------------------------------- sky
static func make_sky() -> Image:
	var img := new_img(W, H)
	for y in H:
		for x in W:
			var f := float(y) / 250.0 * (SKY.size() - 1)
			var d := Vector2((x - 360) * 0.5, y - 235).length()
			f += clampf(1.0 - d / 170.0, 0.0, 1.0) * 1.3
			img.set_pixel(x, y, ramp(SKY, f, x, y))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 70:
		var sx := rng.randi_range(0, W - 1)
		var sy := rng.randi_range(0, 95)
		var c := Color("ffe9c4") if rng.randf() > 0.3 else Color("c9a6e8")
		put(img, sx, sy, c)
		if rng.randf() > 0.9:
			put(img, sx + 1, sy, c)
			put(img, sx - 1, sy, c)
			put(img, sx, sy + 1, c)
			put(img, sx, sy - 1, c)
	for y in range(190, 250):
		for x in range(320, 401):
			var d2 := Vector2(x - 360, y - 232).length()
			if d2 < 24:
				put(img, x, y, Color("fff0b0") if d2 < 18 else Color("ffd98a"))
	return img

static func make_clouds() -> Image:
	var img := new_img(W, H)
	var n := FastNoiseLite.new()
	n.seed = 11
	n.frequency = 0.018
	n.fractal_octaves = 3
	var cols := ["5c3a8a", "9a4a8c", "e0685f", "ffa070"]
	for y in range(40, 190):
		for x in W:
			var v := n.get_noise_2d(x * 0.6, y * 2.6)
			var edge := 0.22 + 0.25 * absf(y - 118) / 80.0
			if v > edge:
				var lit := clampf((y - 70.0) / 100.0, 0, 1)
				put(img, x, y, ramp(cols, lit * 3.0 - (v - edge) * 2.0 + 0.6, x, y))
	return img

# ------------------------------------------------------ parallax layers
static func make_ridge(seed_: int, base: float, amp: float, freq: float,
		body: Color, rim: Color, haze: Color, haze_h: float) -> Image:
	var img := new_img(W, H)
	var n := FastNoiseLite.new()
	n.seed = seed_
	n.frequency = freq
	n.fractal_octaves = 4
	for x in W:
		var top := int(base - amp * (0.5 + 0.5 * n.get_noise_1d(x)))
		for y in range(top, int(base + haze_h) + 1):
			var c := body
			if y - top < 2:
				c = rim
			var hz := clampf((y - (base - 10.0)) / haze_h, 0.0, 1.0)
			if hz > bayer(x, y):
				c = haze
			put(img, x, y, c)
	return img

static func make_trees(seed_: int, base: float, col: Color, rim: Color) -> Image:
	var img := new_img(W, H)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_
	var x := -4
	while x < W + 8:
		var h := rng.randi_range(16, 34)
		var half := rng.randi_range(4, 6)
		for row in h:
			var w := int(half * (float(row) / h)) + (1 if row % 3 == 0 else 0)
			var y := int(base) - h + row
			for dx in range(-w, w + 1):
				var c := col
				if dx >= w - 1 and w > 1 and row % 2 == 0:
					c = rim
				put(img, x + dx, y, c)
		x += rng.randi_range(6, 13)
	for y in range(int(base), int(base) + 60):
		for xx in W:
			put(img, xx, y, col)
	return img

# ------------------------------------------------------------ terrain
static func height_at(x: float) -> float:
	return 245.0 + 10.0 * sin(x * 0.018 + 0.5) + 6.0 * sin(x * 0.043) \
		- 30.0 * exp(-pow((x - 125.0) / 60.0, 2)) - 14.0 * exp(-pow((x - 500.0) / 50.0, 2))

static func make_terrain(crater: Vector3) -> Image:
	var solid := PackedByteArray()
	solid.resize(W * H)
	for x in W:
		var top := int(height_at(x))
		for y in H:
			var s := 1 if y >= top else 0
			if s == 1:
				var d := Vector2(x - crater.x, y - crater.y).length()
				var r := crater.z * (1.0 + 0.08 * sin(x * 0.9))
				if d < r:
					s = 0
			solid[y * W + x] = s
	var img := new_img(W, H)
	for x in W:
		var depth := 0
		for y in H:
			if solid[y * W + x] == 0:
				depth = 0
				continue
			depth += 1
			img.set_pixel(x, y, _terrain_px(solid, x, y, depth, crater))
	_add_tufts(img, solid, crater)
	return img

static func _air(solid: PackedByteArray, x: int, y: int) -> bool:
	return x < 0 or y < 0 or x >= W or y >= H or solid[y * W + x] == 0

static func _near_air(solid: PackedByteArray, x: int, y: int) -> int:
	for s in range(1, 7):
		if _air(solid, x, y - s) or _air(solid, x - s, y - s) or _air(solid, x + s, y - s) \
				or (s < 4 and (_air(solid, x - s, y) or _air(solid, x + s, y))):
			return s - 1
	return 99

static func _terrain_px(solid: PackedByteArray, x: int, y: int, depth: int, crater: Vector3) -> Color:
	var cd := Vector2(x - crater.x, y - crater.y).length()
	var edge := cd - crater.z
	var d := _near_air(solid, x, y)
	var scorched := edge < 7.0 and edge / 7.0 < 1.0 - bayer(x, y) * 0.9
	if scorched:
		if d == 0:
			return Color("5a3a44")
		return CHAR if hash2(x, y) > 0.12 else Color("4a2e3c")
	if d == 0:
		return GRASS_HI
	if d <= 2:
		return GRASS
	if d <= 4:
		return GRASS_DK if bayer(x, y) < 0.8 else GRASS
	var wob := 5.0 * sin(x * 0.04) + 3.0 * sin(x * 0.11)
	var f := (depth + wob) / 26.0
	var c := ramp(SOIL, f, x, y)
	if int(depth + wob) % 14 == 0 and depth > 8:
		c = c.lightened(0.14)
	var hv := hash2(x, y)
	if hv > 0.985:
		c = Color("b59a92")
	elif hv < 0.012:
		c = c.darkened(0.3)
	return c

static func _add_tufts(img: Image, solid: PackedByteArray, crater: Vector3) -> void:
	for x in W:
		if absf(x - crater.x) < crater.z + 8:
			continue
		var top := 0
		while top < H and solid[top * W + x] == 0:
			top += 1
		var hv := hash2(x, 99)
		if hv > 0.6:
			put(img, x, top - 1, GRASS)
		if hv > 0.85:
			put(img, x, top - 2, GRASS_HI)

# --------------------------------------------------------------- tanks
static func fill_poly(img: Image, pts: Array, col: Color) -> void:
	var poly := PackedVector2Array(pts)
	for y in img.get_height():
		for x in img.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
				img.set_pixel(x, y, col)

static func fill_circle(img: Image, c: Vector2, r: float, col: Color) -> void:
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			if Vector2(x + 0.5, y + 0.5).distance_to(c) <= r:
				put(img, x, y, col)

static func outline(img: Image, col: Color) -> Image:
	var out := new_img(img.get_width() + 2, img.get_height() + 2)
	out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(1, 1))
	var src := out.duplicate() as Image
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for y in out.get_height():
		for x in out.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for o in dirs:
				var p: Vector2i = Vector2i(x, y) + o
				if p.x >= 0 and p.y >= 0 and p.x < out.get_width() and p.y < out.get_height() \
						and src.get_pixel(p.x, p.y).a > 0.0:
					out.set_pixel(x, y, col)
					break
	return out

static func make_tank(hi: Color, mid: Color, dk: Color, accent: Color) -> Image:
	var img := new_img(32, 20)
	var track := dk.darkened(0.35)
	fill_poly(img, [Vector2(3, 12), Vector2(29, 12), Vector2(30, 15), Vector2(27, 18), Vector2(5, 18), Vector2(2, 15)], track)
	for cx in [7, 12, 17, 22, 27]:
		fill_circle(img, Vector2(cx, 15.5), 2.2, mid.darkened(0.15))
		img.set_pixel(cx - 1, 14, hi)
	fill_poly(img, [Vector2(6, 7), Vector2(26, 7), Vector2(29, 13), Vector2(3, 13)], mid)
	fill_poly(img, [Vector2(6, 7), Vector2(26, 7), Vector2(27, 9), Vector2(5, 9)], hi)
	fill_poly(img, [Vector2(4, 11), Vector2(28, 11), Vector2(29, 13), Vector2(3, 13)], dk)
	fill_circle(img, Vector2(16, 6), 5.2, mid)
	fill_circle(img, Vector2(15, 5), 3.0, hi)
	for p in [Vector2(18, 8), Vector2(19, 7), Vector2(20, 6), Vector2(17, 9), Vector2(18, 9)]:
		img.set_pixel(int(p.x), int(p.y), dk)
	for x in range(11, 22):
		img.set_pixel(x, 10, accent)
	return outline(img, INK)

static func make_enemy(hi: Color, mid: Color, dk: Color, accent: Color) -> Image:
	var img := new_img(36, 26)
	var track := dk.darkened(0.4)
	fill_poly(img, [Vector2(3, 17), Vector2(34, 17), Vector2(34, 22), Vector2(31, 24), Vector2(5, 24), Vector2(2, 21)], track)
	for cx in [6, 12, 18, 24, 30]:
		fill_circle(img, Vector2(cx, 20.5), 2.4, mid.darkened(0.2))
		img.set_pixel(cx - 1, 19, hi)
	fill_poly(img, [Vector2(1, 17), Vector2(10, 9), Vector2(33, 9), Vector2(34, 17)], mid)
	fill_poly(img, [Vector2(10, 9), Vector2(33, 9), Vector2(33, 11), Vector2(8, 11)], hi)
	fill_poly(img, [Vector2(1, 17), Vector2(3, 14), Vector2(34, 14), Vector2(34, 17)], dk)
	fill_poly(img, [Vector2(14, 3), Vector2(27, 3), Vector2(30, 10), Vector2(12, 10)], mid)
	fill_poly(img, [Vector2(14, 3), Vector2(27, 3), Vector2(28, 5), Vector2(13, 5)], hi)
	fill_poly(img, [Vector2(25, 3), Vector2(28, 0), Vector2(28, 3)], dk)
	fill_poly(img, [Vector2(30, 9), Vector2(35, 5), Vector2(33, 11)], dk)
	for x in range(15, 21):
		img.set_pixel(x, 7, accent)
		img.set_pixel(x, 8, accent)
	return outline(img, INK)

static func make_barrel(angle_deg: float, dir_x: float, hi: Color, mid: Color) -> Image:
	var img := new_img(40, 40)
	var a := deg_to_rad(angle_deg)
	var d := Vector2(cos(a) * dir_x, -sin(a))
	var pivot := Vector2(20, 20)
	for i in range(0, 17):
		var p := pivot + d * i
		for oy in range(-1, 2):
			for ox in range(-1, 2):
				put(img, int(p.x) + ox, int(p.y) + oy, INK)
	for i in range(0, 16):
		var p := pivot + d * i
		put(img, int(p.x), int(p.y), mid)
		if i > 2 and i % 2 == 0:
			put(img, int(p.x), int(p.y) - 1, hi)
	var tip := pivot + d * 15
	put(img, int(tip.x), int(tip.y), hi.lightened(0.3))
	return img

# --------------------------------------------------------- glow / vignette
static func make_glow(radius: int, levels: int, tint: Color) -> Image:
	var img := new_img(radius * 2, radius * 2)
	for y in radius * 2:
		for x in radius * 2:
			var d := Vector2(x + 0.5 - radius, y + 0.5 - radius).length() / radius
			if d >= 1.0:
				continue
			var a := pow(1.0 - d, 1.8) * levels
			var q := (floorf(a) + (1.0 if a - floorf(a) > bayer(x, y) else 0.0)) / levels
			img.set_pixel(x, y, Color(tint.r, tint.g, tint.b, q))
	return img

static func make_vignette() -> Image:
	var img := new_img(W, H)
	for y in H:
		for x in W:
			var v := Vector2((x - W * 0.5) / (W * 0.5), (y - H * 0.5) / (H * 0.5))
			var a := clampf((v.length() - 0.75) * 0.9, 0.0, 0.6)
			a = floorf(a * 6.0 + (1.0 if a * 6.0 - floorf(a * 6.0) > bayer(x, y) else 0.0)) / 6.0
			img.set_pixel(x, y, Color(0.08, 0.03, 0.18, a))
	return img
