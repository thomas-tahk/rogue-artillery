extends Node2D
# Static mockup: everything is drawn in code. Run with `-- --capture` to save shot.png.

const INK := Color("1d2540")
const W := 1280.0
const H := 720.0
const DIRT := [Color("d98b45"), Color("b86a36"), Color("93502d"), Color("6f3a26")]
const GRASS := Color("62d43c")
const GRASS_HI := Color("9cf06a")
var font: Font = ThemeDB.fallback_font
var ground := PackedVector2Array()

func _ready() -> void:
	for x in range(-10, int(W) + 20, 6):
		ground.append(Vector2(x, surface(x)))
	if "--capture" in OS.get_cmdline_user_args():
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://shot.png")
		get_tree().quit()

func surface(x: float) -> float:
	var y := 505.0 + 28.0 * sin(x * 0.0055 + 1.0) + 14.0 * sin(x * 0.014 + 2.0)
	y -= 85.0 * exp(-pow((x - 250.0) / 120.0, 2.0))
	y -= 30.0 * exp(-pow((x - 1030.0) / 130.0, 2.0))
	y += 62.0 * exp(-pow((x - 800.0) / 52.0, 2.0))
	return y

func _draw() -> void:
	draw_sky()
	draw_hills()
	draw_terrain()
	draw_debris()
	draw_tank(Vector2(250, surface(250) + 2), false, 50.0, Color("2e8cff"), Color("1555c9"))
	draw_tank(Vector2(1000 + 70, surface(1070) + 2), true, 20.0, Color("ff5a4d"), Color("b82a3a"))
	draw_shot()
	draw_explosion(Vector2(905, surface(905) - 6))
	draw_hud()

# ---------- helpers
func ol_poly(pts: PackedVector2Array, col: Color, w := 5.0) -> void:
	draw_colored_polygon(pts, col)
	var c := pts.duplicate()
	c.append(pts[0])
	if w > 0.0:
		draw_polyline(c, INK, w, true)

func ol_circle(p: Vector2, r: float, col: Color, w := 5.0) -> void:
	draw_circle(p, r, INK, true)
	draw_circle(p, r - w, col, true)

func rrect(r: Rect2, rad: float, col: Color, w := 5.0) -> void:
	var pts := PackedVector2Array()
	var cs := [r.position + Vector2(rad, rad), Vector2(r.end.x - rad, r.position.y + rad), r.end - Vector2(rad, rad), Vector2(r.position.x + rad, r.end.y - rad)]
	for i in 4:
		for a in range(0, 7):
			var ang := deg_to_rad(i * 90.0 + 180.0 + a * 15.0)
			pts.append(cs[i] + Vector2(cos(ang), sin(ang)) * rad)
	ol_poly(pts, col, w)

func text_c(s: String, p: Vector2, size: int, col := Color.WHITE, ow := 8) -> void:
	var sz := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size)
	var pos := p + Vector2(-sz.x / 2.0, sz.y * 0.3)
	draw_string_outline(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ow, INK)
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)

# ---------- world
func draw_sky() -> void:
	var top := Color("2b8ff0")
	var bot := Color("c4f0ff")
	for i in 36:
		var t := i / 35.0
		draw_rect(Rect2(0, i * H / 36.0, W, H / 36.0 + 1), top.lerp(bot, pow(t, 0.8)))
	draw_circle(Vector2(1120, 190), 80, Color(1, 0.95, 0.6, 0.35))
	draw_circle(Vector2(1120, 190), 50, Color("fff3a0"))
	for c in [[Vector2(180, 110), 1.1], [Vector2(560, 70), 0.8], [Vector2(780, 190), 1.0], [Vector2(1230, 250), 0.7], [Vector2(420, 250), 0.6]]:
		cloud(c[0], c[1])

func cloud(p: Vector2, s: float) -> void:
	var puffs := [Vector2(-60, 10), Vector2(-25, -14), Vector2(22, -10), Vector2(62, 12), Vector2(0, 14)]
	var rs := [28.0, 38.0, 34.0, 26.0, 34.0]
	for i in 5:
		draw_circle(p + puffs[i] * s, (rs[i] + 4) * s, Color("4a77c4"), true)
	for i in 5:
		draw_circle(p + puffs[i] * s, rs[i] * s, Color.WHITE, true)

