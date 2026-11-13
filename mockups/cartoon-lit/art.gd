extends Node2D
# One Art node per `kind`; each paints one depth layer. Everything is code-drawn.
# Light: low golden-hour sun on the right (SUN). Lit sides face right/up (warm),
# shadow sides face left/down (cool teal-violet). Outlines thin out with distance.

const INK := Color("2a1838")
const CREAM := Color("fff0d0")
const W := 1280.0
const H := 720.0
const SUN := Vector2(1125, 222)
const TILT := 1.3  # tank scale

static var player_x := 250.0
static var enemy_x := 1000.0
static var crater_x := 775.0
static var crater_r := 82.0
static var crater_d := 70.0
static var player_ang := 50.0
static var enemy_ang := 26.0

var kind := ""
var ld := Vector2(0.75, -0.66).normalized()
var font: Font = load("res://assets/fonts/kenvector_future.ttf")

func _draw() -> void:
	call("draw_" + kind)

# ------------------------------------------------------------ world functions
static func surface(x: float) -> float:
	var y := 505.0 + 26.0 * sin(x * 0.0055 + 1.0) + 12.0 * sin(x * 0.014 + 2.0)
	y -= 85.0 * exp(-pow((x - player_x) / 120.0, 2.0))
	y -= 30.0 * exp(-pow((x - (enemy_x + 30.0)) / 130.0, 2.0))
	if crater_x > 0.0:
		var u := (x - crater_x) / crater_r
		if absf(u) < 1.0:
			y += crater_d * pow(1.0 - u * u, 0.62)
		y -= 9.0 * exp(-pow((absf(u) - 1.08) / 0.2, 2.0))
	return y

static func slope_lit(x: float) -> float:
	var dy := (surface(x + 14.0) - surface(x - 14.0)) / 28.0
	return clampf(0.55 + dy * 1.2, 0.0, 1.0)

static func tank_base(x: float) -> Vector2:
	return Vector2(x, surface(x) + 6.0)

static func tank_rot(x: float) -> float:
	return atan2(surface(x + 34.0) - surface(x - 34.0), 68.0) * 0.45

static func pivot_world() -> Vector2:
	return tank_base(player_x) + Vector2(4, -62).rotated(tank_rot(player_x)) * TILT

static func muzzle_world() -> Vector2:
	return pivot_world() + Vector2.from_angle(-deg_to_rad(player_ang)) * 72.0 * TILT

static func boom_world() -> Vector2:
	return Vector2(crater_x + 14.0, surface(crater_x + 14.0) - 8.0)

static func shell_pos(t: float) -> Vector2:
	var a := muzzle_world()
	var b := boom_world()
	var h := (tan(deg_to_rad(player_ang)) * (b.x - a.x) + (b.y - a.y)) / 4.0
	return Vector2(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t) - h * 4.0 * t * (1.0 - t))

# ------------------------------------------------------------ helpers
func ramp(stops: Array, t: float) -> Color:
	for i in range(1, stops.size()):
		if t <= stops[i][0]:
			var a: Array = stops[i - 1]
			var b: Array = stops[i]
			return (a[1] as Color).lerp(b[1], (t - a[0]) / maxf(b[0] - a[0], 0.0001))
	return stops[stops.size() - 1][1]

func circ(c: Vector2, r: float, n := 28) -> PackedVector2Array:
	return ell(c, r, r, n)

func ell(c: Vector2, rx: float, ry: float, n := 28) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		p.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return p

