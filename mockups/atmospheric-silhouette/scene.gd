extends Node2D

const W := 1280.0
const H := 720.0
const FG := Color("160d22")
const RIM := Color("ffb347")
const RIM_FOE := Color("ff5d73")
const HOT := Color("fff1b8")
const HUD := Color(1.0, 0.93, 0.8, 0.85)
const HUD_DIM := Color(1.0, 0.93, 0.8, 0.3)
const PLAYER_X := 256.0
const FOE_X := 998.0
const CRATER_X := 770.0
const BLAST_X := 862.0
const SHELL_T := 0.56

var glow: Node2D
var font := ThemeDB.fallback_font

func _ready() -> void:
	glow = Node2D.new()
	glow.set_script(load("res://glow.gd"))
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow.material = m
	add_child(glow)
	if "--capture" in OS.get_cmdline_user_args():
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://shot.png")
		get_tree().quit()

# ---------- terrain ----------
func ground(x: float) -> float:
	var y := 500.0 - 70.0 * exp(-pow((x - PLAYER_X) / 140.0, 2.0))
	y += 22.0 * sin(x * 0.0062 + 1.0) + 10.0 * sin(x * 0.017 + 2.0)
	y -= 30.0 * exp(-pow((x - 1100.0) / 120.0, 2.0))
	y += 38.0 * exp(-pow((x - CRATER_X) / 38.0, 2.0))
	y += 14.0 * exp(-pow((x - BLAST_X) / 30.0, 2.0))
	return y

func ridge(x: float, base: float, amp: float, off: float) -> float:
	return base + amp * (sin(x * 0.004 + off) * 0.6 + sin(x * 0.011 + off * 2.3) * 0.3 + sin(x * 0.027 + off * 5.1) * 0.1)

func rng_f(i: int, k: int) -> float:
	return fposmod(sin(i * 12.9898 + k * 78.233) * 43758.5453, 1.0)

func _draw() -> void:
	_sky()
	_ridges()
	_foreground()
	_tank(PLAYER_X, 1.0, 50.0, RIM, false)
	_tank(FOE_X, -1.0, 40.0, RIM_FOE, true)
	_debris()
	_hud()

func _sky() -> void:
	var stops := [[0.0, Color("1d1b4a")], [0.3, Color("6a2a73")], [0.55, Color("e0527a")], [0.78, Color("ff9a4d")], [1.0, Color("ffd27a")]]
	for i in range(stops.size() - 1):
		var y0: float = stops[i][0] * 560.0
		var y1: float = stops[i + 1][0] * 560.0
		var c0: Color = stops[i][1]
		var c1: Color = stops[i + 1][1]
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(W, y0), Vector2(W, y1), Vector2(0, y1)]),
			PackedColorArray([c0, c0, c1, c1]))
	draw_rect(Rect2(0, 560, W, 200), Color("ffd27a"))
	var sun := Vector2(700, 395)
	for i in 28:
		draw_circle(sun, 30.0 + i * 16.0, Color(1.0, 0.8, 0.45, 0.028))
	draw_circle(sun, 44, Color("fff0c0"))
	for i in 9:
		var cy := 150.0 + i * 24.0
		var cx := rng_f(i, 0) * W
		draw_rect(Rect2(cx - 160, cy, 320 + rng_f(i, 1) * 160, 3), Color(1.0, 0.7, 0.6, 0.16))

func _ridges() -> void:
	var layers := [
		[400.0, 70.0, 0.3, Color("c4547a")], [440.0, 62.0, 1.7, Color("a2457c")],
		[470.0, 56.0, 3.1, Color("7e3a7c")], [500.0, 50.0, 4.4, Color("5a2f78")],
		[535.0, 44.0, 6.2, Color("3d2468")]]
	for l in layers:
		var pts := PackedVector2Array([Vector2(0, H)])
		for x in range(0, 1281, 8):
			pts.append(Vector2(x, ridge(x, l[0], l[1], l[2])))
		pts.append(Vector2(W, H))
		draw_colored_polygon(pts, l[3])
		for k in 6:
			draw_rect(Rect2(0, l[0] + 20 + k * 22, W, 22), Color(1.0, 0.75, 0.55, 0.035))

func _foreground() -> void:
	var top := PackedVector2Array()
	var poly := PackedVector2Array([Vector2(0, H)])
	for x in range(0, 1285, 4):
		var p := Vector2(x, ground(x))
		top.append(p)
		poly.append(p)
	poly.append(Vector2(W, H))
	draw_colored_polygon(poly, FG)
	for k in 10:
		var sh := PackedVector2Array([Vector2(0, H)])
		for q in top:
			sh.append(q + Vector2(0, 8 + k * 16))
		sh.append(Vector2(W, H))
		draw_colored_polygon(sh, Color(0.35, 0.12, 0.3, 0.05))
	draw_polyline(top, Color(1.0, 0.6, 0.3, 0.18), 9.0, true)
	draw_polyline(top, Color(1.0, 0.7, 0.35, 0.5), 4.0, true)
	draw_polyline(top, RIM, 2.0, true)
	var cr := PackedVector2Array()
	for x in range(int(CRATER_X) - 60, int(CRATER_X) + 61, 3):
		cr.append(Vector2(x, ground(x) + 1.0))
	draw_polyline(cr, Color(1.0, 0.45, 0.2, 0.9), 3.0, true)
	draw_polyline(cr, HOT, 1.2, true)

