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
	if tile < 8.0: return
	draw_rect(rect.grow(9), Color("0b1724"), true)
	draw_rect(rect.grow(5), Color("39506a"), false, 2.0)
	for y in SIZE:
		for x in SIZE:
			var cell := Vector2i(x, y)
			var cell_rect := Rect2(rect.position + Vector2(x, y) * tile, Vector2(tile, tile))
			var base := Color("344b46") if (x + y) % 2 == 0 else Color("2f4541")
			if BattleState.GENERATORS.has(cell):
				base = base.lerp(Color("27768a") if BattleState.GENERATORS[cell] == 0 else Color("873b50"), 0.38)
			if battle.phase == "move" and cell in battle.reachable_cells(): base = base.lerp(Color("43c6ff"), 0.18)
			var occupant := battle.unit_at(cell)
			if battle.phase == "target" and not occupant.is_empty() and occupant.id in battle.targetable_units():
				base = base.lerp(Color("ff4e66"), 0.26)
			if cell == hover_cell: base = base.lightened(0.14)
			draw_rect(cell_rect, base, true)
			draw_rect(cell_rect.grow(-1), Color("182b2a"), false, 1.0)
			if battle.phase == "move" and cell in battle.reachable_cells(): draw_rect(cell_rect.grow(-3), Color("6edcff"), false, 1.5)
			if battle.phase == "target" and not occupant.is_empty() and occupant.id in battle.targetable_units(): draw_rect(cell_rect.grow(-3), Color("ff7183"), false, 2.5)
			if BattleState.GENERATORS.has(cell): _draw_generator(cell_rect, BattleState.GENERATORS[cell])
	for unit in battle.units:
		if battle.is_active(unit): _draw_unit(rect, tile, unit)

func _draw_generator(rect: Rect2, team: int) -> void:
	var center := rect.get_center()
	var color := Color("7de7ff") if team == 0 else Color("ff8792")
	draw_colored_polygon(PackedVector2Array([center+Vector2(0,-rect.size.x*.28),center+Vector2(rect.size.x*.28,0),center+Vector2(0,rect.size.x*.28),center+Vector2(-rect.size.x*.28,0)]), Color(color, 0.18))
	draw_arc(center, rect.size.x * 0.25, 0, TAU, 8, color, 2.0)
	draw_arc(center, rect.size.x * 0.13, 0, TAU, 8, Color(color, 0.65), 2.0)

func _draw_unit(board_rect: Rect2, tile: float, unit: Dictionary) -> void:
	var center := board_rect.position + (Vector2(unit.cell) + Vector2(0.5, 0.5)) * tile
	var scale_factor := tile / 82.0
	if unit.leader:
		draw_arc(center, tile * 0.41, 0, TAU, 24, Color("ffe66d"), 2.5)
		draw_circle(center + Vector2(0, -tile*.37), tile*.075, Color("ffe66d"))
	RobotRenderer.draw_robot(self, center + Vector2(0, tile * 0.02), scale_factor, unit, true)
	if battle.should_auto_act(unit):
		draw_circle(center + Vector2(tile*.31, -tile*.31), tile*.105, Color("101a2a"))
		draw_string(ThemeDB.fallback_font, center + Vector2(tile*.255, -tile*.25), "A", HORIZONTAL_ALIGNMENT_CENTER, tile*.11, maxi(8, int(tile*.16)), Color("a8f4ff"))
