class_name OverworldScreen
extends Control

signal battle_requested
signal menu_requested

const MAP_SIZE := Vector2i(18, 13)
const NPC_CELL := Vector2i(11, 4)
var game_data: GameData
var status_label: Label
var dialog: PanelContainer

func _ready() -> void:
	set_process_unhandled_input(true)
	var header := HBoxContainer.new()
	header.set_anchors_preset(Control.PRESET_TOP_WIDE)
	header.custom_minimum_size.y = 54
	header.add_theme_constant_override("separation", 20)
	add_child(header)
	var area := Label.new()
	area.text = " COGTOWN / CENTRAL LAB"
	area.add_theme_font_size_override("font_size", 22)
	area.add_theme_color_override("font_color", Color("8de8ff"))
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(area)
	status_label = Label.new()
	header.add_child(status_label)
	var menu := Button.new()
	menu.text = "MENU [M]"
	menu.pressed.connect(menu_requested.emit)
	header.add_child(menu)
	_build_dialog()
	queue_redraw()

func _build_dialog() -> void:
	dialog = PanelContainer.new()
	dialog.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	dialog.position = Vector2(-360, -205)
	dialog.custom_minimum_size = Vector2(720, 180)
	dialog.hide()
	add_child(dialog)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 9)
	dialog.add_child(box)
	var speaker := Label.new()
	speaker.text = "ロボトル研究員"
	speaker.add_theme_color_override("font_color", Color("ffcf70"))
	speaker.add_theme_font_size_override("font_size", 20)
	box.add_child(speaker)
	var text := Label.new()
	text.text = "ちょうどテスト相手を探していたんだ。\nセッティングが済んでいるなら、ロボトルしてみるかい？"
	box.add_child(text)
	var buttons := HBoxContainer.new()
	box.add_child(buttons)
	var fight := Button.new()
	fight.text = "ロボトルする"
	fight.pressed.connect(battle_requested.emit)
	buttons.add_child(fight)
	var close := Button.new()
	close.text = "また今度"
	close.pressed.connect(dialog.hide)
	buttons.add_child(close)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or dialog.visible or not event is InputEventKey or not event.pressed or event.echo: return
	var delta := Vector2i.ZERO
	match event.physical_keycode:
		KEY_UP, KEY_W: delta = Vector2i.UP
		KEY_DOWN, KEY_S: delta = Vector2i.DOWN
		KEY_LEFT, KEY_A: delta = Vector2i.LEFT
		KEY_RIGHT, KEY_D: delta = Vector2i.RIGHT
		KEY_M, KEY_ESCAPE: menu_requested.emit(); return
		KEY_ENTER, KEY_SPACE:
			if _distance(game_data.player_cell, NPC_CELL) == 1: dialog.show()
			return
	if delta != Vector2i.ZERO:
		var destination := game_data.player_cell + delta
		if _walkable(destination): game_data.player_cell = destination
		queue_redraw()

func _walkable(cell: Vector2i) -> bool:
	if cell.x <= 0 or cell.y <= 0 or cell.x >= MAP_SIZE.x - 1 or cell.y >= MAP_SIZE.y - 1: return false
	if cell == NPC_CELL: return false
	if cell.y == 6 and cell.x in [5, 6, 7, 10, 11, 12]: return false
	return true

func _distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _board_rect() -> Rect2:
	var tile: float = min((size.x - 40.0) / MAP_SIZE.x, (size.y - 100.0) / MAP_SIZE.y)
	var board_size: Vector2 = Vector2(MAP_SIZE) * tile
	return Rect2(Vector2((size.x - board_size.x) * 0.5, 68), board_size)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("0b1724"), true)
	if game_data == null: return
	var rect := _board_rect()
	var tile := rect.size.x / MAP_SIZE.x
	for y in MAP_SIZE.y:
		for x in MAP_SIZE.x:
			var cell := Vector2i(x, y)
			var cell_rect := Rect2(rect.position + Vector2(cell) * tile, Vector2(tile, tile))
			var color := Color("496d57") if (x + y) % 2 == 0 else Color("42654e")
			if not _walkable(cell) and cell != NPC_CELL: color = Color("293b46")
			if y == 6 and x in [5, 6, 7, 10, 11, 12]: color = Color("69757d")
			draw_rect(cell_rect, color, true)
			draw_rect(cell_rect, Color(0.08, 0.13, 0.16, 0.32), false, 1)
	_draw_actor(rect, tile, NPC_CELL, Color("ff9e54"), false)
	_draw_actor(rect, tile, game_data.player_cell, Color("55b9ff"), true)
	status_label.text = "勝利 %d　　移動: WASD/矢印　会話: Enter　" % game_data.battles_won

func _draw_actor(rect: Rect2, tile: float, cell: Vector2i, color: Color, player: bool) -> void:
	var center := rect.position + (Vector2(cell) + Vector2(0.5, 0.5)) * tile
	draw_circle(center + Vector2(0, tile * 0.23), tile * 0.22, Color(0, 0, 0, 0.3))
	draw_rect(Rect2(center - Vector2(tile * 0.2, tile * 0.05), Vector2(tile * 0.4, tile * 0.38)), color.darkened(0.18), true)
	draw_circle(center - Vector2(0, tile * 0.17), tile * 0.21, color)
	if player: draw_colored_polygon(PackedVector2Array([center+Vector2(-tile*.26,-tile*.12),center+Vector2(-tile*.4,0),center+Vector2(-tile*.23,tile*.04)]), Color("d9fffb"))
