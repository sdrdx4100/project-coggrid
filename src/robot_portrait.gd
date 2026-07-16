class_name RobotPortrait
extends Control

var unit: Dictionary = {}

func show_unit(value: Dictionary) -> void:
	unit = value
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("09162d"), true)
	for i in 10:
		draw_line(Vector2(0, size.y * (i + 1) / 11.0), Vector2(size.x, size.y * (i + 1) / 11.0), Color(0.22, 0.68, 0.9, 0.07), 1)
	if unit.is_empty(): return
	var center := Vector2(size.x * 0.5, size.y * 0.57)
	var scale: float = min(size.x, size.y) / 105.0
	RobotRenderer.draw_robot(self, center, scale, unit)
	draw_string(ThemeDB.fallback_font, Vector2(18, size.y - 15), "PARTS-LINK // %s" % unit.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("5b91b8"))
