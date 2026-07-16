class_name SetupPanel
extends PanelContainer

signal closed

var battle: BattleState
var unit_id := -1
var title_label: Label
var rows := VBoxContainer.new()
var detail_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(620, 480)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	title_label = Label.new()
	title_label.add_theme_font_size_override("font_size", 26)
	layout.add_child(title_label)
	var help := Label.new()
	help.text = "所持パーツから4スロットを選択します。装甲と外見は即座に反映されます。"
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(help)
	layout.add_child(rows)
	detail_label = Label.new()
	detail_label.add_theme_color_override("font_color", Color("ffd98f"))
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(detail_label)
	var close_button := Button.new()
	close_button.text = "セッティング完了"
	close_button.pressed.connect(func(): hide(); closed.emit())
	layout.add_child(close_button)

func open_for(state: BattleState, target_unit_id: int) -> void:
	battle = state
	unit_id = target_unit_id
	_rebuild()
	show()

func _rebuild() -> void:
	for child in rows.get_children(): child.queue_free()
	var unit := battle.units[unit_id]
	title_label.text = "SETTING — " + unit.name
	for slot in PartData.SLOTS:
		var line := HBoxContainer.new()
		var label := Label.new()
		label.text = battle.part_label(slot)
		label.custom_minimum_size.x = 70
		line.add_child(label)
		var options := OptionButton.new()
		options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var available := battle.available_parts(unit.team, slot, unit_id)
		for part: PartData in available:
			options.add_item("%s　%s" % [part.display_name, part.summary()])
			options.set_item_metadata(options.item_count - 1, part.id)
			if battle.equipped_part(unit, slot).id == part.id: options.select(options.item_count - 1)
		options.item_selected.connect(_on_part_selected.bind(slot, options))
		line.add_child(options)
		rows.add_child(line)
	_update_detail()

func _on_part_selected(index: int, slot: String, options: OptionButton) -> void:
	var part_id: String = options.get_item_metadata(index)
	battle.equip_part(unit_id, slot, part_id)
	_update_detail()

func _update_detail() -> void:
	var unit := battle.units[unit_id]
	var names := PackedStringArray()
	for slot in PartData.SLOTS:
		names.append("%s: %s" % [battle.part_label(slot), battle.equipped_part(unit, slot).display_name])
	detail_label.text = "　".join(names) + "\n推進 %d　回避 %d　防御 %d" % [unit.propulsion, battle.evasion_value(unit), battle.defense_value(unit)]
