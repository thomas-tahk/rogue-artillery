extends RefCounted
## Chunky pixel effects painted into a transparent image: smoke, fireball, sparks, debris, shell trail.

const Art := preload("res://art.gd")

const FIRE := ["d6342f", "ff7a2a", "ffd23f", "fff4c2"]
const SMOKE_DK := Color("2f2250")
const SMOKE := Color("5a4577")
const SMOKE_LIT := Color("8a6b9a")
const SMOKE_WARM := Color("d0805f")

static func paint_puff(img: Image, c: Vector2, r: float, warm: float) -> void:
	for y in range(int(c.y - r) - 1, int(c.y + r) + 2):
		for x in range(int(c.x - r) - 1, int(c.x + r) + 2):
			var d := Vector2(x + 0.5, y + 0.5) - c
			var wob := 1.0 + 0.12 * sin(atan2(d.y, d.x) * 3.0 + c.x)
			if d.length() > r * wob:
				continue
			# light comes from below (the fireball)
			var lit := d.y / r + 0.15 * (hash_off(x, y))
			var col := SMOKE
			if lit > 0.35:
				col = SMOKE_WARM if warm * lit > Art.bayer(x, y) * 0.8 + 0.1 else SMOKE_LIT
			elif lit < -0.25 or d.x / r > 0.6:
				col = SMOKE_DK
			if d.length() > r * wob - 1.2:
				col = SMOKE_DK if lit < 0.2 else SMOKE
			Art.put(img, x, y, col)

static func hash_off(x: int, y: int) -> float:
	return Art.hash2(x, y) - 0.5

static func paint_fireball(img: Image, c: Vector2) -> void:
	var blobs := [[Vector2(0, 0), 13.0], [Vector2(-10, -5), 9.0], [Vector2(11, -4), 8.0],
		[Vector2(1, -12), 8.0], [Vector2(-15, 4), 6.0], [Vector2(16, 3), 6.0]]
	for y in range(int(c.y) - 28, int(c.y) + 18):
		for x in range(int(c.x) - 30, int(c.x) + 30):
			var best := 9.0
			for b in blobs:
				var d: float = Vector2(x + 0.5, y + 0.5).distance_to(c + b[0]) / b[1]
				best = minf(best, d)
			if best > 1.0:
				continue
			var hot := 1.0 - best + 0.08 * Art.hash2(x, y) * 4.0 - 0.15
			hot += (-(y - c.y) / 60.0)
			var col := Color(Art.ramp(FIRE, hot * 3.4, x, y))
			Art.put(img, x, y, col)

static func paint_sparks(img: Image, c: Vector2, rng: RandomNumberGenerator) -> void:
	for i in 22:
		var a := rng.randf_range(-PI * 0.95, -PI * 0.05)
		var v := Vector2(cos(a), sin(a)) * rng.randf_range(2.5, 6.0)
		var life := rng.randi_range(8, 17)
		for t in life:
			var p := c + v * t * 0.8 + Vector2(0, 0.14 * t * t)
			var col := Color("fff4c2") if t > life - 4 else (Color("ffd23f") if t > life - 9 else Color("ff7a2a"))
			Art.put(img, int(p.x), int(p.y), col)
			if t > life - 3:
				Art.put(img, int(p.x) + 1, int(p.y), col)

static func paint_debris(img: Image, c: Vector2, rng: RandomNumberGenerator) -> void:
	var cols := [Color("74483c"), Color("533340"), Color("9a6448"), Color("62c24a"), Color("b59a92")]
	for i in 20:
		var a := rng.randf_range(-PI * 0.92, -PI * 0.08)
		var v := Vector2(cos(a), sin(a)) * rng.randf_range(2.5, 5.5)
		var t := rng.randf_range(7.0, 20.0)
		var p := c + v * t * 0.7 + Vector2(0, 0.1 * t * t)
		var s := rng.randi_range(2, 4)
		var col: Color = cols[rng.randi() % cols.size()]
		for dy in s - 1:
			for dx in s:
				Art.put(img, int(p.x) + dx, int(p.y) + dy, col)
		Art.put(img, int(p.x), int(p.y) - 1, Art.INK)
		Art.put(img, int(p.x) + s, int(p.y), Art.INK)
		Art.put(img, int(p.x), int(p.y) + s - 1, Art.INK)
		# dust trail
		for k in 3:
			var q := c + v * (t - 2.0 * (k + 1)) * 0.7 + Vector2(0, 0.1 * pow(t - 2.0 * (k + 1), 2))
			if rng.randf() > 0.4:
				Art.put(img, int(q.x), int(q.y), Color("8a6b9a"))

static func paint_trail(img: Image, pts: Array) -> void:
	# pts ordered newest -> oldest
	var n := pts.size()
	for i in n:
		var p: Vector2 = pts[i]
		var f := float(i) / n
		var col := Color("fff4c2")
		var size := 2
		if f > 0.18:
			col = Color("ffd23f")
		if f > 0.4:
			col = Color("ff7a2a")
			size = 2
		if f > 0.62:
			col = Color("8a6b9a")
		if f > 0.82:
			col = Color("5a4577")
			size = 1
		if i % 2 == 0 or f < 0.4:
			for dy in size:
				for dx in size:
					Art.put(img, int(p.x) + dx, int(p.y) + dy, col)