func _tank(x: float, dir: float, ang: float, rim: Color, foe: bool) -> void:
	var gy := ground(x)
	var slope := (ground(x + 20) - ground(x - 20)) / 40.0
	draw_set_transform(Vector2(x, gy + 3), atan(slope) * 0.8, Vector2(dir, 1) * 1.3)
	var tracks: PackedVector2Array
	var body: PackedVector2Array
	var turret: PackedVector2Array
	if foe:
		tracks = PackedVector2Array([Vector2(-36, -2), Vector2(36, -2), Vector2(40, -12), Vector2(32, -20), Vector2(-32, -20), Vector2(-40, -12)])
		body = PackedVector2Array([Vector2(-34, -18), Vector2(34, -18), Vector2(26, -36), Vector2(-26, -42), Vector2(-34, -30)])
		turret = PackedVector2Array([Vector2(-12, -36), Vector2(14, -36), Vector2(18, -50), Vector2(-4, -56), Vector2(-14, -48)])
	else:
		tracks = PackedVector2Array([Vector2(-34, -2), Vector2(34, -2), Vector2(38, -10), Vector2(30, -17), Vector2(-30, -17), Vector2(-38, -10)])
		body = PackedVector2Array([Vector2(-32, -15), Vector2(32, -15), Vector2(22, -32), Vector2(-22, -32)])
		turret = PackedVector2Array([Vector2(-15, -30), Vector2(15, -30), Vector2(11, -42), Vector2(-9, -44)])
	var pivot := Vector2(4, -48) if foe else Vector2(0, -42)
	var a := deg_to_rad(ang)
	var tip := pivot + Vector2(cos(a), -sin(a)) * 44.0
	draw_line(pivot, tip, FG, 8.0)
	draw_line(pivot + Vector2(0, -3.5).rotated(-a), tip + Vector2(0, -3.5).rotated(-a), rim, 1.6)
	for poly in [tracks, body, turret]:
		draw_colored_polygon(poly, FG)
	draw_polyline(PackedVector2Array([body[1], body[2], body[3]]) if foe else PackedVector2Array([body[1], body[2], body[3]]), rim, 2.0, true)
	draw_polyline(PackedVector2Array([turret[1], turret[2], turret[3]]), rim, 2.0, true)
	draw_polyline(PackedVector2Array([tracks[2], tracks[3], tracks[4]]), Color(rim.r, rim.g, rim.b, 0.7), 1.5, true)
	for i in 5:
		draw_circle(Vector2(-24 + i * 12, -8), 4.5, Color("2a1a3a"))
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func muzzle() -> Vector2:
	var a := deg_to_rad(50.0)
	return Vector2(PLAYER_X, ground(PLAYER_X) + 3) + Vector2(0, -42) + Vector2(cos(a), -sin(a)) * 44.0

func shell_at(t: float) -> Vector2:
	var p0 := muzzle()
	var p2 := Vector2(BLAST_X, ground(BLAST_X))
	var ctrl := Vector2((p0.x + p2.x) * 0.5, -140.0)
	return p0.lerp(ctrl, t).lerp(ctrl.lerp(p2, t), t)

func _debris() -> void:
	for i in 26:
		var ang := -PI * (0.1 + 0.8 * rng_f(i, 3))
		var d := 20.0 + rng_f(i, 4) * 120.0
		var c := Vector2(CRATER_X, ground(CRATER_X) + 10.0) + Vector2(cos(ang), sin(ang)) * d * Vector2(1.0, 1.5)
		var sz := 2.0 + rng_f(i, 5) * 4.5
		var rot := rng_f(i, 6) * TAU
		var tri := PackedVector2Array()
		for k in 3:
			tri.append(c + Vector2(cos(rot + k * 2.1), sin(rot + k * 2.1)) * sz)
		draw_colored_polygon(tri, FG)
		draw_polyline(PackedVector2Array([tri[0], tri[1]]), RIM, 1.2)
	for i in 16:
		var t := i / 15.0
		var c := Vector2(BLAST_X + sin(t * 5.0 + 1.0) * 26.0 + 18.0 * t, ground(BLAST_X) - 60.0 - t * 120.0)
		draw_circle(c, 22.0 + t * 30.0, Color(0.22, 0.1, 0.25, 0.55 - t * 0.3))

