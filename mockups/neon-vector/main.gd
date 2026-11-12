extends Node2D
## Static neon-vector battle mockup. Everything is drawn in code on two layers:
## `back` (normal blend: sky, fills, smoke) and `glow` (additive: all neon).

const W := 1280.0
const H := 720.0
const CYAN := Color("19e6ff")
const MAGENTA := Color("ff2e9a")
const ORANGE := Color("ffa12e")
const VIOLET := Color("9d8cff")
const PLAYER_X := 256.0
const ENEMY_X := 998.0
const CRATER_X := 905.0
const BLAST_X := 1072.0
const STEP := 4.0

var font: Font
var rng := RandomNumberGenerator.new()
var back: Node2D
var glow: Node2D
var terrain := PackedVector2Array()
var stars: Array = []
var debris: Array = []
var sparks: Array = []
var rays: Array = []
var smoke: Array = []
var sky := Gradient.new()
var blast := Vector2.ZERO
var shell_t := 0.46
var shell_start := Vector2.ZERO


func _ready() -> void:
	font = load("res://assets/fonts/kenvector_future_thin.ttf")
	rng.seed = 11
	sky.offsets = PackedFloat32Array([0.0, 0.5, 0.78, 1.0])
	sky.colors = PackedColorArray([Color("070519"), Color("150c3a"), Color("34115a"), Color("1a0b3a")])
	for x in range(0, int(W) + 1, int(STEP)):
		terrain.append(Vector2(x, th(x)))
	blast = Vector2(BLAST_X, th(BLAST_X) - 14)
	_make_decor()
	back = _layer(false)
	glow = _layer(true)
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.05
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	if "--capture" in OS.get_cmdline_user_args():
		_capture()


func _layer(additive: bool) -> Node2D:
	var n := Node2D.new()
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		n.material = m
		n.draw.connect(_draw_glow)
	else:
		n.draw.connect(_draw_back)
	add_child(n)
	return n


func _capture() -> void:
	for i in 30:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path("res://shot.png"))
	get_tree().quit()


# ---------------------------------------------------------------- terrain

func th(x: float) -> float:
	var y := 520.0 + sin(x * 0.006 + 0.5) * 36.0 + sin(x * 0.013 + 2.0) * 15.0 + sin(x * 0.029) * 4.0
	y -= 78.0 * exp(-pow((x - PLAYER_X) / 120.0, 2))
	y -= 24.0 * exp(-pow((x - ENEMY_X) / 95.0, 2))
	var d := absf(x - CRATER_X) / 58.0
	if d < 1.0:
		y += 48.0 * (1.0 - d * d)
	elif d < 1.5:
		y -= 7.0 * sin((d - 1.0) * TAU)
	return y


func slope_at(x: float) -> float:
	return atan2(th(x + 14.0) - th(x - 14.0), 28.0)


func heat(x: float) -> float:
	var h1 := exp(-pow((x - blast.x) / 150.0, 2))
	var h2 := 0.55 * exp(-pow((x - CRATER_X) / 75.0, 2))
	return maxf(h1, h2)


func _make_decor() -> void:
	for i in 150:
		stars.append([Vector2(rng.randf_range(0, W), rng.randf_range(0, 470)), rng.randf_range(0.6, 1.8), rng.randf_range(0.25, 0.9)])
	for i in 26:  # crater lip chunks + flying chunks near blast
		var x := CRATER_X + rng.randf_range(-95, 95)
		var up := rng.randf_range(14, 110) * (1.0 - absf(x - CRATER_X) / 140.0)
		debris.append([Vector2(x, th(x) - up), rng.randf_range(0, TAU), rng.randf_range(3, 7), 0.5])
	for i in 22:
		var a := rng.randf_range(-PI * 0.95, -PI * 0.05)
		var r := rng.randf_range(40, 190)
		debris.append([blast + Vector2(cos(a), sin(a)) * r + Vector2(0, 20), rng.randf_range(0, TAU), rng.randf_range(3, 8), 1.0])
	for i in 70:
		var a := rng.randf_range(-PI * 1.02, 0.02)
		sparks.append([a, rng.randf_range(160, 560), rng.randf_range(0.7, 1.0)])
	for i in 18:
		rays.append([TAU * i / 18.0 + rng.randf_range(-0.1, 0.1), rng.randf_range(55, 150)])
	for i in 9:
		smoke.append([blast + Vector2(rng.randf_range(-70, 90), -rng.randf_range(40, 190)), rng.randf_range(26, 58)])


