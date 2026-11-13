extends Node2D
# Builds the layer stack (code-drawn art + real CPUParticles2D) and handles `-- --capture [--closeup]`.

const Art := preload("res://art.gd")
var closeup := false
var frozen: Array[CPUParticles2D] = []
var tex_soft: Texture2D
var tex_puff: Texture2D
var tex_chunk: Texture2D
var tex_leaf: Texture2D

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	closeup = "--closeup" in args
	if closeup:
		Art.player_x = 470.0
		Art.enemy_x = 810.0
		Art.crater_x = -1.0
		Art.player_ang = 34.0
		Art.enemy_ang = 24.0
	tex_soft = soft_tex()
	tex_puff = toon_puff_tex()
	tex_chunk = poly_tex(PackedVector2Array([Vector2(2, 8), Vector2(7, 1), Vector2(15, 3), Vector2(18, 11), Vector2(10, 17), Vector2(3, 15)]), 20, Color("c9824a"), Color("2a1838"))
	tex_leaf = poly_tex(PackedVector2Array([Vector2(1, 8), Vector2(7, 2), Vector2(15, 3), Vector2(19, 8), Vector2(14, 14), Vector2(6, 14)]), 20, Color.WHITE, Color("5a3a20"))
	build()
	if "--capture" in args:
		for i in 6:
			await get_tree().process_frame
		for p in frozen:
			p.speed_scale = 0.0
		for i in 4:
			await get_tree().process_frame
		get_viewport().get_texture().get_image().save_png("res://shot2.png" if closeup else "res://shot.png")
		get_tree().quit()

# ------------------------------------------------------------ layers
func layer(kind: String, parent: Node = self, additive := false) -> Node2D:
	var n := Art.new()
	n.kind = kind
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		n.material = m
	parent.add_child(n)
	return n

func build() -> void:
	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	if closeup:
		cam.position = Vector2(642, 420)
		cam.zoom = Vector2(2.0, 2.0)
	add_child(cam)
	for k in ["sky", "far", "mid", "hills"]:
		layer(k)
	add_ambient_far()
	layer("terrain")
	add_dust()
	layer("tanks")
	add_enemy_smoke()
	if not closeup:
		add_trail()
		layer("shell")
		add_explosion()
		layer("flash", self, true)
	layer("foreground")
	layer("rays", self, true)
	layer("grade")
	add_ambient_near()
	if not closeup:
		var cl := CanvasLayer.new()
		add_child(cl)
		layer("hud", cl)
	else:
		var cl := CanvasLayer.new()
		add_child(cl)

# ------------------------------------------------------------ particle helpers
func emitter(pos: Vector2, tex: Texture2D, amount: int, life: float, o: Dictionary, additive := false, freeze := true) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.position = pos
	p.texture = tex
	p.amount = amount
	p.lifetime = life
	p.local_coords = false
	for k in o:
		p.set(k, o[k])
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		p.material = m
	add_child(p)
	if freeze:
		frozen.append(p)
	return p

func ramp(cols: Array, offs: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offs)
	g.colors = PackedColorArray(cols)
	return g

func curve(a: float, b: float, mid := -1.0) -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0, a))
	if mid >= 0.0:
		c.add_point(Vector2(0.4, mid))
	c.add_point(Vector2(1, b))
	return c

# ------------------------------------------------------------ textures
func soft_tex() -> Texture2D:
	var t := GradientTexture2D.new()
	t.width = 64
	t.height = 64
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(0.5, 0.0)
	t.gradient = ramp([Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)], [0.0, 0.45, 1.0])
	return t

# Cartoon smoke puff: ink outline, lit side toward the sun (up-right), cool shadow crescent.
func toon_puff_tex() -> Texture2D:
	var n := 128
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var c := Vector2(63.5, 63.5)
	var R := 60.0
	var hc := c + Vector2(9, -9)
	for y in n:
		for x in n:
			var p := Vector2(x, y)
			var dist := p.distance_to(c)
			var a := clampf(R - dist + 0.5, 0.0, 1.0)
			if a <= 0.0:
				continue
			var v := 1.0
			if p.distance_to(hc) > R - 6.0:
				v = 0.62
			if dist > R - 5.0:
				v = 0.2
			img.set_pixel(x, y, Color(v, v, v, a))
	return ImageTexture.create_from_image(img)

