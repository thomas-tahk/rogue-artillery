extends Node2D
# Static look mockup built from real CC0 packs (see assets/ and SOURCING.md). No gameplay.
# Run with `-- --capture` to save shot.png (and shot2.png close-up).

const W := 1280.0
const H := 720.0
const A := "res://assets/"
const PLAYER_X := 256.0
const ENEMY_X := 1030.0
const BLAST_X := 858.0
const CRATER_X := 790.0
const SUN := Vector2(800, 392)

const INK := Color("1c1038")
const CREAM := Color("fff1d6")
const PLAYER_HP := 0.82
const ENEMY_HP := 0.38

var font: Font
var rng := RandomNumberGenerator.new()
var player_tank: Node2D
var enemy_tank: Node2D
var player_pivot := Vector2.ZERO
var world: Node2D
var hud: CanvasLayer

func _ready() -> void:
	rng.seed = 11
	font = load(A + "kenney-font/Kenney Future.ttf")
	_build_backdrop()
	world = Node2D.new()
	add_child(world)
	_build_world()
	_build_overlay()
	_build_hud()
	if "--capture" in OS.get_cmdline_user_args():
		_capture()

func _capture() -> void:
	for i in 4:
		await get_tree().process_frame
	_freeze_particles(self)
	for i in 25:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://shot.png")
	var cam := Camera2D.new()
	cam.position = Vector2(640, 360)
	add_child(cam)
	cam.make_current()
	await get_tree().process_frame
	hud.visible = false
	cam.position = Vector2(330, 400)
	cam.zoom = Vector2(2.5, 2.5)
	for i in 12:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png("res://shot2.png")
	get_tree().quit()

func _freeze_particles(n: Node) -> void:
	if n is CPUParticles2D:
		n.speed_scale = 0.0
	for c in n.get_children():
		_freeze_particles(c)

# ---------------------------------------------------------------- helpers

func surface(x: float) -> float:
	var y := 528.0 + 20.0 * sin(x * 0.0055 + 1.0) + 10.0 * sin(x * 0.014 + 2.0)
	y -= 78.0 * exp(-pow((x - PLAYER_X) / 130.0, 2.0))
	y -= 30.0 * exp(-pow((x - 1010.0) / 120.0, 2.0))
	y += 46.0 * exp(-pow((x - CRATER_X) / 44.0, 2.0))
	return y

func mid_hill(x: float) -> float:
	return 462.0 + 26.0 * sin(x * 0.0042 + 0.6) + 12.0 * sin(x * 0.011 + 2.2)

func tex(path: String) -> Texture2D:
	return load(A + path) as Texture2D

func mat_shader(path: String, params: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/" + path)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m

func gmap(dark: Color, light: Color, extra := {}) -> ShaderMaterial:
	var p := {"dark_col": dark, "light_col": light}
	p.merge(extra, true)
	return mat_shader("gmap.gdshader", p)

func lum_alpha() -> ShaderMaterial:
	return mat_shader("lum_alpha.gdshader", {})

func additive() -> CanvasItemMaterial:
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return m

func radial(inner: Color, outer: Color, size := 256) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, outer)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t

func sprite(parent: Node, texture: Texture2D, pos: Vector2, sc := 1.0) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = texture
	s.position = pos
	s.scale = Vector2(sc, sc)
	parent.add_child(s)
	return s

func curve(pts: Array) -> Curve:
	var c := Curve.new()
	for p in pts:
		c.add_point(p)
	return c