# ---------------------------------------------------------------- helpers

func arc_pts(c: Vector2, r: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var p := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / n)
		p.append(c + Vector2(cos(a), sin(a)) * r)
	return p


func gl(ci: CanvasItem, pts: PackedVector2Array, col: Color, w := 2.0, closed := false) -> void:
	var p := pts
	if closed:
		p = pts.duplicate()
		p.append(pts[0])
	var core := col.lerp(Color.WHITE, 0.55)
	ci.draw_polyline(p, Color(col, 0.05 * col.a), w * 8.0, true)
	ci.draw_polyline(p, Color(col, 0.10 * col.a), w * 4.5, true)
	ci.draw_polyline(p, Color(col, 0.30 * col.a), w * 2.2, true)
	ci.draw_polyline(p, Color(col, 0.95 * col.a), w, true)
	ci.draw_polyline(p, Color(core, 0.8 * col.a), maxf(w * 0.45, 1.0), true)


func txt(ci: CanvasItem, s: String, at: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_CENTER) -> void:
	var p := Vector2(at.x - (300.0 if align == HORIZONTAL_ALIGNMENT_CENTER else 0.0), at.y)
	for o in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		ci.draw_string(font, p + o, s, align, 600, size, Color(col, 0.16))
	ci.draw_string(font, p, s, align, 600, size, col.lerp(Color.WHITE, 0.4))


# ---------------------------------------------------------------- back layer

func _draw_back() -> void:
	for y in range(0, int(H), 10):
		var c := sky.sample(float(y) / H)
		back.draw_rect(Rect2(0, y, W, 11), c)
	_ridge_fill()
	_terrain_fill()
	for s in smoke:
		for k in 4:
			var o := Vector2(sin(k * 2.0 + s[1]) * s[1] * 0.4, -k * s[1] * 0.3)
			back.draw_circle(s[0] + o, s[1] * (1.0 - k * 0.12), Color(0.22, 0.12, 0.38, 0.22))
	_tanks(back, false)
	for d in debris:
		var tri := _chunk(d)
		back.draw_colored_polygon(tri, Color(0.10, 0.06, 0.24))


func _ridge_fill() -> void:
	var p := PackedVector2Array()
	for x in range(0, int(W) + 1, 8):
		p.append(Vector2(x, ridge(x)))
	p.append(Vector2(W, H))
	p.append(Vector2(0, H))
	back.draw_colored_polygon(p, Color("120a30"))


func ridge(x: float) -> float:
	return 440.0 + sin(x * 0.004 + 1.0) * 34.0 + sin(x * 0.011 + 0.4) * 14.0


func _terrain_fill() -> void:
	var top := Color(0.17, 0.10, 0.42)
	var bot := Color(0.03, 0.02, 0.10)
	for i in terrain.size() - 1:
		var a := terrain[i]
		var b := terrain[i + 1]
		back.draw_polygon(PackedVector2Array([a, b, Vector2(b.x, H), Vector2(a.x, H)]),
			PackedColorArray([top, top, bot, bot]))


func _chunk(d: Array) -> PackedVector2Array:
	var p := PackedVector2Array()
	for k in 3:
		var a: float = d[1] + k * TAU / 3.0 + k * 0.4
		p.append(d[0] + Vector2(cos(a), sin(a)) * d[2] * (1.0 if k != 1 else 0.6))
	return p


# ---------------------------------------------------------------- glow layer