func poly_tex(pts: PackedVector2Array, n: int, fillc: Color, edge: Color) -> Texture2D:
	var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var cen := Vector2(10, 9)
	var inner := PackedVector2Array()
	for p in pts:
		inner.append(cen + (p - cen) * 0.72)
	for y in n:
		for x in n:
			var q := Vector2(x + 0.5, y + 0.5)
			if Geometry2D.is_point_in_polygon(q, inner):
				var lit := 1.0 if (q.x - q.y) > 1.0 else 0.8
				img.set_pixel(x, y, Color(fillc.r * lit, fillc.g * lit, fillc.b * lit, 1))
			elif Geometry2D.is_point_in_polygon(q, pts):
				img.set_pixel(x, y, edge)
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------ effects
func add_explosion() -> void:
	var e := Art.boom_world()
	var wind := Vector2(26, -34)
	# rising smoke columns with outlined puffs
	emitter(e + Vector2(0, -20), tex_puff, 26, 3.4, {
		"direction": Vector2(0, -1), "spread": 55.0, "initial_velocity_min": 40.0, "initial_velocity_max": 140.0,
		"gravity": Vector2(10, -30), "damping_min": 30.0, "damping_max": 60.0, "scale_amount_min": 0.3, "scale_amount_max": 0.6,
		"scale_amount_curve": curve(0.4, 1.4), "explosiveness": 0.55, "preprocess": 1.5,
		"color_ramp": ramp([Color(0.5, 0.3, 0.5, 0.0), Color(0.55, 0.38, 0.55, 1.0), Color(0.42, 0.3, 0.6, 0.9), Color(0.4, 0.3, 0.62, 0.0)], [0.0, 0.1, 0.65, 1.0])})
	# dust ring on the ground
	emitter(e + Vector2(0, 6), tex_puff, 12, 2.0, {
		"direction": Vector2(1, -0.2), "spread": 180.0, "initial_velocity_min": 60.0, "initial_velocity_max": 190.0,
		"gravity": Vector2(0, 0), "damping_min": 70.0, "damping_max": 120.0, "scale_amount_min": 0.3, "scale_amount_max": 0.55,
		"scale_amount_curve": curve(0.5, 1.2), "explosiveness": 0.9, "preprocess": 0.6,
		"color_ramp": ramp([Color(1, 0.85, 0.7, 0.0), Color(1.0, 0.78, 0.6, 0.95), Color(0.9, 0.6, 0.55, 0.0)], [0.0, 0.1, 1.0])})
	# fireball
	emitter(e + Vector2(0, -26), tex_puff, 24, 0.9, {
		"direction": Vector2(0, -1), "spread": 40.0, "initial_velocity_min": 120.0, "initial_velocity_max": 300.0,
		"gravity": Vector2(0, -60), "damping_min": 90.0, "damping_max": 150.0, "scale_amount_min": 0.35, "scale_amount_max": 0.7,
		"scale_amount_curve": curve(1.0, 0.2, 1.3), "explosiveness": 0.95, "preprocess": 0.3,
		"color_ramp": ramp([Color(1, 0.95, 0.5, 1), Color(1, 0.62, 0.12, 1), Color(0.95, 0.28, 0.14, 0.9), Color(0.6, 0.15, 0.2, 0.0)], [0.0, 0.25, 0.6, 1.0])})
	# sparks
	emitter(e + Vector2(0, -10), tex_soft, 40, 1.2, {
		"direction": Vector2(0, -1), "spread": 100.0, "initial_velocity_min": 220.0, "initial_velocity_max": 560.0,
		"gravity": Vector2(0, 700), "scale_amount_min": 0.07, "scale_amount_max": 0.16, "explosiveness": 1.0, "preprocess": 0.3,
		"color_ramp": ramp([Color(1, 1, 0.8, 1), Color(1, 0.7, 0.2, 1), Color(1, 0.3, 0.1, 0)], [0.0, 0.4, 1.0])}, true)
	# dirt chunks
	emitter(e + Vector2(0, 0), tex_chunk, 16, 1.7, {
		"direction": Vector2(0, -1), "spread": 65.0, "initial_velocity_min": 260.0, "initial_velocity_max": 520.0,
		"gravity": Vector2(0, 900), "angular_velocity_min": -300.0, "angular_velocity_max": 300.0, "angle_min": 0.0, "angle_max": 360.0,
		"scale_amount_min": 0.7, "scale_amount_max": 1.6, "explosiveness": 1.0, "preprocess": 0.34})

