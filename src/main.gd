class_name BattleScreen
extends Control

signal battle_completed(result: String)

var battle := BattleState.new()
var board: GridBoard
var portrait: RobotPortrait
var unit_name: Label
var ap_label: Label
var mf_label: Label
var phase_label: Label
var parts_box: VBoxContainer
var action_box: VBoxContainer
var message: Label
var turn_label: Label
var ai_pending := false
var setup_panel: SetupPanel
var game_data: GameData
var input_locked := true
var intro_panel: PanelContainer
var result_panel: PanelContainer
var result_title: Label
var result_detail: Label
var pending_result := ""

func _ready() -> void:
	_build_ui()
	battle.changed.connect(_refresh)
	battle.log_added.connect(_on_log)
	battle.battle_finished.connect(_on_battle_finished)
	battle.setup_demo(game_data.player_loadouts() if game_data != null else [])
	_show_battle_intro()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("0a1020")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var root := HBoxContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_theme_constant_override("separation", 0)
	add_child(root)

	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size = Vector2(410, 0)
	sidebar.add_theme_constant_override("separation", 8)
	root.add_child(sidebar)

	var header := VBoxContainer.new()
	header.custom_minimum_size.y = 100
	header.add_theme_constant_override("separation", 1)
	sidebar.add_child(header)
	unit_name = _label("---", 30, Color("eef6ff"))
	ap_label = _label("AP", 24, Color("8de8ff"))
	mf_label = _label("MF", 18, Color("8fffc1"))
	header.add_child(unit_name)
	header.add_child(ap_label)
	header.add_child(mf_label)

	portrait = RobotPortrait.new()
	portrait.custom_minimum_size = Vector2(390, 305)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sidebar.add_child(portrait)

	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 190
	sidebar.add_child(bottom)
	parts_box = VBoxContainer.new()
	parts_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_box = VBoxContainer.new()
	action_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(parts_box)
	bottom.add_child(action_box)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	var topbar := HBoxContainer.new()
	topbar.custom_minimum_size.y = 46
	turn_label = _label("TURN", 22, Color("8fffc1"))
	phase_label = _label("", 18, Color("d7e2ff"))
	phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	topbar.add_child(turn_label)
	topbar.add_child(phase_label)
	var retreat := Button.new()
	retreat.text = "フィールドへ戻る"
	retreat.pressed.connect(func(): battle_completed.emit("retreat"))
	topbar.add_child(retreat)
	right.add_child(topbar)
	board = GridBoard.new()
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.cell_clicked.connect(_on_cell_clicked)
	right.add_child(board)
	message = _label("", 18, Color("e4fff3"))
	message.custom_minimum_size.y = 52
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(message)
	board.bind(battle)

	setup_panel = SetupPanel.new()
	setup_panel.set_anchors_preset(Control.PRESET_CENTER)
	setup_panel.position = Vector2(-310, -240)
	setup_panel.closed.connect(_refresh)
	setup_panel.hide()
	add_child(setup_panel)
	_build_battle_overlays()

func _build_battle_overlays() -> void:
	intro_panel = PanelContainer.new()
	intro_panel.set_anchors_preset(Control.PRESET_CENTER)
	intro_panel.position = Vector2(-260, -90)
	intro_panel.custom_minimum_size = Vector2(520, 180)
	intro_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var intro := VBoxContainer.new()
	intro.alignment = BoxContainer.ALIGNMENT_CENTER
	intro_panel.add_child(intro)
	var intro_title := _label("ROBATTLE START", 38, Color("8de8ff"))
	intro_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_child(intro_title)
	var objective := _label("相手リーダーの頭部パーツを破壊せよ", 18, Color("eaf0ff"))
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	intro.add_child(objective)
	intro_panel.hide()
	add_child(intro_panel)

	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.position = Vector2(-300, -170)
	result_panel.custom_minimum_size = Vector2(600, 340)
	result_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var result := VBoxContainer.new()
	result.alignment = BoxContainer.ALIGNMENT_CENTER
	result.add_theme_constant_override("separation", 18)
	result_panel.add_child(result)
	result_title = _label("", 48, Color("8fffc1"))
	result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_child(result_title)
	result_detail = _label("", 20, Color("eaf0ff"))
	result_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_child(result_detail)
	var return_button := Button.new()
	return_button.text = "フィールドへ戻る"
	return_button.pressed.connect(confirm_result)
	result.add_child(return_button)
	result_panel.hide()
	add_child(result_panel)