func rrect_pts(r: Rect2, rad: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var cs := [r.position + Vector2(rad, rad), Vector2(r.end.x - rad, r.position.y + rad), r.end - Vector2(rad, rad), Vector2(r.position.x + rad, r.end.y - rad)]
	for i in 4:
		for a in 7:
			var ang := deg_to_rad(i * 90.0 + 180.0 + a * 15.0)
			pts.append(cs[i] + Vector2(cos(ang), sin(ang)) * rad)
	return pts

func star_pts(c: Vector2, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		p.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	return p

func gear_pts(c: Vector2, r: float, teeth: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in teeth * 4:
		var a := TAU * i / (teeth * 4.0)
		var rr := r if (i % 4 == 1 or i % 4 == 2) else r * 0.8
		p.append(c + Vector2(cos(a), sin(a)) * rr)
	return p

func shifted(pts: PackedVector2Array, off: Vector2) -> PackedVector2Array:
	var q := PackedVector2Array()
	for p in pts:
		q.append(p + off)
	return q

func chaikin(pts: PackedVector2Array, it: int) -> PackedVector2Array:
	var p := pts
	for _i in it:
		var q := PackedVector2Array()
		for i in p.size():
			var a := p[i]
			var b := p[(i + 1) % p.size()]
			q.append(a.lerp(b, 0.25))
			q.append(a.lerp(b, 0.75))
		p = q
	return p

func fill(pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3 or col.a <= 0.0:
		return
	if Geometry2D.triangulate_polygon(pts).is_empty():
		return
	draw_colored_polygon(pts, col)

func fill_many(polys: Array, col: Color) -> void:
	for pc in polys:
		fill(pc, col)

func outline(pts: PackedVector2Array, col: Color, w: float) -> void:
	if w <= 0.0:
		return
	var c := pts.duplicate()
	c.append(pts[0])
	draw_polyline(c, col, w, true)

# Cel-shaded polygon: base fill, shadow crescent on the side away from the light,
# rim crescent on the lit side, then outline.
func shaded(pts: PackedVector2Array, base: Color, shade: Color, rim: Color, ow := 5.0, d := -1.0, ink := INK) -> void:
	var bb := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		bb = bb.expand(p)
	if d < 0.0:
		d = clampf(minf(bb.size.x, bb.size.y) * 0.16, 3.0, 11.0)
	fill(pts, base)
	fill_many(Geometry2D.clip_polygons(pts, shifted(pts, ld * d)), shade)
	fill_many(Geometry2D.clip_polygons(pts, shifted(pts, -ld * d * 0.55)), rim)
	outline(pts, ink, ow)

func clip_to(pts: PackedVector2Array, region: PackedVector2Array) -> Array:
	return Geometry2D.intersect_polygons(pts, region)

func rect_pts(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])

func grad_poly(poly: PackedVector2Array, y0: float, y1: float, c0: Color, c1: Color, steps: int) -> void:
	for i in steps:
		var ya := lerpf(y0, y1, float(i) / steps)
		var yb := lerpf(y0, y1, float(i + 1) / steps) + 1.0
		if i == steps - 1:
			yb = H + 60.0
		if i == 0:
			ya = -60.0
		fill_many(clip_to(poly, rect_pts(Rect2(-60, ya, W + 120, yb - ya))), c0.lerp(c1, (i + 0.5) / steps))

func line_o(pts: PackedVector2Array, col: Color, w: float, ow := 2.5) -> void:
	draw_polyline(pts, INK, w + ow * 2.0, true)
	draw_polyline(pts, col, w, true)

func txt(s: String, pos: Vector2, size: int, col := CREAM, ow := 8, ocol := INK) -> void:
	var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var p := pos + Vector2(-sz.x / 2.0, (font.get_ascent(size) - font.get_descent(size)) / 2.0)
	if ow > 0:
		draw_string_outline(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ow, ocol)
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

# ------------------------------------------------------------ SKY
func draw_sky() -> void:
	var stops := [[0.0, Color("241f5e")], [0.25, Color("5a3590")], [0.45, Color("c2508f")], [0.62, Color("ff7f6e")], [0.8, Color("ffb56e")], [1.0, Color("ffdc98")]]
	var steps := 90
	for i in steps:
		var t := (i + 0.5) / steps
		draw_rect(Rect2(0, i * 560.0 / steps, W, 560.0 / steps + 1.0), ramp(stops, t))
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 34:
		var p := Vector2(rng.randf() * W, rng.randf() * 190.0)
		draw_circle(p, rng.randf_range(0.8, 1.8), Color(1, 0.95, 0.85, rng.randf_range(0.25, 0.8) * (1.0 - p.y / 220.0)))
	for k in [[560.0, 0.07], [420.0, 0.09], [300.0, 0.12], [200.0, 0.16], [120.0, 0.22]]:
		draw_circle(SUN, k[0], Color(1.0, 0.72, 0.42, k[1]))
	draw_circle(SUN, 62, Color(1.0, 0.86, 0.55, 0.9))
	draw_circle(SUN, 50, Color("fff4c8"))
	draw_circle(SUN + Vector2(-8, -8), 34, Color("ffffee"))
	draw_clouds()
	draw_balloon(Vector2(420, 215), 0.55, 0.0)
	draw_balloon(Vector2(610, 150), 0.38, 0.0)
	for b in [[Vector2(120, 150), 1.0], [Vector2(152, 168), 0.8], [Vector2(96, 178), 0.7], [Vector2(178, 140), 0.65], [Vector2(135, 198), 0.55]]:
		draw_bird(b[0], b[1])

func draw_clouds() -> void:
	var base := Color("ffb0a0")
	var shade := Color("a8508f")
	var rim := Color("fff0c4")
	# long streaks near the horizon, then puffier banks higher up
	for c in [[Vector2(300, 330), 380.0, 20.0], [Vector2(760, 352), 300.0, 16.0], [Vector2(110, 392), 260.0, 14.0], [Vector2(1160, 384), 240.0, 14.0]]:
		cloud(c[0], c[1], c[2], base, shade, rim, 0.0, false)
	for c in [[Vector2(230, 80), 250.0, 46.0], [Vector2(780, 118), 210.0, 38.0], [Vector2(1120, 70), 230.0, 40.0], [Vector2(520, 268), 190.0, 30.0], [Vector2(965, 190), 160.0, 26.0]]:
		cloud(c[0], c[1], c[2], Color("ffa4a8"), Color("8c4690"), rim, 0.0, true)

func cloud(p: Vector2, w: float, h: float, base: Color, shade: Color, rim: Color, _a: float, puffy: bool) -> void:
	var poly := rrect_pts(Rect2(p.x - w / 2.0, p.y - h / 2.0, w, h), h / 2.0)
	if puffy:
		for q in [[-0.22, -0.55, 0.42], [0.08, -0.8, 0.55], [0.3, -0.4, 0.38]]:
			var bump := circ(p + Vector2(w * q[0], h * q[1]), h * q[2] * 1.5, 20)
			var m := Geometry2D.merge_polygons(poly, bump)
			if m.size() > 0:
				poly = m[0]
	var old := ld
	ld = Vector2(0.9, -0.35).normalized()
	shaded(poly, base, shade, rim, 0.0, 12.0)
	ld = old
	var lower := clip_to(poly, rect_pts(Rect2(p.x - w, p.y + h * 0.12, w * 2.0, h * 2.0)))
	fill_many(lower, Color(shade, 0.8))

func draw_bird(p: Vector2, s: float) -> void:
	var pts := PackedVector2Array([p + Vector2(-14, -2) * s, p + Vector2(-7, -9) * s, p + Vector2(0, 0), p + Vector2(7, -9) * s, p + Vector2(14, -2) * s])
	draw_polyline(pts, Color("3a1f4f"), 3.0 * s, true)

func draw_balloon(p: Vector2, s: float, _hz: float) -> void:
	var env := ell(p, 34 * s, 42 * s, 32)
	var cols := [Color("ff5d73"), Color("fff0d0")]
	fill(env, Color("fff0d0"))
	for i in 5:
		if i % 2 == 0:
			var band := PackedVector2Array([Vector2(p.x - 34 * s + i * 13.6 * s, p.y - 60 * s), Vector2(p.x - 34 * s + (i + 1) * 13.6 * s, p.y - 60 * s), Vector2(p.x - 34 * s + (i + 1) * 13.6 * s, p.y + 60 * s), Vector2(p.x - 34 * s + i * 13.6 * s, p.y + 60 * s)])
			fill_many(clip_to(env, band), cols[0])
	var old := ld
	ld = Vector2(0.75, -0.5).normalized()
	fill_many(Geometry2D.clip_polygons(env, shifted(env, ld * 12.0 * s)), Color(0.35, 0.1, 0.4, 0.45))
	ld = old
	outline(env, Color("5a2f66"), 2.0)
	var bk := Vector2(p.x, p.y + 62 * s)
	draw_line(p + Vector2(-14, 36) * s, bk + Vector2(-8, 0) * s, Color("5a2f66"), 1.5)
	draw_line(p + Vector2(14, 36) * s, bk + Vector2(8, 0) * s, Color("5a2f66"), 1.5)
	fill(rrect_pts(Rect2(bk.x - 9 * s, bk.y, 18 * s, 12 * s), 2.0), Color("8a4a3a"))

# ------------------------------------------------------------ DISTANT LAYERS
func mesa_layer(prof: Array, c_top: Color, c_haze: Color, shade: Color, rim: Color, y0: float, y1: float, stripe: Color) -> void:
	var raw := PackedVector2Array()
	for p in prof:
		raw.append(Vector2(p[0], p[1]))
	raw.append(Vector2(W + 40, 760))
	raw.append(Vector2(-40, 760))
	var pts := chaikin(raw, 2)
	grad_poly(pts, y0, y1, c_top, c_haze, 14)
	var y := y0
	var k := 0
	while y < y1:
		if k % 2 == 0:
			fill_many(clip_to(pts, rect_pts(Rect2(-50, y, W + 100, 7.0))), stripe)
		y += 17.0
		k += 1
	fill_many(Geometry2D.clip_polygons(pts, shifted(pts, Vector2(16, 5))), shade)
	fill_many(Geometry2D.clip_polygons(pts, shifted(pts, Vector2(-9, 5))), rim)

func draw_far() -> void:
	var prof := [[-20, 440], [40, 410], [58, 340], [150, 334], [172, 400], [262, 432], [330, 418], [352, 352], [384, 344], [470, 340], [492, 412], [570, 442], [700, 432], [730, 384], [748, 366], [850, 360], [872, 384], [892, 432], [960, 444], [1010, 408], [1034, 346], [1126, 340], [1152, 350], [1172, 412], [1300, 432]]
	mesa_layer(prof, Color("c0689a"), Color("ffb78a"), Color(0.5, 0.2, 0.55, 0.35), Color(1.0, 0.85, 0.55, 0.55), 330.0, 470.0, Color(1, 0.8, 0.7, 0.08))
	# distant natural arch
	var c := Vector2(640, 438)
	var arch := PackedVector2Array()
	for i in 17:
		arch.append(c + Vector2(cos(PI + i * PI / 16.0), sin(PI + i * PI / 16.0)) * 70.0)
	for i in 17:
		var a := TAU - i * PI / 16.0
		arch.append(c + Vector2(cos(a), sin(a)) * 40.0 * Vector2(1.0, 1.0))
	var arch_col := Color("b4608f")
	var old := ld
	fill(arch, arch_col)
	fill_many(Geometry2D.clip_polygons(arch, shifted(arch, Vector2(10, 4))), Color(0.5, 0.2, 0.55, 0.4))
	fill_many(Geometry2D.clip_polygons(arch, shifted(arch, Vector2(-6, 6))), Color(1, 0.85, 0.55, 0.55))
	ld = old

func draw_mid() -> void:
	var prof := [[-20, 474], [20, 444], [40, 404], [120, 398], [150, 442], [230, 474], [300, 460], [322, 418], [338, 384], [424, 378], [444, 424], [520, 470], [600, 484], [660, 470], [690, 424], [704, 402], [790, 400], [820, 432], [850, 474], [940, 482], [1012, 456], [1042, 424], [1064, 404], [1160, 400], [1190, 444], [1230, 474], [1300, 474]]
	mesa_layer(prof, Color("7e4390"), Color("e57a84"), Color(0.25, 0.1, 0.4, 0.45), Color(1.0, 0.7, 0.4, 0.6), 380.0, 500.0, Color(0.2, 0.05, 0.3, 0.12))
	# tiny ruined tower on a mesa with a warm lit window
	var tw := Vector2(352, 378)
	var body := rrect_pts(Rect2(tw.x - 9, tw.y - 44, 18, 44), 2.0)
	shaded(body, Color("6a3a84"), Color("3c1d5e"), Color("ffb878"), 1.5, 4.0, Color("3c1d5e"))
	fill(PackedVector2Array([tw + Vector2(-12, -44), tw + Vector2(0, -60), tw + Vector2(12, -44)]), Color("5a2f78"))
	fill(rect_pts(Rect2(tw.x - 2, tw.y - 30, 4, 8)), Color("ffd070"))
	# windows of a small village glowing in the haze
	for v in [[732, 402], [746, 402], [1090, 402], [1104, 402], [1118, 402]]:
		fill(rect_pts(Rect2(v[0], v[1] - 10, 5, 7)), Color("ffd070"))

func draw_hills() -> void:
	var pts := PackedVector2Array()
	for x in range(-20, int(W) + 30, 10):
		pts.append(Vector2(x, hill_y(x)))
	var poly := pts.duplicate()
	poly.append(Vector2(W + 30, 760))
	poly.append(Vector2(-20, 760))
	grad_poly(poly, 430.0, 640.0, Color("3a7a78"), Color("a26b7d"), 12)
	fill_many(Geometry2D.clip_polygons(poly, shifted(poly, Vector2(18, 7))), Color(0.1, 0.1, 0.35, 0.35))
	fill_many(Geometry2D.clip_polygons(poly, shifted(poly, Vector2(-9, 6))), Color(1.0, 0.8, 0.45, 0.5))
	draw_polyline(pts, Color("1d3f55"), 3.0, true)
	for c in [[90, 0.9], [395, 0.7], [575, 1.0], [700, 0.8], [1190, 0.85]]:
		cactus(Vector2(c[0], hill_y(c[0]) + 6.0), c[1])
	for b in [[170, 1.0], [470, 0.9], [770, 1.1], [1090, 0.9], [1250, 0.8]]:
		bush(Vector2(b[0], hill_y(b[0]) + 5.0), b[1])

static func hill_y(x: float) -> float:
	return 478.0 + 22.0 * sin(x * 0.006 + 3.0) + 9.0 * sin(x * 0.017 + 1.0)

func cactus(base: Vector2, s: float) -> void:
	var col := Color("2f8f74")
	var parts := [rrect_pts(Rect2(base.x - 9 * s, base.y - 74 * s, 18 * s, 78 * s), 9 * s), rrect_pts(Rect2(base.x - 30 * s, base.y - 54 * s, 12 * s, 30 * s), 6 * s), rrect_pts(Rect2(base.x - 30 * s, base.y - 34 * s, 28 * s, 11 * s), 5 * s), rrect_pts(Rect2(base.x + 18 * s, base.y - 46 * s, 12 * s, 26 * s), 6 * s), rrect_pts(Rect2(base.x + 2 * s, base.y - 28 * s, 28 * s, 11 * s), 5 * s)]
	for p in parts:
		shaded(p, col, Color("17504f"), Color("e8e87a"), 2.5, 5.0, Color("14303f"))

func bush(base: Vector2, s: float) -> void:
	var poly := circ(base + Vector2(-14, -8) * s, 16 * s, 16)
	for q in [[10, -14, 20], [32, -6, 15]]:
		var m := Geometry2D.merge_polygons(poly, circ(base + Vector2(q[0], q[1]) * s, q[2] * s, 16))
		if m.size() > 0:
			poly = m[0]
	shaded(poly, Color("3f9a6a"), Color("1c5a56"), Color("f2e880"), 2.5, 6.0, Color("14303f"))

# ------------------------------------------------------------ TERRAIN
func ground_pts(step := 4) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for x in range(-12, int(W) + 16, step):
		pts.append(Vector2(x, surface(x)))
	return pts

func draw_terrain() -> void:
	var gp := ground_pts()
	var cool_top := [Color("c0605a"), Color("a04870"), Color("703a7a"), Color("402260"), Color("22123e")]
	var warm_top := [Color("ffb040"), Color("ee8040"), Color("c0504a"), Color("6a2e66"), Color("26143f")]
	var offs := [0.0, 40.0, 110.0, 200.0, 320.0, 700.0]
	for i in gp.size() - 1:
		var a := gp[i]
		var b := gp[i + 1]
		var lit := slope_lit((a.x + b.x) / 2.0)
		var xs := [a.x, b.x]
		for k in 5:
			var col: Color = (cool_top[k] as Color).lerp(warm_top[k], 0.5 + (lit - 0.5) * [1.0, 0.8, 0.5, 0.25, 0.1][k])
			var q := PackedVector2Array([Vector2(a.x, minf(a.y + offs[k], H + 20)), Vector2(b.x + 0.8, minf(b.y + offs[k], H + 20)), Vector2(b.x + 0.8, minf(b.y + offs[k + 1], H + 30)), Vector2(a.x, minf(a.y + offs[k + 1], H + 30))])
			draw_colored_polygon(q, col)
	draw_strata()
	draw_buried()
	draw_crater_scorch()
	draw_grass()

func draw_strata() -> void:
	for k in [[48.0, 0.55], [104.0, 0.6], [178.0, 0.7], [270.0, 0.8]]:
		var pts := PackedVector2Array()
		var pts2 := PackedVector2Array()
		for x in range(-12, int(W) + 16, 8):
			var yy: float = surface(x) * k[1] + 505.0 * (1.0 - k[1]) + k[0] + 7.0 * sin(x * 0.02 + k[0])
			if absf(x - crater_x) < crater_r + 10.0:
				yy = maxf(yy, surface(x) + 40.0 + k[0] * 0.3)
			pts.append(Vector2(x, yy))
			pts2.append(Vector2(x, yy + 4.0))
		draw_polyline(pts, Color(0.12, 0.04, 0.22, 0.3), 3.5, true)
		draw_polyline(pts2, Color(1.0, 0.7, 0.4, 0.14), 3.0, true)

func rock(c: Vector2, r: float, seed_i: int, base: Color, shade: Color, rim: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_i
	var pts := PackedVector2Array()
	for i in 9:
		var a := TAU * i / 9.0
		pts.append(c + Vector2(cos(a) * r * rng.randf_range(0.8, 1.15), sin(a) * r * rng.randf_range(0.7, 1.0)))
	shaded(chaikin(pts, 1), base, shade, rim, 3.0, r * 0.22)

func draw_buried() -> void:
	ld = Vector2(0.7, -0.7).normalized()
	# roots hanging from the grass
	for rt in [[40.0, 80.0], [188.0, 100.0], [340.0, 70.0], [610.0, 90.0], [1090.0, 100.0], [1230.0, 80.0]]:
		var pts := PackedVector2Array()
		for i in 8:
			pts.append(Vector2(rt[0] + sin(i * 0.9 + rt[0]) * 9.0 + i * 3.0, surface(rt[0]) + 18.0 + i * rt[1] / 8.0))
		draw_polyline(pts, INK, 9.0, true)
		draw_polyline(pts, Color("9a5a44"), 5.0, true)
		draw_polyline(shifted(pts, Vector2(1.5, -0.5)), Color("ffb070"), 1.8, true)
	var rc := [Color("9a7aa8"), Color("4f3470"), Color("ffc890")]
	for r in [[Vector2(76, 596), 24.0], [Vector2(318, 648), 30.0], [Vector2(520, 626), 18.0], [Vector2(714, 612), 14.0], [Vector2(1010, 640), 30.0], [Vector2(1190, 604), 20.0], [Vector2(255, 565), 12.0], [Vector2(950, 590), 12.0], [Vector2(430, 590), 10.0]]:
		rock(r[0], r[1], int(r[0].x), rc[0], rc[1], rc[2])
	# rusty cog, a ribcage fossil, glowing crystals: the world has a history
	var cog := gear_pts(Vector2(150, 664), 40.0, 9)
	shaded(cog, Color("d0763c"), Color("7a3a3c"), Color("ffcf8a"), 3.5, 7.0)
	shaded(circ(Vector2(150, 664), 13.0, 16), Color("4a2a56"), Color("2a1838"), Color("8a6aa8"), 3.0, 3.0)
	ribs(Vector2(868, 640))
	crystals(Vector2(612, 672))

func ribs(c: Vector2) -> void:
	var spine := PackedVector2Array([c + Vector2(-64, -6), c + Vector2(-20, -14), c + Vector2(24, -12), c + Vector2(66, -4)])
	line_o(spine, Color("f0dcc0"), 8.0)
	for i in 4:
		var x := c.x - 46 + i * 31
		var pts := PackedVector2Array()
		for k in 8:
			var t := k / 7.0
			pts.append(Vector2(x + 16 * sin(t * 1.8) * (1.0 - t * 0.2), c.y - 10 + t * 56 + 4 * t))
		line_o(pts, Color("f0dcc0"), 7.0, 2.2)
		draw_polyline(shifted(pts, Vector2(2, 0)), Color("fff8e4"), 2.0, true)

func crystals(c: Vector2) -> void:
	for g in [[130.0, 0.14], [90.0, 0.2], [60.0, 0.3]]:
		draw_circle(c + Vector2(0, -22), g[0], Color(0.3, 1.0, 0.9, g[1] * 0.45))
	for k in [[-26.0, 40.0, 14.0, -0.2], [0.0, 66.0, 18.0, 0.0], [24.0, 36.0, 12.0, 0.25]]:
		var base := c + Vector2(k[0], 0)
		var tip := base + Vector2(0, -k[1]).rotated(k[3])
		var pts := PackedVector2Array([base + Vector2(-k[2], 0), base + Vector2(-k[2] * 0.7, -k[1] * 0.55).rotated(k[3]), tip, base + Vector2(k[2] * 0.7, -k[1] * 0.55).rotated(k[3]), base + Vector2(k[2], 0)])
		shaded(pts, Color("52f2dc"), Color("1a8f9a"), Color("e8fffa"), 3.0, 5.0)

func draw_crater_scorch() -> void:
	if crater_x < 0.0:
		return
	var pts := PackedVector2Array()
	var glow := PackedVector2Array()
	for x in range(int(crater_x - crater_r), int(crater_x + crater_r) + 1, 4):
		pts.append(Vector2(x, surface(x) + 11.0))
		glow.append(Vector2(x, surface(x) + 3.0))
	draw_polyline(pts, Color("2e1634"), 30.0, true)
	draw_polyline(pts, Color("5a2638"), 20.0, true)
	draw_polyline(glow, Color(1.0, 0.45, 0.2, 0.55), 7.0, true)
	var bottom := Vector2(crater_x, surface(crater_x))
	draw_circle(bottom + Vector2(0, -4), 46, Color(1.0, 0.5, 0.2, 0.2))
	draw_circle(bottom + Vector2(0, -4), 26, Color(1.0, 0.7, 0.3, 0.25))
	# cracks fanning out of the crater
	for cr in [[-0.7, 52.0], [0.9, 44.0]]:
		var p0 := Vector2(crater_x + cr[0] * crater_r, surface(crater_x + cr[0] * crater_r) + 18.0)
		draw_polyline(PackedVector2Array([p0, p0 + Vector2(cr[0] * 12.0, cr[1] * 0.5), p0 + Vector2(cr[0] * 4.0, cr[1])]), Color("2e1634"), 3.0, true)

func in_crater(x: float, pad := 0.0) -> bool:
	return crater_x > 0.0 and absf(x - crater_x) < crater_r + pad

func draw_grass() -> void:
	var run_ink := PackedVector2Array()
	var run_dark := PackedVector2Array()
	var cols_lit := PackedColorArray()
	var cols_dark := PackedColorArray()
	var runs: Array = []
	var cur: Array = []
	for x in range(-12, int(W) + 16, 4):
		if in_crater(x, -2.0):
			if cur.size() > 1:
				runs.append(cur)
			cur = []
			continue
		cur.append(x)
	if cur.size() > 1:
		runs.append(cur)
	for r in runs:
		var base := PackedVector2Array()
		var lipc := PackedColorArray()
		var hic := PackedColorArray()
		for x in r:
			var lit := slope_lit(x)
			base.append(Vector2(x, surface(x) + 11.0))
			lipc.append(Color("2c8a72").lerp(Color("bfe04a"), lit))
			hic.append(Color("5ec08a").lerp(Color("f8ffa8"), lit))
		draw_polyline(base, INK, 31.0, true)
		draw_polyline(base, Color("1d6a62"), 23.0, true)
		draw_polyline_colors(shifted(base, Vector2(0, -3)), lipc, 16.0, true)
		draw_polyline_colors(shifted(base, Vector2(0, -8)), hic, 4.5, true)
		draw_polyline(shifted(base, Vector2(0, 12)), Color(0.15, 0.05, 0.25, 0.35), 8.0, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var x := -6.0
	while x < W + 6.0:
		x += rng.randf_range(7.0, 13.0)
		if in_crater(x, 4.0):
			continue
		var lit := slope_lit(x)
		var hgt := rng.randf_range(10.0, 24.0)
		var lean := 5.0 + rng.randf_range(0.0, 6.0)
		var bp := Vector2(x, surface(x) + 1.0)
		var blade := PackedVector2Array([bp + Vector2(-4, 0), bp + Vector2(lean * 0.3, -hgt * 0.6), bp + Vector2(lean, -hgt), bp + Vector2(4 + lean * 0.3, -hgt * 0.55), bp + Vector2(4, 0)])
		fill(blade, Color("2f9a6c").lerp(Color("c8e850"), lit))
		outline(blade, Color("1c4a4a"), 2.2)
	# flowers: tiny warm dots for colour accents
	for f in [[60, 0], [335, 1], [560, 0], [700, 1], [1100, 0], [1215, 1]]:
		var fp := Vector2(f[0], surface(f[0]) - 6.0)
		draw_line(fp + Vector2(0, 8), fp, Color("1c4a4a"), 2.0)
		fill(circ(fp, 5.0, 10), Color("ffe36b") if f[1] == 0 else Color("ff7a8a"))
		outline(circ(fp, 5.0, 10), INK, 1.5)

# ------------------------------------------------------------ TANKS
func draw_tanks() -> void:
	for t in [[player_x, 1.0], [enemy_x, -1.0]]:
		var b := tank_base(t[0])
		var r := tank_rot(t[0])
		draw_set_transform(b + Vector2(-30.0 * (-t[1]) * -1.0, 3.0), r, Vector2(1, 0.2))
		draw_circle(Vector2.ZERO, 82.0, Color(0.1, 0.03, 0.3, 0.38))
		draw_set_transform(b + Vector2(0, 2), r, Vector2(1, 0.16))
		draw_circle(Vector2.ZERO, 66.0, Color(0.08, 0.02, 0.2, 0.45))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	tank_player(tank_base(player_x), tank_rot(player_x), player_ang)
	tank_enemy(tank_base(enemy_x), tank_rot(enemy_x), enemy_ang)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func barrel(piv: Vector2, d: Vector2, length: float, w0: float, w1: float, base: Color, shade: Color, rim: Color) -> void:
	var n := d.orthogonal()
	var body := PackedVector2Array([piv + n * w0 / 2.0, piv + d * length + n * w1 / 2.0, piv + d * length - n * w1 / 2.0, piv - n * w0 / 2.0])
	shaded(body, base, shade, rim, 4.5, 4.0)
	var mw := w1 + 8.0
	var mz := PackedVector2Array([piv + d * (length - 12.0) + n * mw / 2.0, piv + d * (length + 6.0) + n * mw / 2.0, piv + d * (length + 6.0) - n * mw / 2.0, piv + d * (length - 12.0) - n * mw / 2.0])
	shaded(mz, base.darkened(0.1), shade, rim, 4.5, 3.0)
	var cw := w0 + 8.0
	var cl := PackedVector2Array([piv + d * 6.0 + n * cw / 2.0, piv + d * 22.0 + n * cw / 2.0, piv + d * 22.0 - n * cw / 2.0, piv + d * 6.0 - n * cw / 2.0])
	shaded(cl, base.lightened(0.05), shade, rim, 4.5, 3.0)

func tank_player(base: Vector2, rot: float, ang: float) -> void:
	ld = Vector2(0.75, -0.66).normalized()
	draw_set_transform(base, rot, Vector2(TILT, TILT))
	var d := Vector2.from_angle(-deg_to_rad(ang))
	var piv := Vector2(4, -62)
	# antenna + pennant (streams with the wind, to the right)
	var ant := PackedVector2Array([Vector2(-30, -76), Vector2(-34, -108), Vector2(-40, -134)])
	line_o(ant, Color("c8c0e8"), 2.5, 2.0)
	var flag := PackedVector2Array([Vector2(-40, -134), Vector2(-24, -140), Vector2(-4, -135), Vector2(14, -138), Vector2(-4, -127), Vector2(-24, -125), Vector2(-40, -120)])
	shaded(flag, Color("ff9a2e"), Color("c2501e"), Color("ffe08a"), 3.0, 3.5)
	fill(star_pts(Vector2(-22, -131), 5.5), CREAM)
	fill(circ(Vector2(-40, -136), 4.0, 10), Color("ffd24a"))
	outline(circ(Vector2(-40, -136), 4.0, 10), INK, 2.0)
	barrel(piv, d, 70.0, 17.0, 13.0, Color("8b9ad0"), Color("424f8c"), Color("e2eaff"))
	# hull
	var hull := rrect_pts(Rect2(-60, -58, 120, 38), 17.0)
	shaded(hull, Color("30d3c1"), Color("107a90"), Color("c4fff2"), 5.0, 9.0)
	var band := rrect_pts(Rect2(-54, -42, 108, 10), 5.0)
	shaded(band, Color("ffc23a"), Color("d97d22"), Color("fff0a0"), 3.0, 3.0)
	for sx in [-38, -14, 10, 34]:
		fill(star_pts(Vector2(sx, -37), 4.2), Color("fff3c4") if sx == 10 else Color("ffe08a"))
	for rx in [-48, 48]:
		fill(circ(Vector2(rx, -50), 2.4, 8), Color("107a90"))
	# scratch and dent: the tank has been through things
	draw_line(Vector2(-36, -52), Vector2(-24, -47), Color(1, 1, 1, 0.55), 2.0, true)
	draw_line(Vector2(-33, -56), Vector2(-26, -53), Color(1, 1, 1, 0.4), 1.5, true)
	fill(ell(Vector2(40, -50), 6.0, 3.5, 10), Color(0.05, 0.3, 0.4, 0.5))
	# headlight
	draw_circle(Vector2(56, -34), 15.0, Color(1.0, 0.9, 0.4, 0.12))
	shaded(circ(Vector2(56, -34), 6.5, 14), Color("fff0a0"), Color("ffc23a"), Color.WHITE, 3.0, 2.0)
	# tracks + wheels
	var trk := rrect_pts(Rect2(-66, -30, 132, 32), 16.0)
	shaded(trk, Color("52477f"), Color("2b2358"), Color("9a8ccf"), 5.0, 7.0)
	for wx in [-45, -15, 15, 45]:
		shaded(circ(Vector2(wx, -14), 12.5, 20), Color("8878b8"), Color("453a78"), Color("d6ccf8"), 3.5, 4.0)
		shaded(circ(Vector2(wx, -14), 4.5, 10), Color("ffc23a"), Color("c2701c"), Color("fff0a0"), 2.0, 1.5)
	for mx in [[-58, -2], [-30, 1], [8, 0], [52, -3]]:
		fill(ell(Vector2(mx[0], mx[1]), 7.0, 3.5, 10), Color(0.35, 0.2, 0.28, 0.85))
	# turret dome
	var dome := PackedVector2Array()
	for a in range(180, 361, 10):
		dome.append(Vector2(cos(deg_to_rad(a)) * 37.0, -56.0 + sin(deg_to_rad(a)) * 33.0))
	shaded(dome, Color("4ee8d6"), Color("1d96a6"), Color("e4fffa"), 5.0, 9.0)
	var hatch := rrect_pts(Rect2(-20, -90, 22, 7), 3.0)
	shaded(hatch, Color("ffc23a"), Color("c2701c"), Color("fff0a0"), 2.5, 2.0)
	# big goggle eye: attitude comes from the heavy lid and where it looks
	shaded(circ(Vector2(13, -68), 18.0, 24), Color("ff9d2e"), Color("b84a1c"), Color("ffe08a"), 4.0, 4.0)
	var eye := circ(Vector2(13, -68), 13.0, 24)
	fill(eye, Color("fffaf0"))
	fill_many(Geometry2D.clip_polygons(eye, shifted(eye, ld * 4.0)), Color("c8c0e8"))
	var pup := Vector2(13, -68) + d * 4.5
	fill(circ(pup, 7.5, 16), Color("1c1038"))
	fill(circ(pup + Vector2(2.5, -3), 2.6, 8), Color.WHITE)
	var lid := PackedVector2Array([Vector2(-8, -92), Vector2(40, -92), Vector2(40, -66), Vector2(6, -76), Vector2(-8, -80)])
	for pc in clip_to(eye, lid):
		fill(pc, Color("4ee8d6"))
		outline(pc, INK, 2.8)
	outline(eye, INK, 3.0)
	# exhaust puff pipe at the rear
	shaded(rrect_pts(Rect2(-68, -52, 12, 22), 4.0), Color("6a5ea0"), Color("2b2358"), Color("a89ce0"), 3.0, 3.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func tank_enemy(base: Vector2, rot: float, ang: float) -> void:
	ld = Vector2(-0.75, -0.66).normalized()
	draw_set_transform(base, rot, Vector2(-TILT, TILT))
	var d := Vector2.from_angle(-deg_to_rad(ang))
	var piv := Vector2(8, -86)
	var crim := Color("d92f52")
	var crim_d := Color("7e1a4a")
	var crim_r := Color("ff9a8a")
	# rear exhaust stacks
	for sx in [-56, -42]:
		shaded(rrect_pts(Rect2(sx - 5, -104, 10, 40), 3.0), Color("4a3a68"), Color("241a44"), Color("9a80c0"), 3.5, 3.0)
		fill(ell(Vector2(sx, -104), 5.0, 2.5, 10), Color("0e0820"))
	# barrel (heavy, flared)
	barrel(piv, d, 74.0, 24.0, 19.0, Color("6a5a8e"), Color("2a2050"), Color("b8a4e8"))
	# hull wedge
	var hull := PackedVector2Array([Vector2(-76, -28), Vector2(-72, -62), Vector2(-42, -74), Vector2(34, -74), Vector2(82, -42), Vector2(78, -24)])
	shaded(chaikin(hull, 1), crim, crim_d, crim_r, 5.0, 10.0)
	var glacis := PackedVector2Array([Vector2(40, -72), Vector2(80, -42), Vector2(76, -26), Vector2(50, -26)])
	shaded(glacis, Color("a42248"), Color("5e153e"), crim_r, 3.5, 5.0)
	# shark grille teeth
	for i in 5:
		var tx := 46.0 + i * 7.0
		var tooth := PackedVector2Array([Vector2(tx, -46 + i * 3.0), Vector2(tx + 7.0, -46 + i * 3.0), Vector2(tx + 3.5, -34 + i * 3.0)])
		fill(tooth, CREAM)
		outline(tooth, INK, 2.0)
	# claw slashes decal
	for i in 3:
		var sl := PackedVector2Array([Vector2(-48 + i * 14, -64), Vector2(-40 + i * 14, -64), Vector2(-52 + i * 14, -34), Vector2(-60 + i * 14, -34)])
		fill(sl, Color("ffcf3a"))
		outline(sl, INK, 2.2)
	# battle damage: scorch, crack, dent
	fill(ell(Vector2(60, -52), 12.0, 8.0, 12), Color(0.1, 0.02, 0.15, 0.55))
	draw_polyline(PackedVector2Array([Vector2(20, -70), Vector2(28, -60), Vector2(22, -52), Vector2(30, -44)]), INK, 2.5, true)
	# spikes along the back
	for sx in [-64, -50, -36]:
		var sp := PackedVector2Array([Vector2(sx - 7, -70), Vector2(sx + 2, -96 + absi(sx + 50) * 0.3), Vector2(sx + 8, -72)])
		shaded(sp, Color("f0dcc0"), Color("a88a7a"), Color.WHITE, 3.0, 3.0)
	# tracks + cogs
	var trk := rrect_pts(Rect2(-84, -32, 168, 34), 10.0)
	shaded(trk, Color("3e3060"), Color("1e1440"), Color("8670b8"), 5.0, 7.0)
	for cx in [-56, 0, 56]:
		shaded(gear_pts(Vector2(cx, -15), 15.5, 9), Color("7a68a8"), Color("3a2e68"), Color("c8baf0"), 3.0, 4.0)
		shaded(circ(Vector2(cx, -15), 4.5, 10), Color("ff7a3a"), Color("b0381c"), Color("ffcf8a"), 2.0, 1.5)
	for mx in [[-70, -3], [-20, 0], [30, -2], [70, -4]]:
		fill(ell(Vector2(mx[0], mx[1]), 8.0, 3.5, 10), Color(0.3, 0.16, 0.26, 0.85))
	# turret: boxy, brooding
	var tur := PackedVector2Array([Vector2(-36, -72), Vector2(-28, -106), Vector2(20, -110), Vector2(42, -90), Vector2(38, -72)])
	shaded(chaikin(tur, 1), Color("b02450"), Color("63153f"), crim_r, 5.0, 9.0)
	# glowing slit eye and heavy brow
	draw_circle(Vector2(24, -90), 22.0, Color(1.0, 0.8, 0.2, 0.1))
	draw_circle(Vector2(24, -88), 13.0, Color(1.0, 0.8, 0.2, 0.16))
	var eye := PackedVector2Array([Vector2(4, -92), Vector2(34, -85), Vector2(31, -77), Vector2(8, -83)])
	fill(eye, Color("ffe23a"))
	fill(circ(Vector2(28, -83), 3.2, 8), Color("d11a2a"))
	outline(eye, INK, 2.5)
	var brow := PackedVector2Array([Vector2(-2, -100), Vector2(42, -91), Vector2(42, -84), Vector2(34, -86), Vector2(-2, -94)])
	fill(brow, INK)
	# torn black war flag
	var ant := PackedVector2Array([Vector2(-22, -104), Vector2(-26, -126), Vector2(-30, -150)])
	line_o(ant, Color("8670b8"), 2.5, 2.0)
	var flag := PackedVector2Array([Vector2(-30, -150), Vector2(-10, -156), Vector2(8, -152), Vector2(2, -146), Vector2(12, -140), Vector2(-8, -142), Vector2(-30, -136)])
	shaded(flag, Color("2a1838"), Color("160a24"), Color("8a60b8"), 2.5, 3.0)
	fill(circ(Vector2(-14, -147), 3.5, 8), Color("ffe23a"))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

# ------------------------------------------------------------ SHELL + FX GLOW
func draw_shell() -> void:
	var p := shell_pos(0.4)
	for g in [[44.0, 0.12], [30.0, 0.2], [20.0, 0.3]]:
		draw_circle(p, g[0], Color(1.0, 0.8, 0.3, g[1]))
	var old := ld
	ld = Vector2(0.75, -0.66).normalized()
	shaded(circ(p, 11.0, 20), Color("4a3a78"), Color("1c1038"), Color("ffcf6a"), 3.5, 3.5)
	fill(circ(p + Vector2(4, -4), 2.6, 8), Color("fff6c0"))
	ld = old

func draw_flash() -> void:
	if crater_x < 0.0:
		return
	var e := boom_world()
	for g in [[110.0, 0.12], [70.0, 0.2], [40.0, 0.35]]:
		draw_circle(e + Vector2(0, -26), g[0], Color(1.0, 0.7, 0.3, g[1]))
	draw_arc(e + Vector2(0, -6), 118.0, PI, TAU, 40, Color(1, 0.92, 0.7, 0.55), 5.0, true)
	draw_arc(e + Vector2(0, -6), 134.0, PI + 0.2, TAU - 0.2, 40, Color(1, 0.8, 0.5, 0.3), 3.0, true)

# ------------------------------------------------------------ FOREGROUND
func draw_foreground() -> void:
	ld = Vector2(0.7, -0.7).normalized()
	var dark := Color("1f1238")
	var shade := Color("120a26")
	var rim := Color("ff9a5a")
	for r in [[Vector2(40, 708), 74.0, 11], [Vector2(150, 722), 52.0, 12], [Vector2(1250, 712), 86.0, 13], [Vector2(1150, 732), 56.0, 14]]:
		rock(r[0], r[1], r[2], dark, shade, rim)
	for b in [[18, 0.6], [62, 1.0], [96, 0.7], [128, 0.9], [1200, 0.8], [1236, 1.2], [1266, 0.8], [1172, 0.7], [310, 0.5], [1020, 0.5]]:
		var bx: float = b[0]
		var bh: float = 90.0 * b[1]
		var lean := -18.0 if bx < 640.0 else 14.0
		for k in 2:
			var bp := Vector2(bx + (k - 0.5) * 16.0, 724)
			var hh := bh * (0.7 + 0.15 * k)
			var bl := PackedVector2Array([bp + Vector2(-9, 0), bp + Vector2(lean * 0.3, -hh * 0.55), bp + Vector2(lean * (k + 0.5), -hh), bp + Vector2(9 + lean * 0.3, -hh * 0.5), bp + Vector2(9, 0)])
			fill(bl, dark)

# ------------------------------------------------------------ LIGHT + GRADE
func draw_rays() -> void:
	for i in 11:
		var a := deg_to_rad(112.0 + i * 8.5)
		var wide := 0.035 + 0.02 * (i % 3)
		var p0 := SUN
		var p1 := SUN + Vector2.from_angle(a - wide) * 1500.0
		var p2 := SUN + Vector2.from_angle(a + wide) * 1500.0
		var c0 := Color(1.0, 0.75, 0.4, 0.05 + 0.015 * (i % 2))
		draw_polygon(PackedVector2Array([p0, p1, p2]), PackedColorArray([c0, Color(c0, 0.0), Color(c0, 0.0)]))

func draw_grade() -> void:
	# cool tint at the top, plum vignette at the bottom (strips: no diagonal creases)
	for i in 24:
		var t := i / 23.0
		draw_rect(Rect2(0, i * 9.0, W, 10.0), Color(0.1, 0.1, 0.45, 0.16 * (1.0 - t)))
		draw_rect(Rect2(0, 470.0 + i * 11.0, W, 12.0), Color(0.12, 0.03, 0.25, 0.3 * t * t))

# ------------------------------------------------------------ HUD
func panel(r: Rect2, accent: Color) -> void:
	ld = Vector2(0.4, -0.9).normalized()
	fill(rrect_pts(Rect2(r.position + Vector2(0, 6), r.size), 16.0), Color(0.05, 0.0, 0.1, 0.4))
	shaded(rrect_pts(r, 16.0), Color("3c2358"), Color("26143e"), Color("7a56a0"), 4.0, 6.0)
	var ip := rrect_pts(r.grow(-6.0), 11.0)
	ip.append(ip[0])
	draw_polyline(ip, Color(accent, 0.75), 2.0, true)

func bar(r: Rect2, frac: float, col: Color, col_d: Color) -> void:
	shaded(rrect_pts(r, r.size.y / 2.0), Color("150a28"), Color("0c0518"), Color("3a2458"), 3.5, 3.0)
	var inner := Rect2(r.position + Vector2(3, 3), Vector2((r.size.x - 6.0) * frac, r.size.y - 6.0))
	var pts := rrect_pts(inner, inner.size.y / 2.0)
	old_ld_fill(pts, col, col_d)
	for i in range(1, 10):
		draw_line(Vector2(r.position.x + 3 + (r.size.x - 6) * i / 10.0, r.position.y + 4), Vector2(r.position.x + 3 + (r.size.x - 6) * i / 10.0, r.end.y - 4), Color(0.08, 0.02, 0.18, 0.55), 2.0)

func old_ld_fill(pts: PackedVector2Array, col: Color, col_d: Color) -> void:
	fill(pts, col)
	fill_many(Geometry2D.clip_polygons(pts, shifted(pts, Vector2(0, -4.0))), col_d)
	var hi := PackedVector2Array()
	for p in pts:
		hi.append(Vector2(p.x, lerpf(p.y, pts[0].y, 0.0)))
	var b := Rect2(pts[0], Vector2.ZERO)
	for p in pts:
		b = b.expand(p)
	fill_many(clip_to(pts, rect_pts(Rect2(b.position.x, b.position.y, b.size.x, b.size.y * 0.38))), Color(1, 1, 1, 0.3))

func portrait(c: Vector2, enemy: bool) -> void:
	ld = Vector2(0.6, -0.8).normalized()
	var pl := Color("e0475a") if enemy else Color("30d3c1")
	shaded(circ(c, 25.0, 28), pl, pl.darkened(0.4), pl.lightened(0.5), 4.0, 5.0)
	if enemy:
		var eye := PackedVector2Array([c + Vector2(-16, -6), c + Vector2(15, 1), c + Vector2(12, 8), c + Vector2(-12, 3)])
		fill(eye, Color("ffe23a"))
		fill(PackedVector2Array([c + Vector2(-18, -13), c + Vector2(18, -2), c + Vector2(18, 1), c + Vector2(-18, -8)]), INK)
		outline(eye, INK, 2.0)
	else:
		fill(circ(c + Vector2(2, 1), 13.0, 18), Color("fffaf0"))
		fill(circ(c + Vector2(6, 2), 6.5, 12), Color("1c1038"))
		fill(circ(c + Vector2(8, -1), 2.2, 8), Color.WHITE)
		outline(circ(c + Vector2(2, 1), 13.0, 18), INK, 2.5)

func hp_panel(r: Rect2, name_s: String, hp: String, frac: float, enemy: bool) -> void:
	panel(r, Color("ff6a7a") if enemy else Color("5af0dc"))
	portrait(Vector2(r.position.x + 44, r.position.y + 42), enemy)
	txt(name_s, Vector2(r.position.x + 120, r.position.y + 24), 18, Color("ffd24a"), 6)
	txt(hp, Vector2(r.end.x - 52, r.position.y + 24), 16, CREAM, 6)
	var col := Color("ff5a5e") if enemy else Color("5ee890")
	var cold := Color("b82e4a") if enemy else Color("1f9a70")
	bar(Rect2(r.position.x + 78, r.position.y + 42, r.size.x - 96, 24), frac, col, cold)

func draw_hud() -> void:
	hp_panel(Rect2(22, 20, 290, 80), "BISCUIT", "82/100", 0.82, false)
	hp_panel(Rect2(968, 20, 290, 80), "BRUTE", "38/100", 0.38, true)
	# banner
	ld = Vector2(0.4, -0.9).normalized()
	for s in [-1.0, 1.0]:
		var tail := PackedVector2Array([Vector2(640 + s * 128, 24), Vector2(640 + s * 190, 24), Vector2(640 + s * 170, 46), Vector2(640 + s * 190, 68), Vector2(640 + s * 128, 68)])
		shaded(tail, Color("e8841f"), Color("a8481c"), Color("ffc860"), 4.0, 4.0)
	fill(rrect_pts(Rect2(496, 20, 288, 62), 18.0), Color(0.05, 0, 0.1, 0.35))
	shaded(rrect_pts(Rect2(496, 14, 288, 62), 18.0), Color("ffbf3a"), Color("e8801c"), Color("fff2a8"), 5.0, 8.0)
	txt("YOUR TURN", Vector2(640, 46), 28, CREAM, 10)
	panel(Rect2(562, 88, 156, 36), Color("ffd24a"))
	txt("TURN 7", Vector2(640, 107), 15, Color("ffd24a"), 6)
	draw_wind()
	draw_gauge()

func draw_wind() -> void:
	panel(Rect2(498, 624, 284, 78), Color("5af0dc"))
	# windsock
	var o := Vector2(540, 664)
	draw_line(o + Vector2(0, 26), o + Vector2(0, -26), INK, 6.0)
	draw_line(o + Vector2(0, 26), o + Vector2(0, -26), Color("c8c0e8"), 3.0)
	for i in 4:
		var x0 := 4.0 + i * 10.0
		var h0 := 16.0 - i * 3.2
		var h1 := 16.0 - (i + 1) * 3.2
		var seg := PackedVector2Array([o + Vector2(x0, -26 - h0 / 2.0 + i * 1.5), o + Vector2(x0 + 10, -26 - h1 / 2.0 + (i + 1) * 1.5 + 2), o + Vector2(x0 + 10, -26 + h1 / 2.0 + (i + 1) * 1.5 + 2), o + Vector2(x0, -26 + h0 / 2.0 + i * 1.5)])
		fill(seg, Color("ff7a3a") if i % 2 == 0 else CREAM)
		outline(seg, INK, 2.5)
	txt("WIND", Vector2(640, 646), 16, Color("a8e8ff"), 6)
	for i in 6:
		var x := 596.0 + i * 24.0
		var chev := PackedVector2Array([Vector2(x, 662), Vector2(x + 12, 662), Vector2(x + 22, 674), Vector2(x + 12, 686), Vector2(x, 686), Vector2(x + 10, 674)])
		var lit := i < 4
		fill(chev, Color("5ae8ff") if lit else Color("2a1e4a"))
		outline(chev, INK, 2.5)
		if lit:
			fill(PackedVector2Array([Vector2(x + 2, 664), Vector2(x + 11, 664), Vector2(x + 14, 668), Vector2(x + 5, 668)]), Color(1, 1, 1, 0.5))
	txt("4", Vector2(748, 664), 34, Color("fff0d0"), 9)

func draw_gauge() -> void:
	var c := pivot_world()
	var r := 120.0
	draw_arc(c, r, -PI / 2.0, 0.0, 40, INK, 19.0, true)
	draw_arc(c, r, -PI / 2.0, 0.0, 40, Color("2a1e4a"), 12.0, true)
	draw_arc(c, r, -deg_to_rad(player_ang), 0.0, 24, Color("ffbf3a"), 12.0, true)
	draw_arc(c, r - 2.5, -deg_to_rad(player_ang), 0.0, 24, Color("fff0a0"), 3.0, true)
	for a in [0, 15, 30, 45, 60, 75, 90]:
		var dd := Vector2.from_angle(-deg_to_rad(a))
		draw_line(c + dd * (r + 10), c + dd * (r + (16 if a % 30 == 0 else 13)), INK, 4.0)
	var d := Vector2.from_angle(-deg_to_rad(player_ang))
	# aim dots
	for i in 7:
		draw_circle(muzzle_world() + d * (24.0 + i * 20.0), 3.2 - i * 0.2, Color(1, 0.95, 0.7, 0.9 - i * 0.1))
	var tip := c + d * r
	fill(circ(tip, 11.0, 14), Color("fff0a0"))
	outline(circ(tip, 11.0, 14), INK, 3.5)
	var lab := c + Vector2.from_angle(-deg_to_rad(player_ang + 13.0)) * (r + 38.0)
	shaded(rrect_pts(Rect2(lab.x - 32, lab.y - 17, 64, 34), 17.0), Color("2a1e4a"), Color("170c30"), Color("6a4a98"), 4.0, 4.0)
	txt("50", lab + Vector2(-5, 0), 20, Color("ffd24a"), 6)
	draw_arc(lab + Vector2(17, -6), 3.2, 0, TAU, 10, Color("ffd24a"), 2.0, true)
	var base := tank_base(player_x)
	var pr := Rect2(base.x - 84, base.y + 30, 168, 28)
	shaded(rrect_pts(pr, 14.0), Color("150a28"), Color("0c0518"), Color("3a2458"), 4.0, 3.0)
	var fr := Rect2(pr.position + Vector2(4, 4), Vector2(160.0 * 0.72, 20))
	var fp := rrect_pts(fr, 10.0)
	fill(fp, Color("ff8a2a"))
	fill_many(clip_to(fp, rect_pts(Rect2(fr.position.x, fr.position.y, fr.size.x * 0.5, fr.size.y))), Color("ffc23a"))
	fill_many(clip_to(fp, rect_pts(Rect2(fr.position.x, fr.position.y, fr.size.x, fr.size.y * 0.4))), Color(1, 1, 1, 0.3))
	txt("POWER 72", pr.get_center(), 13, CREAM, 5)