func _draw_glow() -> void:
	_stars_and_grid()
	_ridge_line()
	_terrain_glow()
	_trajectory()
	_tanks(glow, true)
	for d in debris:
		var ec := ORANGE if d[3] > 0.9 else VIOLET
		gl(glow, _chunk(d), ec, 1.2, true)
	_explosion()
	_hud()


func _stars_and_grid() -> void:
	for x in range(0, int(W), 64):
		glow.draw_line(Vector2(x, 0), Vector2(x, 560), Color(0.4, 0.5, 1.0, 0.035), 1.0)
	for y in range(0, 560, 64):
		glow.draw_line(Vector2(0, y), Vector2(W, y), Color(0.4, 0.5, 1.0, 0.035), 1.0)
	for i in 14:  # horizon haze
		var y := 400.0 + i * 12.0
		glow.draw_line(Vector2(0, y), Vector2(W, y), Color(0.55, 0.2, 0.9, 0.012 + i * 0.002), 14.0)
	for s in stars:
		glow.draw_circle(s[0], s[1], Color(0.8, 0.85, 1.0, s[2] * 0.7))
		if s[1] > 1.6:
			glow.draw_line(s[0] - Vector2(4, 0), s[0] + Vector2(4, 0), Color(0.8, 0.85, 1.0, 0.25), 1.0)
			glow.draw_line(s[0] - Vector2(0, 4), s[0] + Vector2(0, 4), Color(0.8, 0.85, 1.0, 0.25), 1.0)
	gl(glow, arc_pts(Vector2(900, 190), 62, 0, TAU, 48), MAGENTA * Color(1, 1, 1, 0.35), 1.2)
	gl(glow, arc_pts(Vector2(900, 190), 40, 0, TAU, 40), VIOLET * Color(1, 1, 1, 0.18), 1.0)


func _ridge_line() -> void:
	var p := PackedVector2Array()
	for x in range(0, int(W) + 1, 8):
		p.append(Vector2(x, ridge(x)))
	gl(glow, p, Color(0.45, 0.30, 1.0, 0.45), 1.2)


func _terrain_glow() -> void:
	var base := VIOLET
	var cols := PackedColorArray()
	for t in terrain:
		cols.append(base.lerp(ORANGE.lerp(Color.WHITE, 0.25), heat(t.x)))
	for off in [30.0, 62.0, 100.0]:  # contour echoes give the fill depth
		var echo := terrain.duplicate()
		for i in echo.size():
			echo[i].y += off
		glow.draw_polyline(echo, Color(0.5, 0.4, 1.0, 0.11 - off * 0.0007), 1.2, true)
	for i in terrain.size() - 1:  # soft gradient below the edge, hotter near blast
		var a := terrain[i]
		var b := terrain[i + 1]
		var ca := Color(cols[i], 0.20 + heat(a.x) * 0.35)
		var cb := Color(cols[i + 1], 0.20 + heat(b.x) * 0.35)
		var z := Color(0, 0, 0, 0)
		glow.draw_polygon(PackedVector2Array([a, b, b + Vector2(0, 58), a + Vector2(0, 58)]),
			PackedColorArray([ca, cb, z, z]))
	for pass_i in 4:
		var w: float = [11.0, 6.0, 3.0, 1.6][pass_i]
		var al: float = [0.06, 0.12, 0.45, 1.0][pass_i]
		var cc := PackedColorArray()
		for c in cols:
			cc.append(Color(c.lerp(Color.WHITE, 0.5 if pass_i == 3 else 0.0), al))
		glow.draw_polyline_colors(terrain, cc, w, true)


