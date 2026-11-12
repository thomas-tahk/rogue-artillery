extends Node2D
# Papercraft diorama mockup: everything is built in code from jittered polygons.

const INK := Color("3b2a20")
const CREAM := Color("fbf1dc")
const GRASS := Color("5aa845")
const GRASS_D := Color("3f8a3a")
const SOIL := Color("a05f3a")
const SOIL_D := Color("7a4429")
const TEAL := Color("1f93a8")
const TEAL_D := Color("12687a")
const RED := Color("e0472f")
const RED_D := Color("a82c1e")
const MUSTARD := Color("f4b632")
const ORANGE := Color("f08a2e")
const FONT_NAME := ["Marker Felt", "Chalkboard SE", "Comic Sans MS"]

var rng := RandomNumberGenerator.new()
var font: Font

func _ready() -> void:
	rng.seed = 7
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(FONT_NAME)
	sf.font_weight = 700
	font = sf
	_build_sky()
	_build_hills()
	_build_terrain()
	_build_debris()
	_build_trail()
	_build_explosion()
	_tank(Vector2(256, surf(256)), TEAL, TEAL_D, 1, false, -50.0)
	_tank(Vector2(1000, surf(1000)), RED, RED_D, -1, true, -38.0)
	_build_hud()
	_build_grain()
	if "--capture" in OS.get_cmdline_user_args():
		for i in 30:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://shot.png")
		get_tree().quit()

# ---------- terrain function ----------
func surf(x: float) -> float:
	var y := 500.0 + 30.0 * sin(x * 0.0055 + 1.0) + 16.0 * sin(x * 0.013 + 2.0)
	y -= 55.0 * exp(-pow((x - 256.0) / 120.0, 2))
	y -= 25.0 * exp(-pow((x - 1100.0) / 140.0, 2))
	y += 52.0 * exp(-pow((x - 895.0) / 46.0, 2))
	return y

# ---------- helpers ----------
func _poly(parent: Node, pts: PackedVector2Array, col: Color, off := Vector2.ZERO) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	p.position = off
	parent.add_child(p)
	return p

func _shadow(parent: Node, pts: PackedVector2Array, depth := 5.0) -> void:
	for i in 3:
		var k := (i + 1) / 3.0
		_poly(parent, pts, Color(0.2, 0.1, 0.02, 0.10), Vector2(1.0, 1.5) * depth * k + Vector2(0, 1))

func _edge(parent: Node, pts: PackedVector2Array, col: Color, w := 2.0, closed := true) -> void:
	var l := Line2D.new()
	l.points = pts
	l.closed = closed
	l.width = w
	l.default_color = col
	l.joint_mode = Line2D.LINE_JOINT_ROUND
	parent.add_child(l)

func _jitter(pts: PackedVector2Array, amt: float) -> PackedVector2Array:
	var o := PackedVector2Array()
	for p in pts:
		o.append(p + Vector2(rng.randf_range(-amt, amt), rng.randf_range(-amt, amt)))
	return o

func _piece(parent: Node, pts: PackedVector2Array, col: Color, depth := 4.0, jit := 0.0) -> void:
	if jit > 0.0:
		pts = _jitter(pts, jit)
	if depth > 0.0:
		_shadow(parent, pts, depth)
	_poly(parent, pts, col)
	_edge(parent, pts, col.lightened(0.28), 1.5)

func _circle(c: Vector2, r: float, n := 20, jit := 0.0) -> PackedVector2Array:
	var o := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		o.append(c + Vector2(cos(a), sin(a)) * (r + rng.randf_range(-jit, jit)))
	return o

func _label(parent: Node, text: String, pos: Vector2, size: int, col := INK) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	parent.add_child(l)
	return l