func draw_hills() -> void:
	var layers := [[Color("8fd8d2"), 360.0, 70.0, 0.004, 0.5], [Color("6cc9a0"), 410.0, 55.0, 0.006, 2.0], [Color("4fb86f"), 455.0, 40.0, 0.008, 4.0]]
	for L in layers:
		var pts := PackedVector2Array()
		for x in range(0, int(W) + 20, 10):
			pts.append(Vector2(x, L[1] + L[2] * sin(x * L[3] + L[4]) + 15 * sin(x * L[3] * 3.1)))
		var poly := pts.duplicate()
		poly.append(Vector2(W + 20, H))
		poly.append(Vector2(0, H))
		draw_colored_polygon(poly, L[0])
		draw_polyline(pts, L[0].darkened(0.3), 4.0, true)

func draw_terrain() -> void:
	var bottom := PackedVector2Array([Vector2(W + 20, H + 20), Vector2(-10, H + 20)])
	for b in 4:
		var off := 26.0 + b * 62.0
		var top := PackedVector2Array()
		for p in ground:
			top.append(Vector2(p.x, minf(p.y + off - 26.0, H + 10.0)))
		draw_colored_polygon(top + bottom, DIRT[b])
		if b > 0:
			draw_polyline(top, DIRT[b].darkened(0.35), 4.0, true)
	for i in 60:
		var x := fmod(i * 197.3, W)
		var y := 560.0 + fmod(i * 91.7, 150.0)
		if y > surface(x) + 40.0:
			draw_circle(Vector2(x, y), 5 + fmod(i, 4), DIRT[(i + 1) % 4].darkened(0.15))
	var edge := PackedVector2Array()
	var lip := PackedVector2Array()
	var hi := PackedVector2Array()
	for p in ground:
		edge.append(p + Vector2(0, 14))
		lip.append(p + Vector2(0, 9))
		hi.append(p + Vector2(0, 2))
	var sc := PackedVector2Array()
	for x in range(745, 860, 6):
		sc.append(Vector2(x, surface(x) + 14))
	draw_polyline(edge, INK, 36.0, true)
	draw_polyline(sc, Color("3a2430"), 30.0, true)
	draw_polyline(edge, GRASS.darkened(0.2), 28.0, true)
	draw_polyline(lip, GRASS, 18.0, true)
	draw_polyline(hi, GRASS_HI, 5.0, true)
	draw_polyline(sc, Color("3a2430"), 20.0, true)

func draw_debris() -> void:
	var items := [[Vector2(770, 440), 12, 0.3], [Vector2(830, 420), 9, 1.1], [Vector2(790, 385), 7, 2.0], [Vector2(850, 465), 10, 0.7], [Vector2(742, 470), 8, 1.6], [Vector2(700, 430), 8, 2.6]]
	for it in items:
		var pts := PackedVector2Array()
		for k in 5:
			var a: float = it[2] + k * TAU / 5.0
			pts.append(it[0] + Vector2(cos(a), sin(a)) * it[1] * (0.7 + 0.3 * (k % 2)))
		ol_poly(pts, DIRT[int(it[1]) % 3], 3.0)

