class_name RobotRenderer
extends RefCounted

static func draw_robot(canvas: CanvasItem, center: Vector2, scale: float, unit: Dictionary, compact := false) -> void:
	if unit.is_empty(): return
	var facing := 1.0 if int(unit.get("team", 0)) == 0 else -1.0
	var armor: Color = unit.color
	var shadow := Color(0.015, 0.035, 0.08, 0.48)
	var dark := armor.darkened(0.55)
	var edge := armor.darkened(0.72)
	var light := armor.lightened(0.25)
	var visor := Color("78f5ff") if int(unit.get("team", 0)) == 0 else Color("ffb05e")
	var equipment: Dictionary = unit.get("equipment", {})
	var parts: Dictionary = unit.get("parts", {})
	var legs_hover: bool = equipment.has("legs") and equipment.legs.visual_style == "hover"
	var right_cannon: bool = equipment.has("right") and equipment.right.visual_style == "cannon"

	_draw_ellipse(canvas, center + Vector2(0, 27) * scale, Vector2(27, 8) * scale, shadow)
	_draw_legs(canvas, center, scale, armor, dark, edge, legs_hover, _alive(parts, "legs"))
	_draw_body(canvas, center, scale, armor, dark, edge, light, _alive(parts, "head"))
	_draw_arm(canvas, center, scale, -1.0, facing, armor, dark, edge, false, _alive(parts, "left"))
	_draw_arm(canvas, center, scale, 1.0, facing, armor, dark, edge, right_cannon, _alive(parts, "right"))
	_draw_head(canvas, center, scale, facing, armor, dark, edge, light, visor, _alive(parts, "head"), compact)

static func _alive(parts: Dictionary, slot: String) -> bool:
	return int(parts.get(slot, 1)) > 0

static func _part_color(color: Color, alive: bool) -> Color:
	return color if alive else Color(color.darkened(0.75), 0.42)

static func _poly(canvas: CanvasItem, center: Vector2, scale: float, points: Array[Vector2], color: Color) -> void:
	var transformed := PackedVector2Array()
	for point in points: transformed.append(center + point * scale)
	canvas.draw_colored_polygon(transformed, color)