func ramp(stops: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([stops[0][0]])
	g.colors = PackedColorArray([stops[0][1]])
	for i in range(1, stops.size()):
		g.add_point(stops[i][0], stops[i][1])
	return g

func strip(top: PackedVector2Array, bot: PackedVector2Array, c_top: Color, c_bot: Color, t: Texture2D = null, uv_scale := 0.004) -> MeshInstance2D:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var uvs := PackedVector2Array()
	var idx := PackedInt32Array()
	for i in top.size():
		verts.append(top[i]); cols.append(c_top); uvs.append(top[i] * uv_scale)
		verts.append(bot[i]); cols.append(c_bot); uvs.append(bot[i] * uv_scale)
		if i > 0:
			var k := (i - 1) * 2
			idx.append_array(PackedInt32Array([k, k + 1, k + 2, k + 1, k + 3, k + 2]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance2D.new()
	mi.mesh = mesh
	mi.texture = t
	mi.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	return mi

# ---------------------------------------------------------------- backdrop (parallax layers, unlit canvas)

func _build_backdrop() -> void:
	var bg := CanvasLayer.new()
	bg.layer = -10
	add_child(bg)
	_sky(bg)
	_sun(bg)
	_clouds(bg)
	_landscape_layer(bg, "oga-landscape/landscape_0003_4_mountain.png", Color("6a3a8c"), Color("f59ab0"), -20.0,
		{"lo": 0.45, "hi": 0.85, "haze_col": Color("ff9d7a"), "haze_amt": 0.55, "haze_from": 0.55})
	_landscape_layer(bg, "oga-landscape/landscape_0002_3_trees.png", Color("523078"), Color("a04c8f"), -78.0,
		{"lo": 0.2, "hi": 0.6, "haze_col": Color("e06f86"), "haze_amt": 0.5, "haze_from": 0.62})
	_landscape_layer(bg, "oga-landscape/landscape_0001_2_trees.png", Color("33205c"), Color("6d3a86"), -60.0,
		{"lo": 0.2, "hi": 0.6, "haze_col": Color("a04c8f"), "haze_amt": 0.5, "haze_from": 0.66})

func _sky(bg: Node) -> void:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.28, 0.5, 0.64, 0.8])
	g.colors = PackedColorArray([Color("2b2a7a"), Color("7a3f9e"), Color("e0618f"), Color("ff9a5c"), Color("ffd27a")])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 4
	t.height = 256
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1)
	var r := TextureRect.new()
	r.texture = t
	r.position = Vector2.ZERO
	r.size = Vector2(W, H)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_SCALE
	bg.add_child(r)

func _sun(bg: Node) -> void:
	var halo := sprite(bg, radial(Color(1.0, 0.55, 0.3, 0.55), Color(1.0, 0.4, 0.3, 0.0), 512), SUN, 1.9)
	halo.material = additive()
	var core := sprite(bg, radial(Color(1.0, 0.95, 0.7, 0.95), Color(1.0, 0.8, 0.45, 0.0), 256), SUN, 0.8)
	core.material = additive()

func _clouds(bg: Node) -> void:
	var specs := [
		["cloud2", Vector2(210, 150), 0.9], ["cloud4", Vector2(1010, 96), 0.75],
		["cloud1", Vector2(560, 214), 0.7], ["cloud5", Vector2(1200, 250), 0.85],
		["cloud3", Vector2(60, 300), 0.6], ["cloud1", Vector2(890, 305), 0.5],
	]
	for s in specs:
		var c := sprite(bg, tex("kenney-bg/%s.png" % s[0]), s[1], s[2])
		c.material = gmap(Color("b0468f"), Color("ffb78a"), {"lo": 0.55, "hi": 0.98})
		c.modulate.a = 0.8
		c.scale *= 0.8

func _landscape_layer(bg: Node, path: String, dark: Color, light: Color, y_off: float, extra: Dictionary) -> void:
	var s := Sprite2D.new()
	s.texture = tex(path)
	s.centered = false
	s.scale = Vector2(W / 1920.0, W / 1920.0)
	s.position = Vector2(0, y_off)
	s.material = gmap(dark, light, extra)
	bg.add_child(s)

# ---------------------------------------------------------------- world (lit canvas)

func _build_world() -> void:
	var mod := CanvasModulate.new()
	mod.color = Color(0.93, 0.86, 1.0)
	world.add_child(mod)
	_mid_hills()
	_terrain()
	_crater_details()
	_tanks()
	_shell_and_trail()
	_explosion()
	_wind_streaks()
	_foreground()
	_lights()

func _mid_hills() -> void:
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	for x in range(-10, int(W) + 20, 10):
		top.append(Vector2(x, mid_hill(x)))
		bot.append(Vector2(x, 640))
	world.add_child(strip(top, bot, Color("5a3586"), Color("2a1850")))
	var m := gmap(Color("1f1048"), Color("4a2a78"), {"lo": 0.15, "hi": 0.75})
	var names := ["tree", "treeLong", "bush1", "tree", "bush2", "treeLong", "tree", "bush3", "tree", "treeLong", "tree"]
	var x := 40.0
	for n in names:
		var sc := 0.4 if n.begins_with("bush") else 0.3
		var sp := sprite(world, tex("kenney-bg/%s.png" % n), Vector2(x, mid_hill(x) + 6), sc)
		sp.offset = Vector2(0, -sp.texture.get_height() * 0.5)
		sp.material = m
		x += rng.randf_range(95.0, 135.0)
		if x > W + 40.0:
			break