func draw_tank(base: Vector2, flip: bool, ang: float, col: Color, dark: Color) -> void:
	var rot := atan2(surface(base.x + 30) - surface(base.x - 30), 60.0) * 0.9
	var xf_scale := Vector2(-1.35 if flip else 1.35, 1.35)
	base += Vector2(0, 5)
	draw_set_transform(base + Vector2(0, 0), 0, Vector2.ONE)
	draw_set_transform(base + Vector2(0, 8), 0, Vector2(1, 0.22))
	draw_circle(Vector2.ZERO, 62, Color(0, 0, 0, 0.25))
	draw_set_transform(base, rot, xf_scale)
	var enemy := flip
	var pivot := Vector2(0, -52)
	var blen := 52.0 if enemy else 66.0
	var bw := 20.0 if enemy else 15.0
	var d := Vector2.from_angle(-deg_to_rad(ang))
	var nn := d.orthogonal() * bw / 2.0
	ol_poly(PackedVector2Array([pivot + nn, pivot + d * blen + nn, pivot + d * blen - nn, pivot - nn]), Color("5b6788"), 5)
	var tip := d * (blen - 4)
	ol_poly(PackedVector2Array([pivot + tip + nn * 1.35, pivot + tip + d * 14 + nn * 1.35, pivot + tip + d * 14 - nn * 1.35, pivot + tip - nn * 1.35]), Color("8a96b8"), 5)
	if enemy:
		rrect(Rect2(-52, -50, 104, 36), 12, col)
		rrect(Rect2(-30, -80, 60, 38), 10, dark)
		draw_rect(Rect2(-22, -70, 44, 10), Color("ffe36b"))
		draw_rect(Rect2(-22, -70, 44, 10), INK, false, 3)
		for sx in [-40, 40]:
			draw_circle(Vector2(sx, -32), 4, Color("ffe36b"))
	else:
		rrect(Rect2(-56, -40, 112, 34), 16, col)
		var dome := PackedVector2Array()
		for a in range(180, 361, 15):
			dome.append(Vector2(cos(deg_to_rad(a)) * 28, -40 + sin(deg_to_rad(a)) * 30))
		ol_poly(dome, dark)
		draw_circle(Vector2(0, -52), 7, Color("ffe36b"))
		draw_arc(Vector2(0, -52), 7, 0, TAU, 20, INK, 3)
		draw_rect(Rect2(-44, -26, 88, 6), Color(1, 1, 1, 0.35))
	for wx in [-38, -13, 13, 38]:
		ol_circle(Vector2(wx, -9), 15 if absi(wx) > 20 else 13, Color("3a4466"), 5)
		draw_circle(Vector2(wx, -9), 5, Color("ffd34a"))
		draw_arc(Vector2(wx, -9), 5, 0, TAU, 12, INK, 2)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func shell_pos(t: float) -> Vector2:
	var a := Vector2(300, 440)
	var b := Vector2(905, 480)
	return Vector2(lerpf(a.x, b.x, t), lerpf(a.y, b.y, t) - 330.0 * 4.0 * t * (1.0 - t))

func draw_shot() -> void:
	var t_now := 0.42
	for i in 22:
		var t := t_now - i * 0.016
		if t < 0:
			break
		var f := 1.0 - i / 22.0
		draw_circle(shell_pos(t), 4 + 9 * f, Color(1, 1, 1, 0.75 * f))
	var p := shell_pos(t_now)
	draw_circle(p, 22, Color(1, 0.85, 0.3, 0.35))
	ol_circle(p, 12, Color("ffcf33"), 4)
	draw_circle(p + Vector2(-3, -4), 3.5, Color.WHITE)

func draw_explosion(at: Vector2) -> void:
	draw_set_transform(at, 0, Vector2(0.78, 0.78))
	explosion_body(Vector2.ZERO)
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)

func explosion_body(p: Vector2) -> void:
	for s in [[Vector2(-30, -120), 42], [Vector2(25, -150), 36], [Vector2(-60, -80), 30], [Vector2(55, -95), 34]]:
		ol_circle(p + s[0], s[1], Color("7c7f99"), 4)
		draw_circle(p + s[0] + Vector2(-8, -8), s[1] * 0.5, Color("a0a4bd"))
	for k in 12:
		var a := -PI + k * PI / 11.0
		var r := 88.0 if k % 2 == 0 else 56.0
		draw_line(p, p + Vector2(cos(a), sin(a)) * (r + 40), INK, 14, true)
		draw_line(p, p + Vector2(cos(a), sin(a)) * (r + 34), Color("ff9c1a"), 8, true)
	ol_circle(p + Vector2(0, -20), 66, Color("ff8a1f"), 5)
	draw_circle(p + Vector2(0, -24), 46, Color("ffc933"))
	draw_circle(p + Vector2(0, -26), 26, Color("fff6c2"))
	for k in 8:
		var q := p + Vector2(cos(-PI + k * 0.44), sin(-PI + k * 0.44)) * (95 + 12 * (k % 3))
		ol_circle(q, 7, Color("ffd34a"), 3)