# ---------- scenery ----------
func _build_sky() -> void:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("f7c98f"), Color("fbe3b8"), Color("fbf1dc")])
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	t.width = 8
	t.height = 256
	var s := Sprite2D.new()
	s.texture = t
	s.centered = false
	s.scale = Vector2(160, 720.0 / 256.0)
	add_child(s)
	var sun := Node2D.new()
	add_child(sun)
	for r in [118.0, 92.0, 66.0]:
		var c := Color("f9a45a") if r > 100 else (Color("f6bf5c") if r > 80 else Color("fbe08a"))
		_piece(sun, _circle(Vector2(640, 250), r, 40, 1.5), c, 3.0)
	for c in [Vector2(120, 150), Vector2(470, 90), Vector2(1010, 190), Vector2(1190, 100)]:
		_cloud(c)

func _cloud(c: Vector2) -> void:
	var n := Node2D.new()
	add_child(n)
	var pts := PackedVector2Array()
	for i in 24:
		var a := PI + PI * i / 23.0
		var bump := 1.0 + 0.35 * sin(a * 7.0)
		pts.append(c + Vector2(cos(a) * 70.0, sin(a) * 34.0 * bump))
	pts.append(c + Vector2(70, 8))
	pts.append(c + Vector2(-70, 8))
	_piece(n, pts, Color("fffaf0"), 5.0, 1.0)

func _ridge(base: float, amp: float, ph: float, freq: float, col: Color, depth: float) -> void:
	var n := Node2D.new()
	add_child(n)
	var pts := PackedVector2Array()
	var x := -10.0
	while x <= 1290.0:
		pts.append(Vector2(x, base + amp * sin(x * freq + ph) + amp * 0.4 * sin(x * freq * 2.7 + ph * 2.0) + rng.randf_range(-1.2, 1.2)))
		x += 14.0
	var top := pts.duplicate()
	pts.append(Vector2(1290, 730))
	pts.append(Vector2(-10, 730))
	_shadow(n, pts, depth)
	_poly(n, pts, col)
	_edge(n, top, col.lightened(0.3), 2.0, false)

func _build_hills() -> void:
	_ridge(330, 38, 0.5, 0.0045, Color("e9a38f"), 8.0)
	_ridge(395, 34, 2.0, 0.0062, Color("c97e7a"), 9.0)
	_ridge(450, 26, 4.1, 0.0075, Color("9c6a76"), 10.0)