func _terrain() -> void:
	var poly := PackedVector2Array()
	for x in range(-10, int(W) + 20, 6):
		poly.append(Vector2(x, surface(x)))
	poly.append(Vector2(W + 14, H + 10))
	poly.append(Vector2(-10, H + 10))
	var dirt := Polygon2D.new()
	dirt.polygon = poly
	dirt.material = mat_shader("terrain.gdshader", {"dirt_tex": tex("oga-terrains/dirt.jpg"), "crater": Vector2(CRATER_X, surface(CRATER_X) + 4.0)})
	world.add_child(dirt)
	_grass(-12.0, CRATER_X - 52.0)
	_grass(CRATER_X + 52.0, W + 14.0)
	_ground_shadow()

func _grass(x0: float, x1: float) -> void:
	var top := PackedVector2Array()
	var bot := PackedVector2Array()
	var hi_top := PackedVector2Array()
	var hi_bot := PackedVector2Array()
	var x := x0
	while x <= x1:
		var edge := clampf(minf(x - x0, x1 - x) / 14.0, 0.0, 1.0)
		var thick := (23.0 + 5.0 * sin(x * 0.045)) * edge
		var y := surface(x)
		top.append(Vector2(x, y - 1.0))
		bot.append(Vector2(x, y + thick))
		hi_top.append(Vector2(x, y - 1.5))
		hi_bot.append(Vector2(x, y + 4.5 * edge))
		x += 6.0
	world.add_child(strip(top, bot, Color("c4f060"), Color("2f9a52"), tex("oga-terrains/grass.jpg"), 0.004))
	world.add_child(strip(hi_top, hi_bot, Color(1.0, 0.98, 0.65, 0.95), Color(0.9, 1.0, 0.5, 0.0)))
	_blades(x0, x1)

func _blades(x0: float, x1: float) -> void:
	var verts := PackedVector2Array()
	var cols := PackedColorArray()
	var x := x0 + 8.0
	while x < x1 - 8.0:
		var y := surface(x) + 1.0
		var h := rng.randf_range(7.0, 15.0)
		var lean := rng.randf_range(-4.0, 4.0)
		var w := rng.randf_range(1.6, 2.8)
		verts.append_array(PackedVector2Array([Vector2(x - w, y), Vector2(x + w, y), Vector2(x + lean, y - h)]))
		cols.append_array(PackedColorArray([Color("3aa24a"), Color("3aa24a"), Color("e4ff7a")]))
		x += rng.randf_range(5.0, 11.0)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = cols
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance2D.new()
	mi.mesh = mesh
	world.add_child(mi)

func _ground_shadow() -> void:
	# soft ambient-occlusion band under the grass lip, split at the crater
	var runs := [[PackedVector2Array(), PackedVector2Array()], [PackedVector2Array(), PackedVector2Array()]]
	for x in range(-10, int(W) + 20, 8):
		if absf(x - CRATER_X) < 50.0:
			continue
		var k := 0 if x < CRATER_X else 1
		runs[k][0].append(Vector2(x, surface(x) + 24.0))
		runs[k][1].append(Vector2(x, surface(x) + 78.0))
	for run in runs:
		world.add_child(strip(run[0], run[1], Color(0.12, 0.03, 0.2, 0.45), Color(0.12, 0.03, 0.2, 0.0)))