func _trajectory() -> void:
	var s := _tank_pivot(PLAYER_X, 1.0) + Vector2(cos(deg_to_rad(50.0)), -sin(deg_to_rad(50.0))) * 34.0
	shell_start = s
	var e := blast
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	for i in range(0, 41):  # trail behind the shell
		var t := shell_t * i / 40.0
		pts.append(_arc_at(s, e, t))
		var f := float(i) / 40.0
		cols.append(Color(CYAN.lerp(Color.WHITE, f * f), f * f * 0.9))
	for pass_i in 3:
		var w: float = [14.0, 7.0, 3.0][pass_i]
		var al: float = [0.08, 0.18, 1.0][pass_i]
		var c2 := PackedColorArray()
		for c in cols:
			c2.append(Color(c, c.a * al))
		glow.draw_polyline_colors(pts, c2, w, true)
	for i in range(0, 60):  # faint dotted prediction ahead
		var t := shell_t + (1.0 - shell_t) * i / 60.0
		if i % 2 == 0:
			glow.draw_circle(_arc_at(s, e, t), 1.6, Color(CYAN, 0.35 * (1.0 - float(i) / 60.0) + 0.05))
	var head := _arc_at(s, e, shell_t)
	for k in 8:
		glow.draw_circle(head, 5.0 + k * 3.5, Color(CYAN, 0.05 + 0.01 * (8 - k)))
	glow.draw_circle(head, 4.5, Color(0.75, 1.0, 1.0, 1.0))
	glow.draw_circle(head, 2.5, Color.WHITE)


func _arc_at(a: Vector2, b: Vector2, t: float) -> Vector2:
	return a.lerp(b, t) + Vector2(0, -4.0 * 285.0 * t * (1.0 - t))


# ---------------------------------------------------------------- tanks

func _tank_pivot(x: float, _f: float) -> Vector2:
	return Vector2(x, th(x) + 2.0) + Vector2(0, -27).rotated(slope_at(x))


func _tanks(ci: CanvasItem, is_glow: bool) -> void:
	_tank(ci, PLAYER_X, 1.0, CYAN, 0, 50.0, is_glow)
	_tank(ci, ENEMY_X, -1.0, MAGENTA, 1, 38.0, is_glow)


func _tank(ci: CanvasItem, x: float, f: float, col: Color, kind: int, deg: float, is_glow: bool) -> void:
	var pos := Vector2(x, th(x) + 2.0)
	ci.draw_set_transform(pos, slope_at(x), Vector2.ONE)
	var parts: Array = []  # [points, closed, fill]
	parts.append([_flip(_stadium(Vector2(0, -6), 26, 6), f), true, true])
	var pivot := Vector2(0, -27)
	var blen := 32.0
	if kind == 0:
		parts.append([_flip(PackedVector2Array([Vector2(-20, -12), Vector2(20, -12), Vector2(15, -25), Vector2(-15, -25)]), f), true, true])
		parts.append([_flip(arc_pts(Vector2(0, -25), 11, PI, TAU, 12), f), true, true])
	else:
		pivot = Vector2(0, -32)
		blen = 38.0
		parts.append([_flip(PackedVector2Array([Vector2(-25, -12), Vector2(27, -12), Vector2(14, -27), Vector2(-19, -23)]), f), true, true])
		parts.append([_flip(PackedVector2Array([Vector2(-9, -26), Vector2(9, -26), Vector2(6, -37), Vector2(-6, -37)]), f), true, true])
		parts.append([_flip(PackedVector2Array([Vector2(-17, -22), Vector2(-25, -48)]), f), false, false])
	var dir := Vector2(cos(deg_to_rad(deg)) * f, -sin(deg_to_rad(deg)))
	parts.append([PackedVector2Array([pivot, pivot + dir * blen]), false, false])
	var fill := Color(col.r * 0.18, col.g * 0.18, col.b * 0.18, 1.0)
	for p in parts:
		if is_glow:
			gl(ci, p[0], col, 2.0 if p[1] else 2.4, p[1])
		elif p[2]:
			ci.draw_colored_polygon(p[0], fill)
	if is_glow:
		for wx in [-16, -5, 6, 17]:
			gl(ci, arc_pts(Vector2(wx * f, -6), 3.0, 0, TAU, 10), col, 1.2)
		var tip: Vector2 = pivot + dir * blen
		ci.draw_circle(tip, 4.0, Color(col, 0.35))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _flip(p: PackedVector2Array, f: float) -> PackedVector2Array:
	var o := p.duplicate()
	if f < 0.0:
		for i in o.size():
			o[i].x = -o[i].x
		o.reverse()
	return o