static func _draw_ellipse(canvas: CanvasItem, center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index in 24:
		var angle := TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	canvas.draw_colored_polygon(points, color)

static func _draw_body(canvas: CanvasItem, center: Vector2, scale: float, armor: Color, dark: Color, edge: Color, light: Color, alive: bool) -> void:
	_poly(canvas, center, scale, [Vector2(-20,-12),Vector2(-12,-22),Vector2(12,-22),Vector2(21,-11),Vector2(16,14),Vector2(7,20),Vector2(-9,19),Vector2(-18,11)], _part_color(edge, alive))
	_poly(canvas, center, scale, [Vector2(-16,-11),Vector2(-10,-18),Vector2(10,-18),Vector2(17,-9),Vector2(12,11),Vector2(5,16),Vector2(-7,15),Vector2(-14,9)], _part_color(armor, alive))
	_poly(canvas, center, scale, [Vector2(-9,-15),Vector2(8,-15),Vector2(11,-4),Vector2(-6,-1)], _part_color(light, alive))
	canvas.draw_line(center + Vector2(-10, 6) * scale, center + Vector2(10, 6) * scale, _part_color(dark, alive), maxf(1.0, 2.2 * scale))

static func _draw_head(canvas: CanvasItem, center: Vector2, scale: float, facing: float, armor: Color, dark: Color, edge: Color, light: Color, visor: Color, alive: bool, compact: bool) -> void:
	var y := -30.0
	_poly(canvas, center, scale, [Vector2(-17,y-7),Vector2(-8,y-14),Vector2(13,y-11),Vector2(19,y-3),Vector2(13,y+8),Vector2(-13,y+8),Vector2(-20,y+1)], _part_color(edge, alive))
	_poly(canvas, center, scale, [Vector2(-14,y-5),Vector2(-7,y-11),Vector2(11,y-8),Vector2(15,y-2),Vector2(10,y+4),Vector2(-12,y+4),Vector2(-16,y)], _part_color(armor, alive))
	_poly(canvas, center, scale, [Vector2(-11,y-3),Vector2(11,y-2),Vector2(8,y+3),Vector2(-12,y+2)], visor if alive else Color("29343d"))
	if not compact:
		_poly(canvas, center, scale, [Vector2(-5,y-11),Vector2(1,y-24),Vector2(5,y-10)], _part_color(light, alive))
		canvas.draw_circle(center + Vector2(9 * facing, y) * scale, 2.1 * scale, Color("efffff") if alive else Color("4b5155"))

static func _draw_arm(canvas: CanvasItem, center: Vector2, scale: float, side: float, facing: float, armor: Color, dark: Color, edge: Color, cannon: bool, alive: bool) -> void:
	var x := 24.0 * side
	canvas.draw_circle(center + Vector2(x, -9) * scale, 10 * scale, _part_color(edge, alive))
	_poly(canvas, center, scale, [Vector2(x-7*side,-16),Vector2(x+8*side,-14),Vector2(x+12*side,-4),Vector2(x+5*side,2),Vector2(x-8*side,-2)], _part_color(armor, alive))
	var forearm_x := x + 7.0 * side
	_poly(canvas, center, scale, [Vector2(forearm_x-7*side,0),Vector2(forearm_x+8*side,-2),Vector2(forearm_x+11*side,18),Vector2(forearm_x+3*side,24),Vector2(forearm_x-8*side,17)], _part_color(edge, alive))
	_poly(canvas, center, scale, [Vector2(forearm_x-4*side,2),Vector2(forearm_x+5*side,1),Vector2(forearm_x+7*side,16),Vector2(forearm_x+1*side,20),Vector2(forearm_x-5*side,15)], _part_color(dark, alive))
	if cannon and alive:
		var muzzle := center + Vector2(forearm_x + 7.0 * side, 16) * scale
		canvas.draw_circle(muzzle, 5.0 * scale, edge)
		canvas.draw_circle(muzzle, 2.3 * scale, Color("a7fbff"))
	elif alive:
		var knuckle := center + Vector2(forearm_x + 2.0 * side, 23) * scale
		canvas.draw_circle(knuckle, 5.0 * scale, armor.lightened(0.15))

static func _draw_legs(canvas: CanvasItem, center: Vector2, scale: float, armor: Color, dark: Color, edge: Color, hover: bool, alive: bool) -> void:
	if hover:
		_poly(canvas, center, scale, [Vector2(-22,14),Vector2(22,14),Vector2(28,25),Vector2(17,32),Vector2(-18,32),Vector2(-28,25)], _part_color(edge, alive))
		_poly(canvas, center, scale, [Vector2(-17,16),Vector2(17,16),Vector2(21,24),Vector2(13,28),Vector2(-14,28),Vector2(-21,24)], _part_color(armor, alive))
		if alive:
			canvas.draw_line(center + Vector2(-14,31)*scale, center + Vector2(14,31)*scale, Color("7df7ff"), 3.0*scale)
		return
	for side in [-1.0, 1.0]:
		var x: float = 10.0 * float(side)
		_poly(canvas, center, scale, [Vector2(x-7*side,15),Vector2(x+5*side,15),Vector2(x+8*side,27),Vector2(x+2*side,39),Vector2(x-8*side,37),Vector2(x-9*side,27)], _part_color(edge, alive))
		_poly(canvas, center, scale, [Vector2(x-4*side,17),Vector2(x+3*side,17),Vector2(x+5*side,27),Vector2(x,34),Vector2(x-5*side,33),Vector2(x-6*side,26)], _part_color(armor, alive))
		_poly(canvas, center, scale, [Vector2(x-3*side,34),Vector2(x+7*side,34),Vector2(x+11*side,40),Vector2(x-7*side,40)], _part_color(dark, alive))
