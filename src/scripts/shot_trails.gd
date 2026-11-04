## Draws the live shell (head + fading tail) and the faint dotted path of each side's last shot.
class_name ShotTrails
extends Node2D

const TAIL_POINTS := 28
const DOT_EVERY := 5
const SIDE_COLORS: Array[Color] = [Color(0.4, 1.0, 0.4), Color(1.0, 0.5, 0.35)]

var _last: Array[PackedVector2Array] = [PackedVector2Array(), PackedVector2Array()]
var _live := PackedVector2Array()
var _live_side := -1


func begin(side: int) -> void:
	_live = PackedVector2Array()
	_live_side = side
	_last[side] = PackedVector2Array()
	queue_redraw()


func add_point(point: Vector2) -> void:
	_live.append(point)
	queue_redraw()


## The finished path stays as that side's dotted aiming aid until it fires again.
func finish() -> void:
	if _live_side >= 0:
		_last[_live_side] = _live
	_live = PackedVector2Array()
	_live_side = -1
	queue_redraw()


func clear() -> void:
	_last = [PackedVector2Array(), PackedVector2Array()]
	_live = PackedVector2Array()
	_live_side = -1
	queue_redraw()


func _draw() -> void:
	for side in 2:
		_draw_dots(_last[side], SIDE_COLORS[side])
	_draw_live()


func _draw_dots(points: PackedVector2Array, color: Color) -> void:
	color.a = 0.9
	for i in range(0, points.size(), DOT_EVERY):
		draw_circle(points[i], 4.0, color)


func _draw_live() -> void:
	var count := _live.size()
	if count == 0:
		return
	var first := maxi(count - TAIL_POINTS, 1)
	for i in range(first, count):
		var fade := float(i - first + 1) / float(count - first + 1)
		draw_line(_live[i - 1], _live[i], Color(1.0, 0.9, 0.3, fade), 4.0)
	draw_circle(_live[count - 1], 5.0, Color.BLACK)
	draw_circle(_live[count - 1], 3.5, Color(1.0, 1.0, 0.6))