func _stadium(c: Vector2, hw: float, r: float) -> PackedVector2Array:
	var p := PackedVector2Array()
	p.append_array(arc_pts(c + Vector2(hw - r, 0), r, -PI / 2, PI / 2, 8))
	p.append_array(arc_pts(c - Vector2(hw - r, 0), r, PI / 2, PI * 1.5, 8))
	return p


# ---------------------------------------------------------------- explosion

func _explosion() -> void:
	var c := blast
	for i in 16:
		var f := float(i) / 15.0
		var col := MAGENTA.lerp(ORANGE, clampf(f * 1.6, 0, 1)).lerp(Color.WHITE, clampf(f - 0.7, 0, 1) * 2.0)
		glow.draw_circle(c, 230.0 - i * 13.0, Color(col, 0.010 + f * 0.008))
	for r in rays:
		var d := Vector2(cos(r[0]), sin(r[0]))
		glow.draw_line(c + d * 16, c + d * r[1], Color(ORANGE, 0.14), 7.0, true)
		glow.draw_line(c + d * 16, c + d * r[1], Color(1, 0.85, 0.5, 0.7), 1.6, true)
		glow.draw_line(c + d * 16, c + d * r[1] * 0.45, Color(1, 1, 1, 0.8), 2.4, true)
	gl(glow, arc_pts(c, 92, 0, TAU, 56), Color(MAGENTA, 0.7), 1.6)
	gl(glow, arc_pts(c, 128, 0, TAU, 64), Color(VIOLET, 0.25), 1.2)
	glow.draw_circle(c, 30, Color(1, 0.6, 0.3, 0.5))
	glow.draw_circle(c, 20, Color(1, 0.92, 0.7, 0.9))
	glow.draw_circle(c, 11, Color.WHITE)
	_sparks(c)


func _sparks(c: Vector2) -> void:
	var tn := 0.62
	for s in sparks:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for k in 7:
			var t: float = tn * s[2] - 0.13 + k * 0.0217
			var v: Vector2 = Vector2(cos(s[0]), sin(s[0])) * s[1]
			pts.append(c + v * t + Vector2(0, 450.0 * t * t))
			var f := float(k) / 6.0
			cols.append(Color(1.0, 0.55 + 0.45 * f, 0.25 + 0.6 * f * f, f))
		if pts[6].y > th(pts[6].x) - 2.0:
			continue
		glow.draw_polyline_colors(pts, cols, 2.0, true)
		glow.draw_circle(pts[6], 1.8, Color(1, 0.95, 0.8, 0.9))


# ---------------------------------------------------------------- HUD

func _hud() -> void:
	_aim_dial()
	_hp_bar(Vector2(PLAYER_X, _tank_pivot(PLAYER_X, 1.0).y - 118), 0.82, CYAN, "PLAYER", 74)
	_hp_bar(Vector2(ENEMY_X, _tank_pivot(ENEMY_X, 1.0).y - 62), 0.55, MAGENTA, "RAIDER", 74)
	_wind(Vector2(W * 0.5, 40))
	_banner(Vector2(W * 0.5, 112))
	txt(glow, "TURN", Vector2(40, 40), 14, Color(VIOLET, 0.8), HORIZONTAL_ALIGNMENT_LEFT)
	txt(glow, "07", Vector2(40, 82), 36, CYAN, HORIZONTAL_ALIGNMENT_LEFT)
	gl(glow, PackedVector2Array([Vector2(36, 98), Vector2(36, 104), Vector2(110, 104)]), Color(VIOLET, 0.7), 1.2)


