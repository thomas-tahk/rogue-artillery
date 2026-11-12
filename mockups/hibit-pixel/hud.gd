extends Node2D
## Pixel HUD: framed panels, tank-attached angle/power gauge, wind, HP, banner.

const INK := Color("1b1030")
const PANEL := Color("2a1d54")
const PANEL_HI := Color("4a2a7a")
const GOLD := Color("ffd98a")
const CREAM := Color("fff4c2")
const GOOD := Color("62c24a")
const GOOD_HI := Color("c4f065")
const BAD := Color("e0343c")
const BAD_HI := Color("ff7a45")

var font: FontFile
var player_pivot := Vector2.ZERO
var player_top := Vector2.ZERO
var enemy_top := Vector2.ZERO
var angle_deg := 50.0
var power := 0.72

func panel(r: Rect2i, border := GOLD) -> void:
	draw_rect(Rect2i(r.position + Vector2i(1, 0), r.size - Vector2i(2, 0)), INK)
	draw_rect(Rect2i(r.position + Vector2i(0, 1), r.size - Vector2i(0, 2)), INK)
	var i := r.grow(-1)
	draw_rect(Rect2i(i.position + Vector2i(1, 0), i.size - Vector2i(2, 0)), border)
	draw_rect(Rect2i(i.position + Vector2i(0, 1), i.size - Vector2i(0, 2)), border)
	var f := i.grow(-1)
	draw_rect(f, PANEL)
	draw_rect(Rect2i(f.position, Vector2i(f.size.x, f.size.y / 2)), PANEL_HI)
	draw_rect(Rect2i(f.position.x, f.position.y + f.size.y / 2, f.size.x, 1), PANEL.lightened(0.1))

func text(pos: Vector2i, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1) -> void:
	draw_string(font, pos + Vector2i(0, 1), s, align, w, size, INK)
	draw_string(font, pos + Vector2i(1, 0), s, align, w, size, INK)
	draw_string(font, pos + Vector2i(1, 1), s, align, w, size, INK)
	draw_string(font, pos, s, align, w, size, col)

func hp_bar(top_center: Vector2, frac: float, hi: Color, mid: Color, label: String) -> void:
	var r := Rect2i(int(top_center.x) - 19, int(top_center.y) - 14, 38, 7)
	draw_rect(r, INK)
	draw_rect(r.grow(-1), Color("3a2a50"))
	var w := int((r.size.x - 2) * frac)
	draw_rect(Rect2i(r.position + Vector2i(1, 1), Vector2i(w, 5)), mid)
	draw_rect(Rect2i(r.position + Vector2i(1, 1), Vector2i(w, 2)), hi)
	for tx in range(r.position.x + 8, r.position.x + r.size.x - 2, 8):
		draw_rect(Rect2i(tx, r.position.y + 1, 1, 5), INK)
	text(Vector2i(int(top_center.x), r.position.y - 3), label, 8, CREAM, HORIZONTAL_ALIGNMENT_CENTER, 0)

func angle_gauge() -> void:
	var c := player_pivot
	var rad := 27.0
	for a in range(0, 91, 5):
		var d := Vector2(cos(deg_to_rad(a)), -sin(deg_to_rad(a)))
		var major := a % 15 == 0
		var p := c + d * rad
		var col: Color = GOLD if a <= angle_deg else Color("8a6ab0")
		draw_rect(Rect2i(int(p.x), int(p.y), 1, 1), col)
		if major:
			var p2 := c + d * (rad + 2)
			draw_rect(Rect2i(int(p2.x), int(p2.y), 1, 1), col)
			var p3 := c + d * (rad - 2)
			draw_rect(Rect2i(int(p3.x), int(p3.y), 1, 1), col)
	var ap := c + Vector2(cos(deg_to_rad(angle_deg)), -sin(deg_to_rad(angle_deg))) * rad
	draw_rect(Rect2i(int(ap.x) - 1, int(ap.y) - 1, 3, 3), CREAM)
	draw_rect(Rect2i(int(ap.x) - 2, int(ap.y) - 2, 5, 5), CREAM, false)
	text(Vector2i(int(c.x) + 31, int(c.y) - 20), "%d°" % int(angle_deg), 8, CREAM)

func power_bar() -> void:
	var r := Rect2i(int(player_pivot.x) - 38, int(player_pivot.y) - 30, 7, 34)
	draw_rect(r, INK)
	draw_rect(r.grow(-1), Color("3a2a50"))
	var segs := 8
	var lit := int(round(power * segs))
	for i in segs:
		var sy := r.position.y + r.size.y - 2 - (i + 1) * 4 + 1
		var col := Color("ffd23f")
		if i >= 6:
			col = Color("ff7a2a")
		if i >= 7:
			col = BAD
		if i >= lit:
			col = Color("4a3a66")
		draw_rect(Rect2i(r.position.x + 1, sy, 5, 3), col)
		if i < lit:
			draw_rect(Rect2i(r.position.x + 1, sy, 5, 1), col.lightened(0.4))
	text(Vector2i(r.position.x - 4, r.position.y - 4), "PWR", 8, GOLD)
	text(Vector2i(r.position.x + 8, r.position.y + r.size.y - 6), "%d" % int(power * 100), 8, CREAM)

func chevrons(origin: Vector2i, count: int, lit: int) -> void:
	for i in count:
		var col := GOLD if i < lit else Color("5a4580")
		var x := origin.x + i * 7
		for k in 4:
			draw_rect(Rect2i(x + k, origin.y + k, 2, 1), col)
			draw_rect(Rect2i(x + k, origin.y + 7 - k, 2, 1), col)

func _draw() -> void:
	# turn counter
	panel(Rect2i(8, 8, 64, 20))
	text(Vector2i(14, 22), "TURN", 8, GOLD)
	text(Vector2i(64, 22), "07", 8, CREAM, HORIZONTAL_ALIGNMENT_RIGHT, 0)
	# banner
	panel(Rect2i(240, 8, 160, 24), GOLD)
	for sx in [248, 384]:
		draw_rect(Rect2i(sx, 18, 4, 4), BAD_HI)
		draw_rect(Rect2i(sx + 1, 19, 2, 2), CREAM)
	text(Vector2i(240, 25), "YOUR TURN", 16, CREAM, HORIZONTAL_ALIGNMENT_CENTER, 160)
	# wind
	panel(Rect2i(500, 8, 132, 28))
	text(Vector2i(508, 20), "WIND", 8, GOLD)
	text(Vector2i(508, 31), "STRENGTH 4", 8, CREAM)
	chevrons(Vector2i(582, 12), 5, 4)
	# HP
	hp_bar(player_top, 0.78, GOOD_HI, GOOD, "YOU")
	hp_bar(enemy_top, 0.45, BAD_HI, BAD, "RAIDER")
	angle_gauge()
	power_bar()
