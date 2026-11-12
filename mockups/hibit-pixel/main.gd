extends Node2D
## Static hi-bit pixel mockup. 640x360 viewport, stretched x2, nearest filtering.

const Art := preload("res://art.gd")
const Fx := preload("res://fx.gd")
const Hud := preload("res://hud.gd")

const PLAYER_X := 128
const ENEMY_X := 499
const CRATER := Vector3(440, 252, 21)
const ANGLE := 50.0

func _ready() -> void:
	_layer(Art.make_sky())
	_layer(Art.make_clouds())
	_layer(Art.make_ridge(3, 205, 70, 0.006, Color("6b3f8c"), Color("e0685f"), Color("b04a82"), 60))
	_layer(Art.make_ridge(8, 232, 50, 0.011, Color("4a2f78"), Color("b04a82"), Color("7a3a86"), 40))
	_layer(Art.make_trees(5, 246, Color("2d2060"), Color("5a3a8a")))
	_layer(Art.make_terrain(CRATER))
	var pg := Art.height_at(PLAYER_X)
	var eg := Art.height_at(ENEMY_X)
	var pivot := Vector2(PLAYER_X, pg - 12)
	var epivot := Vector2(ENEMY_X - 5, eg - 19)
	_sprite(Art.make_barrel(ANGLE, 1.0, Color("7fd8f0"), Color("2a8fd6")), pivot - Vector2(20, 20))
	_sprite(Art.make_barrel(40.0, -1.0, Color("ff9a62"), Color("e0343c")), epivot - Vector2(20, 20))
	_sprite(Art.make_tank(Color("7fd8f0"), Color("2a8fd6"), Color("1f4a9a"), Color("ffd23f")),
		Vector2(PLAYER_X - 17, pg - 19))
	_sprite(Art.make_enemy(Color("ff9a62"), Color("e0343c"), Color("8a1f4a"), Color("ffd23f")),
		Vector2(ENEMY_X - 19, eg - 25))
	_effects(pivot)
	_layer(Art.make_vignette())
	var hud := Hud.new()
	hud.font = load("res://assets/fonts/kenpixel_square.ttf")
	hud.font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	hud.font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	hud.player_pivot = pivot
	hud.player_top = Vector2(PLAYER_X, pg - 24)
	hud.enemy_top = Vector2(ENEMY_X, eg - 28)
	add_child(hud)
	if "--capture" in OS.get_cmdline_user_args():
		_capture()

func _layer(img: Image) -> void:
	_sprite(img, Vector2.ZERO)

func _sprite(img: Image, pos: Vector2, additive := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.centered = false
	s.position = pos
	if additive:
		var m := CanvasItemMaterial.new()
		m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
		s.material = m
	add_child(s)
	return s

func _effects(pivot: Vector2) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var fx := Art.new_img(Art.W, Art.H)
	var boom := Vector2(CRATER.x, CRATER.y - 10)
	for p in [[Vector2(437, 205), 11.0], [Vector2(452, 190), 10.0], [Vector2(433, 176), 9.0],
			[Vector2(450, 160), 8.0], [Vector2(466, 148), 7.0], [Vector2(416, 214), 8.0]]:
		Fx.paint_puff(fx, p[0], p[1], 0.9 - (250.0 - p[0].y) / 150.0)
	Fx.paint_fireball(fx, boom)
	Fx.paint_sparks(fx, boom, rng)
	Fx.paint_debris(fx, boom, rng)
	# shell arc from the barrel tip to a landing point past the crater
	var a := deg_to_rad(ANGLE)
	var s := pivot + Vector2(cos(a), -sin(a)) * 15
	var e := Vector2(480, 236)
	var pts := []
	var u_now := 0.5
	for i in 40:
		var u := u_now - i * 0.0105
		pts.append(Vector2(lerpf(s.x, e.x, u), lerpf(s.y, e.y, u) - 4.0 * 150.0 * u * (1.0 - u)))
	Fx.paint_trail(fx, pts.slice(1))
	var head: Vector2 = pts[0]
	for y in range(-2, 3):
		for x in range(-2, 3):
			if absi(x) + absi(y) < 4:
				Art.put(fx, int(head.x) + x, int(head.y) + y, Art.INK)
	for y in range(-1, 2):
		for x in range(-1, 2):
			Art.put(fx, int(head.x) + x, int(head.y) + y, Color("ffd23f"))
	Art.put(fx, int(head.x), int(head.y), Color("ffffff"))
	_sprite(fx, Vector2.ZERO)
	_sprite(Art.make_glow(70, 8, Color(1.0, 0.45, 0.15)), boom - Vector2(70, 70), true)
	_sprite(Art.make_glow(26, 6, Color(1.0, 0.8, 0.4)), boom - Vector2(26, 26), true)
	_sprite(Art.make_glow(22, 6, Color(1.0, 0.7, 0.3)), head - Vector2(22, 22), true)

func _capture() -> void:
	for i in 30:
		await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.resize(1280, 720, Image.INTERPOLATE_NEAREST)
	img.save_png("res://shot.png")
	get_tree().quit()