func _aim_dial() -> void:
	var c := _tank_pivot(PLAYER_X, 1.0)
	var r := 66.0
	var ang := deg_to_rad(50.0)
	gl(glow, arc_pts(c, r, -PI / 2, 0, 30), Color(CYAN, 0.4), 1.2)
	gl(glow, arc_pts(c, r - 5, -ang, 0, 24), Color(CYAN, 1.0), 3.5)
	for d in range(0, 91, 10):
		var a := -deg_to_rad(d)
		var dd := Vector2(cos(a), sin(a))
		var l := 12.0 if d % 45 == 0 else 6.0
		glow.draw_line(c + dd * r, c + dd * (r + l), Color(CYAN, 0.7), 1.4, true)
	var m := Vector2(cos(-ang), sin(-ang))
	gl(glow, PackedVector2Array([c + m * (r - 12), c + m * (r + 16)]), Color(1, 1, 1, 1), 2.0)
	glow.draw_circle(c + m * r, 5, Color(0.8, 1, 1, 0.9))
	glow.draw_line(c, c + Vector2(r + 14, 0), Color(CYAN, 0.25), 1.0)
	txt(glow, "50", c + m * (r + 40) + Vector2(0, 7), 20, CYAN)
	# power bar under the tank
	var pos := Vector2(PLAYER_X, th(PLAYER_X) + 24)
	for i in 12:
		var x := pos.x - 66 + i * 11.5
		var lit := i < 8
		var col := CYAN.lerp(MAGENTA, float(i) / 11.0)
		if lit:
			gl(glow, PackedVector2Array([Vector2(x, pos.y), Vector2(x + 7, pos.y)]), col, 4.0)
		else:
			glow.draw_line(Vector2(x, pos.y), Vector2(x + 7, pos.y), Color(0.5, 0.5, 1.0, 0.25), 4.0)
	txt(glow, "POWER 68", pos + Vector2(0, 26), 14, Color(CYAN, 0.9))


func _hp_bar(c: Vector2, frac: float, col: Color, label: String, w: float) -> void:
	var a := c - Vector2(w, 0)
	var b := c + Vector2(w, 0)
	glow.draw_line(a, b, Color(0.5, 0.5, 1.0, 0.18), 7.0)
	gl(glow, PackedVector2Array([a, a.lerp(b, frac)]), col, 5.0)
	gl(glow, PackedVector2Array([a + Vector2(0, -7), a + Vector2(-5, -7), a + Vector2(-5, 7), a + Vector2(0, 7)]), Color(col, 0.6), 1.0)
	gl(glow, PackedVector2Array([b + Vector2(0, -7), b + Vector2(5, -7), b + Vector2(5, 7), b + Vector2(0, 7)]), Color(col, 0.6), 1.0)
	txt(glow, label, c + Vector2(0, -16), 15, col)


func _wind(c: Vector2) -> void:
	txt(glow, "WIND", c + Vector2(-92, 6), 14, Color(VIOLET, 0.9))
	for i in 5:  # chevrons point left (toward the player), 4 of 5 lit
		var x := c.x - 38 + i * 20
		var p := PackedVector2Array([Vector2(x + 9, c.y - 10), Vector2(x, c.y), Vector2(x + 9, c.y + 10)])
		if i < 4:
			gl(glow, p, ORANGE, 2.4)
		else:
			glow.draw_polyline(p, Color(0.5, 0.5, 1.0, 0.3), 2.0, true)
	txt(glow, "4", c + Vector2(92, 12), 32, ORANGE)


func _banner(c: Vector2) -> void:
	txt(glow, "YOUR TURN", c + Vector2(0, 14), 44, CYAN)
	for s in [-1.0, 1.0]:
		var p := PackedVector2Array([c + Vector2(s * 150, 0), c + Vector2(s * 190, 0), c + Vector2(s * 230, 0), c + Vector2(s * 262, 0)])
		gl(glow, p, Color(CYAN, 0.8), 1.4)
		var dm := PackedVector2Array([c + Vector2(s * 268, 0), c + Vector2(s * 276, -6), c + Vector2(s * 284, 0), c + Vector2(s * 276, 6)])
		gl(glow, dm, CYAN, 1.2, true)