func _crater_details() -> void:
	var cy := surface(CRATER_X)
	var ember := sprite(world, tex("kenney-particles/light_01.png"), Vector2(CRATER_X, cy + 2.0), 0.55)
	ember.material = additive()
	ember.modulate = Color(1.0, 0.45, 0.15, 0.55)
	var p := _ps("kenney-particles/dirt_01.png", false)
	p.position = Vector2(CRATER_X, cy - 6.0)
	p.amount = 16
	p.lifetime = 1.4
	p.preprocess = 0.75
	p.explosiveness = 1.0
	p.direction = Vector2(0, -1)
	p.spread = 55.0
	p.initial_velocity_min = 90.0
	p.initial_velocity_max = 260.0
	p.gravity = Vector2(0, 520)
	p.scale_amount_min = 0.035
	p.scale_amount_max = 0.085
	p.angular_velocity_min = -240.0
	p.angular_velocity_max = 240.0
	p.color_ramp = ramp([[0.0, Color("8a4a30")], [0.75, Color("5a2a34")], [1.0, Color(0.3, 0.12, 0.2, 0.0)]])
	world.add_child(p)

# ---------------------------------------------------------------- tanks

func _tank_mat(flip: bool, tint := Color.WHITE) -> ShaderMaterial:
	return mat_shader("toon.gdshader", {"flip_x": -1.0 if flip else 1.0, "tint": tint})

func _tank(body: String, body_size: Vector2, barrel: String, pivot: Vector2, x: float, flip: bool, angle_deg: float, tint: Color) -> Node2D:
	var gy := surface(x)
	var slope := (surface(x + 34.0) - surface(x - 34.0)) / 68.0
	var shadow := sprite(world, radial(Color(0.1, 0.02, 0.15, 0.7), Color(0.1, 0.02, 0.15, 0.0), 128), Vector2(x, gy + 5.0), 1.0)
	shadow.scale = Vector2(1.55, 0.2)
	shadow.rotation = atan(slope)
	var root := Node2D.new()
	root.position = Vector2(x, gy + 5.0)
	root.rotation = atan(slope) * 0.9
	var sc := 1.12
	root.scale = Vector2(-sc if flip else sc, sc)
	world.add_child(root)
	var bpos := Vector2(0, -40.0 - body_size.y * 0.5)
	var br := sprite(root, tex("kenney-tanks/" + barrel), bpos + pivot - body_size * 0.5)
	br.offset = Vector2(br.texture.get_width() * 0.5 - 4.0, 0)
	br.rotation = -deg_to_rad(angle_deg)
	br.material = _tank_mat(flip, tint)
	var tr := sprite(root, tex("kenney-tanks/tanks_tankTracks2.png"), Vector2(0, -34.5))
	tr.material = _tank_mat(flip, Color(0.62, 0.6, 0.78))
	var bd := sprite(root, tex("kenney-tanks/" + body), bpos)
	bd.material = _tank_mat(flip, tint)
	return root

func _tanks() -> void:
	player_tank = _tank("tanks_tankGreen_body1.png", Vector2(165, 96), "tanks_turret1.png", Vector2(96, 22), PLAYER_X, false, 50.0, Color(1.0, 1.0, 1.0))
	enemy_tank = _tank("tanks_tankDesert_body3.png", Vector2(168, 106), "tanks_turret2.png", Vector2(104, 34), ENEMY_X, true, 38.0, Color(1.0, 0.92, 0.9))
	player_pivot = player_tank.to_global(Vector2(96, 22) - Vector2(82.5, 48) + Vector2(0, -88.0))

# ---------------------------------------------------------------- shell, trail, explosion

func bez(t: float) -> Vector2:
	var p0 := Vector2(318, 372)
	var p1 := Vector2(660, -110)
	var p2 := Vector2(1010, 440)
	return p0 * (1 - t) * (1 - t) + p1 * 2.0 * (1 - t) * t + p2 * t * t