func draw_glow(g: Node2D) -> void:
	var prev := shell_at(0.0)
	for i in range(1, 61):
		var p := shell_at(SHELL_T * i / 60.0)
		var k := float(i) / 60.0
		g.draw_line(prev, p, Color(1.0, 0.45, 0.15, 0.55 * k), 2.0 + 14.0 * k * k)
		g.draw_line(prev, p, Color(1.0, 0.85, 0.5, 0.9 * k), 1.0 + 4.0 * k)
		prev = p
	var sp := shell_at(SHELL_T)
	for r in [26.0, 16.0, 9.0]:
		g.draw_circle(sp, r, Color(1.0, 0.55, 0.2, 0.22))
	g.draw_circle(sp, 5.0, Color(1, 1, 0.9, 1))
	var c := Vector2(BLAST_X, ground(BLAST_X) - 8.0)
	for i in 14:
		g.draw_circle(c, 105.0 - i * 6.5, Color(1.0, 0.35, 0.12, 0.045))
	for i in 10:
		var a := rng_f(i, 9) * TAU
		var o := c + Vector2(cos(a), sin(a) * 0.9) * (14.0 + rng_f(i, 10) * 24.0)
		g.draw_circle(o, 16.0 + rng_f(i, 11) * 14.0, Color(1.0, 0.55, 0.15, 0.4))
	g.draw_circle(c, 28, Color(1.0, 0.85, 0.45, 0.7))
	g.draw_circle(c, 15, Color(1.0, 1.0, 0.9, 0.9))
	for i in 26:
		var a := -PI * (0.02 + 0.96 * rng_f(i, 12))
		var l := 30.0 + rng_f(i, 13) * 70.0
		var d := Vector2(cos(a), sin(a))
		g.draw_line(c + d * 20.0, c + d * l, Color(1.0, 0.8, 0.4, 0.9), 1.5)
		g.draw_circle(c + d * l, 2.2, Color(1.0, 0.95, 0.7, 1.0))
	g.draw_circle(Vector2(CRATER_X, ground(CRATER_X) + 4.0), 26.0, Color(1.0, 0.3, 0.1, 0.18))

# ---------- HUD ----------
func _txt(s: String, p: Vector2, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	draw_string(font, p, s, align, w, size, col)

func _bar(p: Vector2, w: float, frac: float, col: Color, mirror := false) -> void:
	draw_line(p, p + Vector2(w, 0), HUD_DIM, 2.0)
	if mirror:
		draw_line(p + Vector2(w, 0), p + Vector2(w * (1.0 - frac), 0), col, 4.0)
	else:
		draw_line(p, p + Vector2(w * frac, 0), col, 4.0)

func _hud() -> void:
	draw_line(Vector2(440, 52), Vector2(840, 52), HUD_DIM, 1.0)
	draw_line(Vector2(440, 100), Vector2(840, 100), HUD_DIM, 1.0)
	_txt("Y O U R   T U R N", Vector2(440, 86), 28, HUD, HORIZONTAL_ALIGNMENT_CENTER, 400)
	_txt("T U R N   0 7", Vector2(440, 122), 13, Color(HUD, 0.6), HORIZONTAL_ALIGNMENT_CENTER, 400)
	_txt("S C O U T", Vector2(40, 46), 13, HUD)
	_bar(Vector2(40, 58), 260, 0.78, RIM)
	_txt("78", Vector2(276, 46), 13, HUD)
	_txt("B R U T E", Vector2(980, 46), 13, HUD, HORIZONTAL_ALIGNMENT_RIGHT, 260)
	_bar(Vector2(980, 58), 260, 0.34, RIM_FOE, true)
	var wc := Vector2(600, 672)
	draw_line(wc + Vector2(-60, 0), wc + Vector2(60, 0), HUD_DIM, 1.0)
	for i in 5:
		var col := HUD if i < 4 else HUD_DIM
		var px := wc.x + 14 + i * 12.0
		draw_line(Vector2(px, wc.y - 5), Vector2(px + 6, wc.y), col, 1.6)
		draw_line(Vector2(px + 6, wc.y), Vector2(px, wc.y + 5), col, 1.6)
	_txt("WIND", wc + Vector2(-60, -8), 12, Color(HUD, 0.6))
	_txt("4", wc + Vector2(-22, 7), 20, HUD)
	var pc := Vector2(PLAYER_X, ground(PLAYER_X) - 42.0)
	draw_arc(pc, 82.0, -PI / 2, 0.0, 40, HUD_DIM, 1.0, true)
	for d in range(0, 91, 10):
		var a := -deg_to_rad(d)
		var l := 7.0 if d % 30 == 0 else 3.5
		draw_line(pc + Vector2(cos(a), sin(a)) * 82.0, pc + Vector2(cos(a), sin(a)) * (82.0 + l), HUD_DIM, 1.0)
	var ta := -deg_to_rad(50)
	draw_line(pc + Vector2(cos(ta), sin(ta)) * 78.0, pc + Vector2(cos(ta), sin(ta)) * 96.0, HOT, 2.0)
	_txt("50°", pc + Vector2(cos(ta), sin(ta)) * 108.0 + Vector2(-4, 4), 15, HUD)
	draw_arc(pc, 118.0, -PI / 2, 0.0, 40, Color(HUD_DIM, 0.18), 1.0, true)
	draw_arc(pc, 118.0, -deg_to_rad(90 * 0.72), 0.0, 40, RIM, 3.0, true)
	_txt("72", pc + Vector2(124, 14), 13, HUD)
