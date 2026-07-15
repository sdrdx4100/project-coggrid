class_name GridBoard
extends Control

signal cell_clicked(cell: Vector2i)

const SIZE := 9
var battle: BattleState
var hover_cell := Vector2i(-1, -1)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	resized.connect(queue_redraw)

func bind(state: BattleState) -> void:
	battle = state
	battle.changed.connect(queue_redraw)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		hover_cell = _position_to_cell(event.position)
		queue_redraw()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var cell := _position_to_cell(event.position)
		if _inside(cell): cell_clicked.emit(cell)

func _position_to_cell(pos: Vector2) -> Vector2i:
	var rect := _board_rect()
	var tile := rect.size.x / SIZE
	return Vector2i(floor((pos.x - rect.position.x) / tile), floor((pos.y - rect.position.y) / tile))

func _inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < SIZE and cell.y < SIZE

func _board_rect() -> Rect2:
	var side: float = min(size.x, size.y) - 24.0
	return Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))

func _draw() -> void:
	if battle == null: return
	var rect := _board_rect()
	var tile := rect.size.x / SIZE
	draw_rect(rect.grow(7), Color("172039"), true)
	for y in SIZE:
		for x in SIZE:
			var cell := Vector2i(x, y)
			var cell_rect := Rect2(rect.position + Vector2(x, y) * tile, Vector2(tile, tile))
			var base := Color("597057") if (x + y) % 2 == 0 else Color("4a614d")
			if BattleState.GENERATORS.has(cell):
				base = Color("8a7b2d") if BattleState.GENERATORS[cell] == 0 else Color("73434e")
			if battle.phase == "move" and cell in battle.reachable_cells(): base = base.lerp(Color("43c6ff"), 0.43)
			var occupant := battle.unit_at(cell)
			if battle.phase == "target" and not occupant.is_empty() and occupant.id in battle.targetable_units():
				base = base.lerp(Color("ff4e66"), 0.58)
			if cell == hover_cell: base = base.lightened(0.14)
			draw_rect(cell_rect, base, true)
			draw_rect(cell_rect, Color("21302b"), false, 1.5)
			if BattleState.GENERATORS.has(cell): _draw_generator(cell_rect, BattleState.GENERATORS[cell])
	for unit in battle.units:
		if battle.is_active(unit): _draw_unit(rect, tile, unit)

func _draw_generator(rect: Rect2, team: int) -> void:
	var center := rect.get_center()
	var color := Color("7de7ff") if team == 0 else Color("ff8792")
	draw_circle(center, rect.size.x * 0.27, Color(color, 0.22))
	draw_arc(center, rect.size.x * 0.26, 0, TAU, 24, color, 3.0)
	draw_circle(center, rect.size.x * 0.09, color)

func _draw_unit(board_rect: Rect2, tile: float, unit: Dictionary) -> void:
	var center := board_rect.position + (Vector2(unit.cell) + Vector2(0.5, 0.5)) * tile
	var scale_factor := tile / 64.0
	var c: Color = unit.color
	var dark := c.darkened(0.55)
	if unit.leader:
		draw_arc(center, tile * 0.38, 0, TAU, 20, Color("ffe66d"), 3.0)
	draw_circle(center + Vector2(0, 17) * scale_factor, 17 * scale_factor, Color(0, 0, 0, 0.3))
	# Legs, torso/head (one head-part), then both arms.
	draw_colored_polygon(PackedVector2Array([center + Vector2(-12, 8)*scale_factor, center + Vector2(-2, 8)*scale_factor, center + Vector2(-5, 24)*scale_factor, center + Vector2(-15, 24)*scale_factor]), dark)
	draw_colored_polygon(PackedVector2Array([center + Vector2(2, 8)*scale_factor, center + Vector2(12, 8)*scale_factor, center + Vector2(15, 24)*scale_factor, center + Vector2(5, 24)*scale_factor]), dark)
	draw_rect(Rect2(center + Vector2(-13, -11)*scale_factor, Vector2(26, 25)*scale_factor), c, true)
	draw_circle(center + Vector2(0, -17)*scale_factor, 11*scale_factor, c.lightened(0.12))
	draw_circle(center + Vector2(-4, -18)*scale_factor, 2.4*scale_factor, Color("d9fffb"))
	draw_circle(center + Vector2(4, -18)*scale_factor, 2.4*scale_factor, Color("d9fffb"))
	draw_rect(Rect2(center + Vector2(-24, -7)*scale_factor, Vector2(10, 22)*scale_factor), dark, true)
	draw_rect(Rect2(center + Vector2(14, -7)*scale_factor, Vector2(10, 22)*scale_factor), dark, true)