func _shell_and_trail() -> void:
	var t_now := 0.60
	var line := Line2D.new()
	for i in 41:
		line.add_point(bez(t_now * float(i) / 40.0))
	line.width = 9.0
	line.width_curve = curve([Vector2(0, 0.0), Vector2(1, 1.0)])
	var g := Gradient.new()
	g.set_color(0, Color(1.0, 0.45, 0.2, 0.0))
	g.set_color(1, Color(1.0, 0.95, 0.7, 0.95))
	line.gradient = g
	line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	line.end_cap_mode = Line2D.LINE_CAP_ROUND
	line.material = additive()
	world.add_child(line)
	for i in 16:
		var t := t_now * (0.15 + 0.85 * float(i) / 15.0)
		var puff := sprite(world, tex("kenney-particles/smoke_07.png"), bez(t) + Vector2(rng.randf_range(-3, 3), rng.randf_range(-3, 3)), 0.05 + 0.05 * (1.0 - float(i) / 15.0))
		puff.material = lum_alpha()
		puff.modulate = Color(1.0, 0.82, 0.85, 0.5 * float(i) / 15.0 + 0.05)
	var pos := bez(t_now)
	var ahead := bez(t_now + 0.02)
	var halo := sprite(world, radial(Color(1.0, 0.8, 0.4, 0.8), Color(1.0, 0.5, 0.2, 0.0), 128), pos, 0.6)
	halo.material = additive()
	var shell := sprite(world, tex("kenney-tanks/tank_bullet1.png"), pos, 1.0)
	shell.rotation = (ahead - pos).angle()
	shell.material = _tank_mat(false, Color(1.0, 0.9, 0.7))
	for i in 9:
		var t := t_now + 0.03 * float(i + 1)
		var d := sprite(world, radial(Color(1.0, 0.95, 0.8, 0.8), Color(1.0, 0.8, 0.5, 0.0), 32), bez(t), 0.28 - 0.02 * float(i))
		d.material = additive()

