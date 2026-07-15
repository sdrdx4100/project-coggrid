class_name RobotPortrait
extends Control

var unit: Dictionary = {}

func show_unit(value: Dictionary) -> void:
	unit = value
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("132e59"), true)
	for i in 8:
		draw_line(Vector2(0, size.y * (i + 1) / 9.0), Vector2(size.x, size.y * (i + 1) / 9.0), Color(0.2, 0.55, 0.8, 0.12), 1)
	if unit.is_empty(): return
	var center := Vector2(size.x * 0.5, size.y * 0.58)
	var s: float = min(size.x, size.y) / 230.0
	var c: Color = unit.color
	var dark := c.darkened(0.56)
	draw_circle(center + Vector2(0, 78)*s, 55*s, Color(0, 0, 0, 0.32))
	# Legs
	draw_colored_polygon(PackedVector2Array([center+Vector2(-42,25)*s,center+Vector2(-8,25)*s,center+Vector2(-18,90)*s,center+Vector2(-52,90)*s]), dark)
	draw_colored_polygon(PackedVector2Array([center+Vector2(8,25)*s,center+Vector2(42,25)*s,center+Vector2(52,90)*s,center+Vector2(18,90)*s]), dark)
	# Head part includes torso.
	draw_colored_polygon(PackedVector2Array([center+Vector2(-52,-46)*s,center+Vector2(52,-46)*s,center+Vector2(40,35)*s,center+Vector2(-40,35)*s]), c)
	draw_circle(center+Vector2(0,-72)*s, 40*s, c.lightened(0.12))
	draw_colored_polygon(PackedVector2Array([center+Vector2(-15,-102)*s,center+Vector2(-4,-145)*s,center+Vector2(4,-102)*s]), dark)
	draw_colored_polygon(PackedVector2Array([center+Vector2(15,-102)*s,center+Vector2(28,-137)*s,center+Vector2(26,-94)*s]), dark)
	draw_circle(center+Vector2(-14,-76)*s, 7*s, Color("e9ffff"))
	draw_circle(center+Vector2(14,-76)*s, 7*s, Color("e9ffff"))
	# Arms
	draw_rect(Rect2(center+Vector2(-85,-35)*s, Vector2(27,82)*s), dark, true)
	draw_circle(center+Vector2(-72,50)*s, 18*s, c.lightened(0.08))
	draw_rect(Rect2(center+Vector2(58,-35)*s, Vector2(27,82)*s), dark, true)
	draw_circle(center+Vector2(72,50)*s, 18*s, c.lightened(0.08))
