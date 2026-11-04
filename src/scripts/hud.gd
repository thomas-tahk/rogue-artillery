## Heads-up display, built in code: status bar, wind arrow, key legend, result overlay.
class_name Hud
extends CanvasLayer

signal restart_requested

const TEXT_COLOR := Color(1, 1, 1)
const PANEL_COLOR := Color(0.04, 0.05, 0.12, 0.88)
const WIND_COLOR := Color(1.0, 0.85, 0.0)
const MIN_TEXT_SCALE := 0.8
const LEGEND := "Left/Right drive  |  Up/Down angle  |  W/S power  |  Space fire  |  R new battle"

var _turn := Label.new()
var _aim := Label.new()
var _wind_label := Label.new()
var _fuel := Label.new()
var _wind_arrow := Control.new()
var _wind := 0
var _overlay := ColorRect.new()
var _result := Label.new()
var _root := Control.new()


func _ready() -> void:
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_root.add_child(_build_status_bar())
	_root.add_child(_build_legend())
	_build_overlay(_root)
	get_viewport().size_changed.connect(_fit_to_window)
	_fit_to_window()


## Canvas stretch shrinks everything on tall phone windows; scale the HUD layer back up so text stays readable.
func _fit_to_window() -> void:
	var view := get_viewport().get_visible_rect().size
	var stretch := get_window().size.x / view.x
	var boost := clampf(MIN_TEXT_SCALE / stretch, 1.0, 3.0)
	scale = Vector2(boost, boost)
	_root.position = Vector2.ZERO
	_root.size = view / boost


func set_turn(text: String) -> void:
	_turn.text = text


func set_aim(deg: float, power: float) -> void:
	_aim.text = "Angle %d  Power %d" % [roundi(deg), roundi(power)]


func set_wind(strength: int) -> void:
	_wind = strength
	_wind_label.text = "Wind %d" % absi(strength)
	_wind_arrow.queue_redraw()


func set_fuel(fuel: float) -> void:
	_fuel.text = "Fuel %d" % roundi(fuel)


func show_result(player_won: bool) -> void:
	_result.text = "YOU WIN" if player_won else "YOU LOSE"
	_turn.text = _result.text
	_result.add_theme_color_override("font_color", Color(0.2, 1, 0.3) if player_won else Color(1, 0.3, 0.25))
	_overlay.visible = true


func hide_result() -> void:
	_overlay.visible = false
	_turn.text = ""


func _build_status_bar() -> Control:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 24)
	panel.add_child(flow)
	for label in [_turn, _aim, _fuel]:
		_style(label, 22)
		flow.add_child(label)
	flow.add_child(_build_wind())
	return panel


func _build_wind() -> Control:
	var box := HBoxContainer.new()
	_wind_arrow.custom_minimum_size = Vector2(76, 28)
	_wind_arrow.draw.connect(_draw_wind_arrow)
	_style(_wind_label, 22)
	box.add_child(_wind_arrow)
	box.add_child(_wind_label)
	return box


func _build_legend() -> Control:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	panel.add_theme_stylebox_override("panel", _box(PANEL_COLOR))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var legend := Label.new()
	legend.text = LEGEND
	legend.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style(legend, 18)
	panel.add_child(legend)
	return panel


func _build_overlay(root: Control) -> void:
	_overlay.color = Color(0, 0, 0, 0.55)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	root.add_child(_overlay)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_CENTER)
	column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	column.grow_vertical = Control.GROW_DIRECTION_BOTH
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 24)
	_overlay.add_child(column)
	_style(_result, 96)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_result)
	column.add_child(_build_restart_button())


func _build_restart_button() -> Button:
	var button := Button.new()
	button.text = "NEW BATTLE (R)"
	button.custom_minimum_size = Vector2(260, 56)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _box(Color(0.0, 0.35, 0.95)))
	button.add_theme_stylebox_override("hover", _box(Color(0.15, 0.5, 1.0)))
	button.add_theme_stylebox_override("pressed", _box(Color(0.0, 0.25, 0.75)))
	button.pressed.connect(restart_requested.emit)
	return button


func _draw_wind_arrow() -> void:
	var mid := _wind_arrow.size / 2.0
	var dir := signf(_wind)
	if dir == 0.0:
		_wind_arrow.draw_circle(mid, 5.0, WIND_COLOR)
		return
	var half := 8.0 + absf(_wind) * 3.0
	var tip := mid + Vector2(dir * half, 0)
	_wind_arrow.draw_line(mid - Vector2(dir * half, 0), tip, WIND_COLOR, 4.0)
	_wind_arrow.draw_colored_polygon(
		PackedVector2Array([tip + Vector2(dir * 8, 0), tip + Vector2(0, -8), tip + Vector2(0, 8)]), WIND_COLOR)


func _style(label: Label, size: int) -> void:
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 4)


func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_content_margin_all(8)
	box.set_corner_radius_all(6)
	return box