func add_trail() -> void:
	# shell trail: a puff emitter per segment, wider and fainter further from the shell
	var segs := [[0.34, 0.39, 0.12, 1.0], [0.26, 0.34, 0.17, 0.8], [0.16, 0.26, 0.23, 0.55], [0.04, 0.16, 0.3, 0.32]]
	for s in segs:
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		for i in 14:
			pts.append(Art.shell_pos(lerpf(s[0], s[1], i / 13.0)))
			cols.append(Color(1.0, 0.92, 0.82, s[3]).lerp(Color(1.0, 0.7, 0.55, s[3]), 0.3))
		emitter(Vector2.ZERO, tex_soft, 22, 100.0, {
			"emission_shape": CPUParticles2D.EMISSION_SHAPE_POINTS, "emission_points": pts, "emission_colors": cols,
			"explosiveness": 1.0, "scale_amount_min": s[2] * 0.8, "scale_amount_max": s[2] * 1.1, "gravity": Vector2.ZERO, "initial_velocity_min": 0.0, "initial_velocity_max": 0.0})
	# hot core glow right behind the shell, plus sparks shed by it
	var core := PackedVector2Array()
	for i in 8:
		core.append(Art.shell_pos(0.392 - i * 0.006))
	emitter(Vector2.ZERO, tex_soft, 14, 100.0, {
		"emission_shape": CPUParticles2D.EMISSION_SHAPE_POINTS, "emission_points": core, "explosiveness": 1.0,
		"scale_amount_min": 0.1, "scale_amount_max": 0.16, "color": Color(1.0, 0.8, 0.3, 0.9), "gravity": Vector2.ZERO}, true)
	emitter(Art.shell_pos(0.39), tex_soft, 24, 0.9, {
		"direction": Vector2(-1, 0.6), "spread": 40.0, "initial_velocity_min": 40.0, "initial_velocity_max": 140.0,
		"gravity": Vector2(0, 300), "scale_amount_min": 0.05, "scale_amount_max": 0.1, "preprocess": 0.6,
		"color_ramp": ramp([Color(1, 0.95, 0.6, 1), Color(1, 0.5, 0.2, 0.8), Color(1, 0.3, 0.1, 0)], [0.0, 0.5, 1.0])}, true)

func add_enemy_smoke() -> void:
	var b := Art.tank_base(Art.enemy_x)
	var hits := [Vector2(b.x + 10, b.y - 146), Vector2(b.x + 74, b.y - 138), Vector2(b.x + 55, b.y - 135)]
	for i in 2:
		emitter(hits[i], tex_puff, 9 if i == 0 else 5, 2.6 if i == 0 else 2.0, {
			"direction": Vector2(0.3, -1), "spread": 20.0, "initial_velocity_min": 24.0, "initial_velocity_max": 54.0,
			"gravity": Vector2(16, -10), "scale_amount_min": 0.12 if i == 0 else 0.08, "scale_amount_max": 0.2 if i == 0 else 0.14,
			"scale_amount_curve": curve(0.5, 1.9), "preprocess": 2.5,
			"color_ramp": ramp([Color(0.5, 0.4, 0.6, 0.0), Color(0.5, 0.4, 0.62, 0.95), Color(0.5, 0.4, 0.65, 0.0)], [0.0, 0.12, 1.0])})

func add_dust() -> void:
	var b := Art.tank_base(Art.player_x)
	emitter(b + Vector2(-70, -4), tex_puff, 6, 1.6, {
		"direction": Vector2(-1, -0.4), "spread": 25.0, "initial_velocity_min": 14.0, "initial_velocity_max": 40.0,
		"scale_amount_min": 0.1, "scale_amount_max": 0.17, "scale_amount_curve": curve(0.5, 1.6), "preprocess": 1.5,
		"color_ramp": ramp([Color(1, 0.8, 0.6, 0.0), Color(1.0, 0.72, 0.52, 0.9), Color(1.0, 0.7, 0.6, 0.0)], [0.0, 0.15, 1.0])})

func add_ambient_far() -> void:
	# floating pollen / embers in the middle distance
	emitter(Vector2(640, 330), tex_soft, 46, 12.0, {
		"emission_shape": CPUParticles2D.EMISSION_SHAPE_RECTANGLE, "emission_rect_extents": Vector2(680, 200),
		"direction": Vector2(1, -0.2), "spread": 30.0, "initial_velocity_min": 6.0, "initial_velocity_max": 18.0,
		"scale_amount_min": 0.03, "scale_amount_max": 0.08, "preprocess": 12.0, "color": Color(1.0, 0.85, 0.55, 0.65)}, true, false)

func add_ambient_near() -> void:
	emitter(Vector2(640, 380), tex_soft, 10, 10.0, {
		"emission_shape": CPUParticles2D.EMISSION_SHAPE_RECTANGLE, "emission_rect_extents": Vector2(700, 330),
		"direction": Vector2(1, -0.1), "spread": 25.0, "initial_velocity_min": 10.0, "initial_velocity_max": 26.0,
		"scale_amount_min": 0.18, "scale_amount_max": 0.45, "preprocess": 10.0, "color": Color(1.0, 0.8, 0.5, 0.14)}, true, false)
	# tumbling leaves carried by the wind
	emitter(Vector2(500, 380), tex_leaf, 8, 11.0, {
		"emission_shape": CPUParticles2D.EMISSION_SHAPE_RECTANGLE, "emission_rect_extents": Vector2(560, 260),
		"direction": Vector2(1, 0.15), "spread": 15.0, "initial_velocity_min": 50.0, "initial_velocity_max": 90.0,
		"gravity": Vector2(0, 8), "angular_velocity_min": -160.0, "angular_velocity_max": 160.0, "angle_min": 0.0, "angle_max": 360.0,
		"scale_amount_min": 0.8, "scale_amount_max": 1.4, "preprocess": 11.0, "color": Color("ffb040")}, false, false)