func _ps(path: String, add: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = tex(path)
	p.emitting = true
	p.one_shot = false
	p.randomness = 0.4
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 8.0
	p.local_coords = false
	p.gravity = Vector2.ZERO
	p.material = additive() if add else lum_alpha()
	return p

func _explosion() -> void:
	var bp := Vector2(BLAST_X, surface(BLAST_X) - 22.0)
	var root := Node2D.new()
	root.position = bp
	world.add_child(root)
	var glow := sprite(root, radial(Color(1.0, 0.7, 0.3, 0.55), Color(1.0, 0.35, 0.2, 0.0), 512), Vector2(0, -10), 0.9)
	glow.material = additive()
	var flat2 := sprite(root, tex("kenney-tanks/tank_explosion3.png"), Vector2(-4, 4), 1.25)
	flat2.rotation = 0.3
	var flat := sprite(root, tex("kenney-tanks/tank_explosion4.png"), Vector2(2, -10), 0.78)
	flat.rotation = -0.2
	var smoke := _ps("kenney-particles/smoke_01.png", false)
	smoke.amount = 14
	smoke.lifetime = 3.2
	smoke.preprocess = 1.5
	smoke.explosiveness = 0.5
	smoke.direction = Vector2(0.2, -1)
	smoke.spread = 40.0
	smoke.initial_velocity_min = 35.0
	smoke.initial_velocity_max = 90.0
	smoke.gravity = Vector2(14, -12)
	smoke.damping_min = 10.0
	smoke.damping_max = 25.0
	smoke.scale_amount_min = 0.2
	smoke.scale_amount_max = 0.38
	smoke.scale_amount_curve = curve([Vector2(0, 0.55), Vector2(1, 1.3)])
	smoke.angular_velocity_min = -25.0
	smoke.angular_velocity_max = 25.0
	smoke.color_ramp = ramp([[0.0, Color(0.30, 0.20, 0.34, 0.0)], [0.12, Color(0.30, 0.20, 0.34, 0.9)], [0.6, Color(0.42, 0.30, 0.46, 0.65)], [1.0, Color(0.6, 0.42, 0.58, 0.0)]])
	smoke.position = Vector2(0, -22)
	root.add_child(smoke)
	var fire := _ps("kenney-particles/smoke_04.png", true)
	fire.amount = 12
	fire.lifetime = 1.6
	fire.preprocess = 0.35
	fire.explosiveness = 1.0
	fire.direction = Vector2(0, -1)
	fire.spread = 100.0
	fire.initial_velocity_min = 25.0
	fire.initial_velocity_max = 110.0
	fire.damping_min = 30.0
	fire.damping_max = 60.0
	fire.scale_amount_min = 0.14
	fire.scale_amount_max = 0.3
	fire.scale_amount_curve = curve([Vector2(0, 1.0), Vector2(1, 0.4)])
	fire.color_ramp = ramp([[0.0, Color(1.0, 0.95, 0.6, 0.9)], [0.4, Color(1.0, 0.5, 0.15, 0.7)], [0.75, Color(0.8, 0.15, 0.2, 0.35)], [1.0, Color(0.3, 0.05, 0.2, 0.0)]])
	root.add_child(fire)
	var sparks := _ps("kenney-particles/trace_03.png", true)
	sparks.amount = 26
	sparks.lifetime = 1.4
	sparks.preprocess = 0.5
	sparks.explosiveness = 1.0
	sparks.direction = Vector2(0, -1)
	sparks.spread = 80.0
	sparks.initial_velocity_min = 220.0
	sparks.initial_velocity_max = 520.0
	sparks.gravity = Vector2(0, 640)
	sparks.particle_flag_align_y = true
	sparks.scale_amount_min = 0.05
	sparks.scale_amount_max = 0.11
	sparks.color_ramp = ramp([[0.0, Color(1.0, 0.95, 0.7, 1.0)], [0.5, Color(1.0, 0.6, 0.2, 0.9)], [1.0, Color(1.0, 0.3, 0.1, 0.0)]])
	root.add_child(sparks)
	var debris := _ps("kenney-particles/dirt_02.png", false)
	debris.amount = 22
	debris.lifetime = 1.8
	debris.preprocess = 0.7
	debris.explosiveness = 1.0
	debris.direction = Vector2(0, -1)
	debris.spread = 70.0
	debris.initial_velocity_min = 180.0
	debris.initial_velocity_max = 440.0
	debris.gravity = Vector2(0, 640)
	debris.angular_velocity_min = -300.0
	debris.angular_velocity_max = 300.0
	debris.scale_amount_min = 0.04
	debris.scale_amount_max = 0.1
	debris.color_ramp = ramp([[0.0, Color("ffb070")], [0.2, Color("b86a3a")], [0.8, Color("6a3238")], [1.0, Color(0.3, 0.1, 0.2, 0.0)]])
	debris.position = Vector2(0, 14)
	root.add_child(debris)
	var ring := sprite(root, tex("kenney-particles/circle_05.png"), Vector2(0, 26), 0.5)
	ring.material = additive()
	ring.scale = Vector2(0.62, 0.2)
	ring.modulate = Color(1.0, 0.8, 0.6, 0.45)

func _wind_streaks() -> void:
	var p := _ps("kenney-particles/trace_03.png", true)
	p.position = Vector2(-50, 340)
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(10, 190)
	p.amount = 9
	p.lifetime = 4.0
	p.preprocess = 2.0
	p.explosiveness = 0.0
	p.direction = Vector2(1, 0.03)
	p.spread = 2.0
	p.initial_velocity_min = 320.0
	p.initial_velocity_max = 380.0
	p.particle_flag_align_y = true
	p.scale_amount_min = 0.1
	p.scale_amount_max = 0.18
	p.color_ramp = ramp([[0.0, Color(1, 1, 1, 0.0)], [0.3, Color(1, 0.95, 0.9, 0.4)], [1.0, Color(1, 1, 1, 0.0)]])
	p.angle_min = 90.0
	p.angle_max = 90.0
	world.add_child(p)
	var motes := _ps("kenney-particles/circle_05.png", true)
	motes.position = Vector2(640, 400)
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(660, 260)
	motes.amount = 40
	motes.lifetime = 6.0
	motes.preprocess = 3.0
	motes.explosiveness = 0.0
	motes.direction = Vector2(1, -0.2)
	motes.spread = 25.0
	motes.initial_velocity_min = 8.0
	motes.initial_velocity_max = 24.0
	motes.scale_amount_min = 0.006
	motes.scale_amount_max = 0.014
	motes.color_ramp = ramp([[0.0, Color(1, 0.9, 0.6, 0.0)], [0.3, Color(1, 0.9, 0.6, 0.7)], [1.0, Color(1, 0.8, 0.5, 0.0)]])
	world.add_child(motes)

func _foreground() -> void:
	var m := gmap(Color("160a2e"), Color("3a1f5c"), {"lo": 0.1, "hi": 0.7})
	var items := [["bush1", Vector2(40, 724), 1.5], ["bush3", Vector2(190, 730), 1.1], ["bushAlt1", Vector2(1210, 726), 1.6],
		["bush2", Vector2(1090, 734), 1.0], ["bushAlt2", Vector2(1290, 730), 1.1]]
	for it in items:
		var s := sprite(world, tex("kenney-bg/%s.png" % it[0]), it[1], it[2])
		s.offset = Vector2(0, -s.texture.get_height() * 0.5)
		s.material = m

func _lights() -> void:
	var l := PointLight2D.new()
	l.texture = radial(Color.WHITE, Color(1, 1, 1, 0), 512)
	l.texture_scale = 1.5
	l.color = Color(1.0, 0.55, 0.25)
	l.energy = 0.4
	l.position = Vector2(BLAST_X, surface(BLAST_X) - 30.0)
	world.add_child(l)

# ---------------------------------------------------------------- screen overlay

func _build_overlay() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	var v := ColorRect.new()
	v.size = Vector2(W, H)
	v.material = mat_shader("vignette.gdshader", {})
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(v)

# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.layer = 10
	add_child(hud)
	_hp_panel(Vector2(24, 18), "PLAYER", PLAYER_HP, 82, "Blue", Color("5cf08a"), Color("1fa85a"), "tanks_tankGreen1.png")
	_hp_panel(Vector2(W - 24 - 300, 18), "BRUISER", ENEMY_HP, 38, "Red", Color("ffb54a"), Color("f0402e"), "tanks_tankDesert1.png")
	_banner()
	_wind()
	_gauge()

func label(text: String, pos: Vector2, sz: Vector2, fsize: int, col: Color, align := HORIZONTAL_ALIGNMENT_CENTER, outline := INK, osize := 6) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = sz
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", font)
	l.add_theme_font_size_override("font_size", fsize)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", outline)
	l.add_theme_constant_override("outline_size", osize)
	hud.add_child(l)
	return l

func panel9(color: String, pos: Vector2, sz: Vector2) -> NinePatchRect:
	var n := NinePatchRect.new()
	n.texture = tex("kenney-ui/btn_%s.png" % color)
	n.position = pos
	n.size = sz
	n.patch_margin_left = 18
	n.patch_margin_right = 18
	n.patch_margin_top = 16
	n.patch_margin_bottom = 22
	hud.add_child(n)
	return n

func pill(rect: Rect2, col: Color, outline := false) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(int(rect.size.y * 0.5))
	if outline:
		sb.set_border_width_all(2)
		sb.border_color = Color(1, 1, 1, 0.35)
	p.add_theme_stylebox_override("panel", sb)
	p.position = rect.position
	p.size = rect.size
	hud.add_child(p)
	return p

func bar(rect: Rect2, frac: float, c_hi: Color, c_lo: Color) -> void:
	pill(rect, Color(0.07, 0.03, 0.18, 0.92), true)
	var fill := Rect2(rect.position + Vector2(3, 3), Vector2((rect.size.x - 6.0) * frac, rect.size.y - 6.0))
	pill(fill, c_lo)
	pill(Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.58)), c_hi)
	pill(Rect2(fill.position + Vector2(4, 2), Vector2(maxf(fill.size.x - 8.0, 2.0), 3)), Color(1, 1, 1, 0.45))