func _curve(x0: float, x1: float, dy := 0.0, step := 6.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var x := x0
	while x < x1:
		pts.append(Vector2(x, surf(x) + dy + rng.randf_range(-0.9, 0.9)))
		x += step
	pts.append(Vector2(x1, surf(x1) + dy))
	return pts

func _band(x0: float, x1: float, top: float, bot: float) -> PackedVector2Array:
	var a := _curve(x0, x1, top)
	var b := _curve(x0, x1, bot)
	b.reverse()
	a.append_array(b)
	return a

func _build_terrain() -> void:
	var t := Node2D.new()
	add_child(t)
	var soil := _curve(-10, 1290, 0.0)
	soil.append(Vector2(1290, 730))
	soil.append(Vector2(-10, 730))
	_shadow(t, soil, 9.0)
	_poly(t, soil, SOIL)
	for i in 3:
		var strata := _curve(-10, 1290, 46.0 + i * 38.0)
		var top := strata.duplicate()
		strata.append(Vector2(1290, 730))
		strata.append(Vector2(-10, 730))
		_shadow(t, strata, 4.0)
		_poly(t, strata, SOIL.lerp(SOIL_D, 0.3 + i * 0.3))
		_edge(t, top, SOIL.lightened(0.15), 1.5, false)
	for i in 26:
		var x := rng.randf_range(10, 1270)
		var y := surf(x) + rng.randf_range(60, 190)
		_piece(t, _circle(Vector2(x, y), rng.randf_range(4, 9), 7, 2.0), SOIL_D.lerp(CREAM, rng.randf_range(0.05, 0.3)), 2.0)
	var cx0 := 840.0
	var cx1 := 950.0
	_poly(t, _band(cx0, cx1, -2.0, 12.0), Color("5b321f"))
	_poly(t, _band(cx0 + 8, cx1 - 8, 12.0, 26.0), Color("3d2114"))
	for seg in [[-10.0, cx0], [cx1, 1290.0]]:
		var gb := _band(seg[0], seg[1], -3.0, 15.0)
		_shadow(t, gb, 4.0)
		_poly(t, gb, GRASS_D)
		_poly(t, _band(seg[0], seg[1], -6.0, 8.0), GRASS)
		_edge(t, _curve(seg[0], seg[1], -6.0), GRASS.lightened(0.35), 2.0, false)
	for i in 70:
		var x := rng.randf_range(0, 1280)
		if x > cx0 - 6 and x < cx1 + 6:
			continue
		var y := surf(x) - 5.0
		var h := rng.randf_range(8, 15)
		_poly(t, PackedVector2Array([Vector2(x - 4, y), Vector2(x + rng.randf_range(-3, 3), y - h), Vector2(x + 4, y)]), GRASS.lerp(GRASS_D, rng.randf()))

func _build_debris() -> void:
	var d := Node2D.new()
	add_child(d)
	for i in 22:
		var a := rng.randf_range(-PI * 0.95, -PI * 0.05)
		var dist := rng.randf_range(30, 120)
		var n := Node2D.new()
		n.position = Vector2(895, surf(895) - 10) + Vector2(cos(a), sin(a)) * dist * Vector2(1.0, 1.1)
		n.rotation = rng.randf() * TAU
		d.add_child(n)
		var s := rng.randf_range(4, 10)
		var col: Color = [SOIL, SOIL_D, GRASS_D, GRASS][rng.randi() % 4]
		_piece(n, _jitter(PackedVector2Array([Vector2(-s, -s * 0.7), Vector2(s, -s * 0.5), Vector2(s * 0.8, s * 0.8), Vector2(-s * 0.6, s)]), 1.5), col, 3.0)

func _build_trail() -> void:
	var t := Node2D.new()
	add_child(t)
	var p0 := Vector2(326, 346)
	var p1 := Vector2(1125, 450)
	var apex := Vector2(700, 60)
	var pts: Array[Vector2] = []
	for i in 61:
		var u := i / 60.0
		pts.append(p0.lerp(p1, u) + (apex - p0.lerp(p1, 0.5)) * 4.0 * u * (1.0 - u))
	var upto := 46
	var i := 0
	while i < upto:
		var seg := PackedVector2Array()
		var sh := PackedVector2Array()
		for k in range(i, min(i + 2, upto) + 1):
			var q: Vector2 = pts[k] + Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
			seg.append(q)
			sh.append(q + Vector2(2, 3))
		_edge(t, sh, Color(0.2, 0.1, 0.02, 0.2), 6.0, false)
		_edge(t, seg, INK, 4.0, false)
		i += 4
	var tip: Vector2 = pts[upto]
	var dir: Vector2 = (pts[upto] - pts[upto - 1]).normalized()
	_piece(t, _circle(tip, 11, 16, 0.6), INK.lightened(0.1), 5.0)
	_poly(t, _circle(tip + Vector2(-3, -3), 4, 10), Color("8a6a55"))
	for k in 3:
		var back: Vector2 = tip - dir * (22 + k * 10) + Vector2(0, (k - 1) * 8)
		_edge(t, PackedVector2Array([back, back - dir * 10]), MUSTARD, 3.0, false)

func _build_explosion() -> void:
	var ex := Node2D.new()
	ex.position = Vector2(1130, 440)
	ex.scale = Vector2(0.85, 0.85)
	add_child(ex)
	for i in 14:
		var c := Vector2(rng.randf_range(-70, 70), rng.randf_range(-95, 10))
		var r := rng.randf_range(20, 36)
		_piece(ex, _circle(c, r, 18, 2.5), Color("f4ede0").lerp(Color("b9a89a"), rng.randf() * 0.5), 5.0)
	for layer in [[92.0, RED], [72.0, ORANGE], [50.0, MUSTARD], [28.0, Color("fff3c4")]]:
		var pts := PackedVector2Array()
		for i in 24:
			var a := TAU * i / 24.0 + (0.2 if layer[0] < 60 else 0.0)
			var rr: float = layer[0] * (1.0 if i % 2 == 0 else 0.55) * rng.randf_range(0.85, 1.1)
			pts.append(Vector2(cos(a), sin(a)) * rr)
		_piece(ex, pts, layer[1], 3.0)
	var cols := [TEAL, RED, MUSTARD, GRASS, ORANGE, CREAM]
	for i in 46:
		var a := rng.randf() * TAU
		var n := Node2D.new()
		n.position = Vector2(cos(a), sin(a) * 0.9) * rng.randf_range(80, 190)
		n.rotation = rng.randf() * TAU
		ex.add_child(n)
		var w := rng.randf_range(4, 8)
		var h := rng.randf_range(7, 14)
		_piece(n, PackedVector2Array([Vector2(-w, -h), Vector2(w, -h), Vector2(w, h), Vector2(-w, h)]), cols[rng.randi() % cols.size()], 2.5)

# ---------- tanks ----------
func _tank(pos: Vector2, col: Color, dark: Color, facing: int, enemy: bool, barrel_deg: float) -> Node2D:
	var t := Node2D.new()
	t.position = pos + Vector2(0, 4)
	t.scale = Vector2(1.4, 1.4)
	t.rotation = atan2(surf(pos.x + 20) - surf(pos.x - 20), 40.0)
	add_child(t)
	var f := Node2D.new()
	f.scale.x = facing
	t.add_child(f)
	_shadow(f, PackedVector2Array([Vector2(-50, 0), Vector2(50, 0), Vector2(52, -20), Vector2(-52, -20)]), 7.0)
	var bar := Node2D.new()
	bar.position = Vector2(8 if not enemy else 4, -44)
	bar.rotation_degrees = barrel_deg
	f.add_child(bar)
	var bl := 52.0
	_piece(bar, PackedVector2Array([Vector2(0, -6), Vector2(bl, -5), Vector2(bl, 5), Vector2(0, 6)]), dark, 3.0)
	_piece(bar, PackedVector2Array([Vector2(bl - 3, -8), Vector2(bl + 8, -8), Vector2(bl + 8, 8), Vector2(bl - 3, 8)]), col.lightened(0.15), 2.0)
	_edge(bar, PackedVector2Array([Vector2(18, -5.5), Vector2(18, 5.5)]), dark.darkened(0.3), 1.5, false)
	var hull: PackedVector2Array
	if enemy:
		hull = PackedVector2Array([Vector2(-44, -18), Vector2(44, -18), Vector2(40, -50), Vector2(24, -58), Vector2(-24, -58), Vector2(-40, -50)])
	else:
		hull = PackedVector2Array([Vector2(-46, -18), Vector2(46, -18), Vector2(36, -38), Vector2(-36, -38)])
	_piece(f, hull, col, 5.0)
	_edge(f, PackedVector2Array([Vector2(-44, -28), Vector2(44, -28)]), dark, 1.5, false)
	if enemy:
		_edge(f, PackedVector2Array([Vector2(-24, -58), Vector2(-40, -18)]), dark.lightened(0.1), 1.5, false)
		_edge(f, PackedVector2Array([Vector2(24, -58), Vector2(40, -18)]), dark.lightened(0.1), 1.5, false)
		_piece(f, PackedVector2Array([Vector2(-18, -58), Vector2(-10, -76), Vector2(-2, -58), Vector2(6, -80), Vector2(14, -58)]), MUSTARD, 3.0)
		_piece(f, _circle(Vector2(-8, -42), 7.0, 12), CREAM, 0.0)
		_poly(f, _circle(Vector2(-10, -42), 3.2, 8), INK)
	else:
		_edge(f, PackedVector2Array([Vector2(-36, -38), Vector2(-20, -18)]), dark, 1.5, false)
		_edge(f, PackedVector2Array([Vector2(36, -38), Vector2(20, -18)]), dark, 1.5, false)
		var dome := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			dome.append(Vector2(cos(a) * 24.0, sin(a) * 20.0 - 38.0))
		_piece(f, dome, col.lightened(0.12), 4.0)
		_edge(f, PackedVector2Array([Vector2(0, -58), Vector2(0, -38)]), dark, 1.5, false)
		_piece(f, _circle(Vector2(-10, -50), 4.5, 10), MUSTARD, 0.0)
	# tracks in front of hull
	_piece(f, PackedVector2Array([Vector2(-48, 0), Vector2(48, 0), Vector2(52, -10), Vector2(48, -20), Vector2(-48, -20), Vector2(-52, -10)]), INK.lightened(0.12), 0.0)
	for i in 5:
		_piece(f, _circle(Vector2(-34 + i * 17, -10), 8.0, 14), CREAM if i % 2 else MUSTARD.lerp(CREAM, 0.2), 0.0)
		_poly(f, _circle(Vector2(-34 + i * 17, -10), 2.5, 8), INK)
	return t

# ---------- HUD ----------
func _strip(parent: Node, rect: Rect2, col: Color, tilt := 0.0) -> Node2D:
	var n := Node2D.new()
	n.position = rect.position
	n.rotation_degrees = tilt
	parent.add_child(n)
	var w := rect.size.x
	var h := rect.size.y
	var pts := PackedVector2Array()
	var x := 0.0
	while x < w - 5.0:
		pts.append(Vector2(x, rng.randf_range(-2.0, 2.0)))
		x += 9.0
	pts.append(Vector2(w, rng.randf_range(-2, 2)))
	pts.append(Vector2(w + rng.randf_range(-2, 2), h))
	x = w - 9.0
	while x > 5.0:
		pts.append(Vector2(x, h + rng.randf_range(-2.0, 2.0)))
		x -= 9.0
	pts.append(Vector2(0, h))
	_piece(n, pts, col, 5.0)
	return n

func _tape(parent: Node, pos: Vector2, deg: float) -> void:
	var n := Node2D.new()
	n.position = pos
	n.rotation_degrees = deg
	parent.add_child(n)
	var pts := PackedVector2Array([Vector2(-26, -9), Vector2(26, -9), Vector2(23, -4), Vector2(26, 0), Vector2(23, 5), Vector2(26, 9), Vector2(-26, 9), Vector2(-23, 4), Vector2(-26, 0), Vector2(-23, -5)])
	_poly(n, pts, Color(1.0, 0.86, 0.4, 0.82))
	_edge(n, pts, Color(1, 0.93, 0.6, 0.9), 1.0)

func _bar(card: Node, x0: float, y0: float, w: float, h: float, frac: float, col: Color) -> void:
	_poly(card, PackedVector2Array([Vector2(x0, y0), Vector2(x0 + w, y0), Vector2(x0 + w, y0 + h), Vector2(x0, y0 + h)]), Color("d9c8a6"))
	_poly(card, PackedVector2Array([Vector2(x0, y0), Vector2(x0 + w * frac, y0), Vector2(x0 + w * frac, y0 + h), Vector2(x0, y0 + h)]), col)
	_edge(card, PackedVector2Array([Vector2(x0, y0 + h * 0.5), Vector2(x0 + w * frac, y0 + h * 0.5)]), col.lightened(0.3), 2.0, false)

func _hp_card(pos: Vector2, title: String, frac: float, col: Color, tilt: float) -> void:
	var h := Node2D.new()
	add_child(h)
	var card := _strip(h, Rect2(pos, Vector2(250, 62)), CREAM, tilt)
	_label(card, title, Vector2(14, 5), 22)
	_bar(card, 14, 36, 222, 16, frac, col)
	_tape(h, pos + Vector2(125, -2), tilt * 2.0 + 3.0)

func _build_hud() -> void:
	var hud := Node2D.new()
	add_child(hud)
	_hp_card(Vector2(24, 20), "YOU  72/100", 0.72, TEAL, -1.5)
	_hp_card(Vector2(1006, 20), "GRUNT  38/100", 0.38, RED, 1.2)
	var b := _strip(hud, Rect2(Vector2(480, 22), Vector2(320, 64)), MUSTARD, -1.0)
	var lb := _label(b, "YOUR TURN", Vector2(0, 4), 40)
	lb.size = Vector2(320, 56)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tape(hud, Vector2(500, 24), -28.0)
	_tape(hud, Vector2(780, 22), 24.0)
	var tg := _strip(hud, Rect2(Vector2(560, 100), Vector2(160, 34)), CREAM, 1.5)
	var tl := _label(tg, "TURN 7", Vector2(0, 0), 22)
	tl.size = Vector2(160, 34)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var w := _strip(hud, Rect2(Vector2(24, 100), Vector2(190, 78)), CREAM, 1.2)
	_label(w, "WIND  4", Vector2(12, 0), 20)
	var arrow := PackedVector2Array([Vector2(16, 48), Vector2(100, 48), Vector2(100, 36), Vector2(130, 56), Vector2(100, 74), Vector2(100, 62), Vector2(16, 62)])
	_poly(w, arrow, TEAL)
	_edge(w, arrow, TEAL.lightened(0.3), 1.5)
	for i in 4:
		_poly(w, _circle(Vector2(150 + (i % 2) * 18, 44 + (i / 2) * 18), 6.0, 10), MUSTARD)
	# gauge attached to the player tank
	var g := Node2D.new()
	g.position = Vector2(267, surf(256) - 62)
	add_child(g)
	var fan := PackedVector2Array([Vector2.ZERO])
	for i in 15:
		var a := deg_to_rad(-70.0 + i * (70.0 / 14.0))
		fan.append(Vector2(cos(a), sin(a)) * 120.0)
	_poly(g, fan, Color(1.0, 0.95, 0.8, 0.30))
	_edge(g, fan.slice(1), CREAM, 2.0, false)
	for d in [0, 15, 30, 45, 60]:
		var a := deg_to_rad(-d)
		_edge(g, PackedVector2Array([Vector2(cos(a), sin(a)) * 112.0, Vector2(cos(a), sin(a)) * 126.0]), INK, 2.0, false)
	var ar := deg_to_rad(-50.0)
	_edge(g, PackedVector2Array([Vector2.ZERO, Vector2(cos(ar), sin(ar)) * 120.0]), RED, 3.0, false)
	var lab := _strip(g, Rect2(Vector2(128, -96), Vector2(76, 32)), CREAM, -3.0)
	_label(lab, "50°", Vector2(14, -1), 24)
	var pb := _strip(g, Rect2(Vector2(-110, 96), Vector2(140, 34)), CREAM, 0.0)
	_label(pb, "PWR", Vector2(8, -6), 14)
	_bar(pb, 8, 18, 124, 10, 0.68, ORANGE)

func _build_grain() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 10
	add_child(cl)
	var n1 := FastNoiseLite.new()
	n1.frequency = 0.35
	n1.seed = 3
	var n2 := FastNoiseLite.new()
	n2.frequency = 0.05
	n2.seed = 9
	var m := ShaderMaterial.new()
	m.shader = load("res://grain.gdshader")
	m.set_shader_parameter("noise", ImageTexture.create_from_image(n1.get_image(256, 256)))
	m.set_shader_parameter("fibre", ImageTexture.create_from_image(n2.get_image(256, 256)))
	var r := ColorRect.new()
	r.size = Vector2(1280, 720)
	r.material = m
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(r)