# ---------- HUD
func panel(r: Rect2, col := Color("27335c")) -> void:
	rrect(Rect2(r.position + Vector2(0, 5), r.size), 16, Color(0, 0, 0, 0.3), 0)
	rrect(r, 16, col, 5)
	draw_rect(Rect2(r.position + Vector2(14, 8), Vector2(r.size.x - 28, 3)), Color(1, 1, 1, 0.25))

func hp_bar(r: Rect2, frac: float, col: Color, label: String, hp: String) -> void:
	panel(r)
	text_c(label, Vector2(r.position.x + 70, r.position.y + 24), 22, Color("ffe36b"), 6)
	text_c(hp, Vector2(r.end.x - 60, r.position.y + 24), 22, Color.WHITE, 6)
	var bar := Rect2(r.position + Vector2(16, 42), Vector2(r.size.x - 32, 22))
	rrect(bar, 10, Color("111833"), 4)
	rrect(Rect2(bar.position + Vector2(3, 3), Vector2((bar.size.x - 6) * frac, bar.size.y - 6)), 7, col, 0)
	draw_rect(Rect2(bar.position + Vector2(10, 6), Vector2((bar.size.x - 20) * frac, 4)), Color(1, 1, 1, 0.4))

func draw_hud() -> void:
	hp_bar(Rect2(24, 20, 270, 74), 0.82, Color("4be07a"), "PLAYER", "82/100")
	hp_bar(Rect2(986, 20, 270, 74), 0.38, Color("ff5a4d"), "BRUISER", "38/100")
	rrect(Rect2(500, 14, 280, 62), 24, Color("ffb524"), 6)
	draw_rect(Rect2(520, 22, 240, 4), Color(1, 1, 1, 0.5))
	text_c("YOUR TURN", Vector2(640, 44), 36, Color.WHITE, 10)
	panel(Rect2(555, 86, 170, 36))
	text_c("TURN 7", Vector2(640, 104), 22, Color("ffe36b"), 6)
	panel(Rect2(520, 628, 240, 72))
	text_c("WIND", Vector2(580, 648), 20, Color("9fb4ff"), 6)
	for i in 6:
		rrect(Rect2(615 + i * 22, 638, 16, 22), 5, Color("5fd0ff") if i < 4 else Color("3a4670"), 3)
	var ar := PackedVector2Array([Vector2(550, 676), Vector2(690, 676), Vector2(690, 668), Vector2(722, 682), Vector2(690, 696), Vector2(690, 688), Vector2(550, 688)])
	draw_colored_polygon(ar, Color("5fd0ff"))
	text_c("4", Vector2(536, 682), 26, Color.WHITE, 8)
	var c := Vector2(250, surface(250) - 68)
	draw_arc(c, 125, -deg_to_rad(90), 0, 32, INK, 18, true)
	draw_arc(c, 125, -deg_to_rad(90), 0, 32, Color("1b2a55"), 11, true)
	draw_arc(c, 125, -deg_to_rad(50), 0, 24, Color("ffe36b"), 11, true)
	for a in [0, 30, 60, 90]:
		var d := Vector2.from_angle(-deg_to_rad(a))
		draw_line(c + d * 115, c + d * 137, INK, 4)
	text_c("50°", c + Vector2.from_angle(-deg_to_rad(50)) * 165, 28, Color("ffe36b"), 8)
	var pr := Rect2(c.x - 80, c.y + 88, 160, 24)
	rrect(pr, 11, Color("111833"), 5)
	rrect(Rect2(pr.position + Vector2(4, 4), Vector2(152 * 0.72, 16)), 7, Color("ff8a1f"), 0)
	text_c("POWER 72", pr.get_center(), 18, Color.WHITE, 6)