func _hp_panel(pos: Vector2, who: String, frac: float, hp: int, color: String, c_hi: Color, c_lo: Color, icon: String) -> void:
	panel9(color, pos, Vector2(300, 92))
	var disc := sprite(hud, tex("kenney-ui/round_%s.png" % ("Blue" if color == "Blue" else "Yellow")), pos + Vector2(36, 44), 1.0)
	disc.modulate = Color(0.25, 0.1, 0.5) if color == "Blue" else Color(0.35, 0.05, 0.12)
	var ic := sprite(hud, tex("kenney-tanks/" + icon), pos + Vector2(36, 46), 0.23)
	ic.material = _tank_mat(color == "Red")
	label(who, pos + Vector2(70, 8), Vector2(130, 32), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_LEFT)
	label("%d/100" % hp, pos + Vector2(170, 8), Vector2(116, 32), 20, CREAM, HORIZONTAL_ALIGNMENT_RIGHT)
	bar(Rect2(pos + Vector2(70, 46), Vector2(216, 24)), frac, c_hi, c_lo)

func _banner() -> void:
	var glow := sprite(hud, radial(Color(1.0, 0.8, 0.3, 0.55), Color(1.0, 0.6, 0.2, 0.0), 256), Vector2(640, 52), 2.6)
	glow.material = additive()
	panel9("Yellow", Vector2(450, 12), Vector2(380, 76))
	label("YOUR TURN", Vector2(450, 14), Vector2(380, 64), 40, Color("fffbe8"), HORIZONTAL_ALIGNMENT_CENTER, Color("8a3a00"), 9)
	panel9("Grey", Vector2(550, 94), Vector2(180, 42))
	label("TURN 7", Vector2(550, 94), Vector2(180, 38), 22, Color("3b2a66"), HORIZONTAL_ALIGNMENT_CENTER, Color(1, 1, 1, 0.0), 0)