func _show_battle_intro() -> void:
	input_locked = true
	intro_panel.show()
	get_tree().create_timer(1.0).timeout.connect(func():
		if not is_instance_valid(self) or battle.phase == "finished": return
		intro_panel.hide()
		input_locked = false
		_refresh()
	)

func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color("172039"))
	return label

func _refresh() -> void:
	var unit := battle.current_unit()
	turn_label.text = " TURN %02d " % battle.round_number
	phase_label.text = _phase_text()
	if unit.is_empty(): return
	unit_name.text = ("LEADER  " if unit.leader else "MEMBER  ") + unit.name
	ap_label.text = "AP  %02d / %02d pt" % [unit.ap, unit.max_ap]
	mf_label.text = "MF  %03d pt" % unit.mf
	portrait.show_unit(unit)
	_rebuild_parts(unit)
	_rebuild_actions(unit)
	if unit.team == 1 and battle.phase != "finished" and not input_locked and not ai_pending:
		ai_pending = true
		get_tree().create_timer(0.55).timeout.connect(func():
			ai_pending = false
			if battle.current_unit().get("team", 0) == 1: battle.auto_act()
		)

func _rebuild_parts(unit: Dictionary) -> void:
	for child in parts_box.get_children(): child.queue_free()
	parts_box.add_child(_label("PARTS", 16, Color("8de8ff")))
	for part in ["head", "right", "left", "legs"]:
		var value: int = unit.parts[part]
		var maximum: int = unit.parts_max[part]
		var equipped := battle.equipped_part(unit, part)
		var label := _label("%s %s  %02d/%02d" % [battle.part_label(part), equipped.display_name, value, maximum], 14, Color("ff8390") if value == 0 else Color("eaf0ff"))
		parts_box.add_child(label)

func _rebuild_actions(unit: Dictionary) -> void:
	for child in action_box.get_children(): child.queue_free()
	action_box.add_child(_label("ACTION", 16, Color("8fffc1")))
	for action in ["head", "right", "left", "move"]:
		var data := battle.action_data(action, unit)
		var button := Button.new()
		button.text = "%s  AP %d" % [data.label, data.cost]
		button.disabled = input_locked or unit.team == 1 or battle.phase != "choose" or unit.ap < data.cost or (action != "move" and unit.parts[action] <= 0)
		button.pressed.connect(func(): battle.choose_action(action))
		action_box.add_child(button)
	if battle.can_reconfigure(unit.id):
		var setup := Button.new()
		setup.text = "セッティング"
		setup.pressed.connect(func(): setup_panel.open_for(battle, unit.id))
		action_box.add_child(setup)
	if battle.phase in ["move", "target"] and unit.team == 0:
		var skip := Button.new()
		skip.text = "行動終了"
		skip.pressed.connect(battle.finish_action)
		action_box.add_child(skip)

func _phase_text() -> String:
	match battle.phase:
		"choose": return "使用パーツを選択"
		"move": return "残りAPで移動先を選択"
		"target": return "攻撃対象を選択"
		"finished": return "ROBATTLE FINISHED"
	return ""

func _on_cell_clicked(cell: Vector2i) -> void:
	var unit := battle.current_unit()
	if input_locked or unit.is_empty() or unit.team == 1: return
	if battle.phase == "move":
		battle.move_current(cell)
	elif battle.phase == "target":
		var target := battle.unit_at(cell)
		if not target.is_empty(): battle.attack(target.id)

func _on_log(text: String) -> void:
	message.text = "  " + text

func _on_battle_finished(text: String) -> void:
	input_locked = true
	intro_panel.hide()
	pending_result = "win" if battle.winner == 0 else "loss"
	result_title.text = "YOU WIN" if pending_result == "win" else "YOU LOSE"
	result_title.add_theme_color_override("font_color", Color("8fffc1") if pending_result == "win" else Color("ff8390"))
	result_detail.text = "%s\nTURN %d　勝利条件：リーダー頭部の破壊" % [text, battle.round_number]
	result_panel.show()
	result_panel.move_to_front()
	_on_log(text)

func confirm_result() -> void:
	if pending_result == "": return
	var result := pending_result
	pending_result = ""
	result_panel.hide()
	battle_completed.emit(result)