func _wind() -> void:
	panel9("Grey", Vector2(492, 640), Vector2(296, 70))
	label("WIND", Vector2(508, 646), Vector2(80, 30), 18, Color("3b2a66"), HORIZONTAL_ALIGNMENT_LEFT, Color(1, 1, 1, 0), 0)
	for i in 6:
		pill(Rect2(Vector2(588 + i * 28, 653), Vector2(22, 14)), Color("23b8f0") if i < 4 else Color("8f93b5"), false)
	label("4", Vector2(506, 668), Vector2(40, 36), 30, Color("1d6fd1"), HORIZONTAL_ALIGNMENT_CENTER, Color(1, 1, 1, 0), 0)
	var arrow := Polygon2D.new()
	var y0 := 686.0
	arrow.polygon = PackedVector2Array([Vector2(552, y0 - 6), Vector2(720, y0 - 6), Vector2(720, y0 - 15), Vector2(766, y0), Vector2(720, y0 + 15), Vector2(720, y0 + 6), Vector2(552, y0 + 6)])
	arrow.color = Color("23b8f0")
	hud.add_child(arrow)
	var hl := Polygon2D.new()
	hl.polygon = PackedVector2Array([Vector2(554, y0 - 5), Vector2(718, y0 - 5), Vector2(718, y0 - 1), Vector2(554, y0 - 1)])
	hl.color = Color(1, 1, 1, 0.45)
	hud.add_child(hl)

func _gauge() -> void:
	var c := player_pivot
	var r := 150.0
	var shadow := Line2D.new()
	var track := Line2D.new()
	var fill := Line2D.new()
	for i in 46:
		var a := deg_to_rad(float(i) * 2.0)
		var pt := c + Vector2(cos(a), -sin(a)) * r
		shadow.add_point(pt)
		track.add_point(pt)
		if i <= 25:
			fill.add_point(pt)
	shadow.width = 16.0
	shadow.default_color = Color(0.1, 0.03, 0.22, 0.75)
	track.width = 10.0
	track.default_color = Color(1, 1, 1, 0.32)
	fill.width = 10.0
	var g := Gradient.new()
	g.set_color(0, Color("ffe35a"))
	g.set_color(1, Color("ff7a2a"))
	fill.gradient = g
	for l in [shadow, track, fill]:
		l.begin_cap_mode = Line2D.LINE_CAP_ROUND
		l.end_cap_mode = Line2D.LINE_CAP_ROUND
		l.antialiased = true
		hud.add_child(l)
	for deg in range(0, 91, 10):
		var a := deg_to_rad(float(deg))
		var d := Vector2(cos(a), -sin(a))
		var tick := Line2D.new()
		tick.add_point(c + d * (r + 9.0))
		tick.add_point(c + d * (r + 17.0))
		tick.width = 2.5
		tick.default_color = Color(1, 1, 1, 0.8)
		hud.add_child(tick)
	var a50 := deg_to_rad(50.0)
	sprite(hud, tex("kenney-ui/round_Yellow.png"), c + Vector2(cos(a50), -sin(a50)) * r, 0.42)
	var lp := c + Vector2(cos(a50), -sin(a50)) * (r + 38.0)
	label("50°", lp - Vector2(40, 18), Vector2(80, 36), 26, Color("fff1a0"), HORIZONTAL_ALIGNMENT_CENTER, INK, 8)
	var base := player_tank.position + Vector2(-70, 24)
	pill(Rect2(base, Vector2(150, 24)), Color(0.07, 0.03, 0.18, 0.92), true)
	pill(Rect2(base + Vector2(3, 3), Vector2(144.0 * 0.72, 18)), Color("ff7a2a"))
	pill(Rect2(base + Vector2(3, 3), Vector2(144.0 * 0.72, 8)), Color("ffc24a"))
	label("POWER 72", base + Vector2(0, -1), Vector2(150, 26), 15, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, INK, 6)
