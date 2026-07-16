class_name RpgMenu
extends PanelContainer

signal closed
signal title_requested

var game_data: GameData
var member_index := 0
var member_options: OptionButton
var part_rows := VBoxContainer.new()
var detail := Label.new()
var notice := Label.new()

func _ready() -> void:
	set_anchors_preset(Control.PRESET_CENTER)
	position = Vector2(-390, -300)
	custom_minimum_size = Vector2(780, 600)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]: margin.add_theme_constant_override("margin_" + side, 22)
	add_child(margin)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)
	var heading := Label.new()
	heading.text = "ROBOT MENU / SETTING"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("8de8ff"))
	root.add_child(heading)
	member_options = OptionButton.new()
	member_options.item_selected.connect(func(index: int): member_index = index; _rebuild_parts())
	root.add_child(member_options)
	root.add_child(part_rows)
	detail.add_theme_color_override("font_color", Color("ffd98f"))
	root.add_child(detail)
	notice.add_theme_color_override("font_color", Color("8fffc1"))
	root.add_child(notice)
	var controls := HBoxContainer.new()
	root.add_child(controls)
	var save := Button.new()
	save.text = "セーブ"
	save.pressed.connect(func(): notice.text = "セーブしました。" if game_data.save_game() else "セーブに失敗しました。")
	controls.add_child(save)
	var title := Button.new()
	title.text = "タイトルへ"
	title.pressed.connect(title_requested.emit)
	controls.add_child(title)
	var close := Button.new()
	close.text = "フィールドへ戻る"
	close.pressed.connect(func(): hide(); closed.emit())
	controls.add_child(close)

func open_for(data: GameData) -> void:
	game_data = data
	member_options.clear()
	for member in game_data.roster:
		var control_label := "手動" if bool(member.get("controllable", member.leader)) else "AUTO"
		member_options.add_item(("LEADER  " if member.leader else "MEMBER  ") + member.name + "  Lv.%d  [%s]" % [game_data.member_level(member), control_label])
	member_index = clampi(member_index, 0, game_data.roster.size() - 1)
	member_options.select(member_index)
	notice.text = ""
	_rebuild_parts()
	show()

func _rebuild_parts() -> void:
	for child in part_rows.get_children(): child.queue_free()
	var member := game_data.roster[member_index]
	for slot in PartData.SLOTS:
		var line := HBoxContainer.new()
		var slot_label := Label.new()
		slot_label.text = {"head":"頭部","right":"右腕","left":"左腕","legs":"脚部"}[slot]
		slot_label.custom_minimum_size.x = 70
		line.add_child(slot_label)
		var options := OptionButton.new()
		options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		for part: PartData in game_data.available_parts(slot, member_index):
			options.add_item("%s　%s" % [part.display_name, part.summary()])
			options.set_item_metadata(options.item_count - 1, part.id)
			if member.loadout[slot] == part.id: options.select(options.item_count - 1)
		options.item_selected.connect(_on_part_selected.bind(slot, options))
		line.add_child(options)
		part_rows.add_child(line)
	_update_detail()

func _on_part_selected(index: int, slot: String, options: OptionButton) -> void:
	var part_id: String = options.get_item_metadata(index)
	if game_data.equip(member_index, slot, part_id): notice.text = "%sを装着しました。" % game_data.catalog.get_part(part_id).display_name
	_update_detail()

func _update_detail() -> void:
	var member := game_data.roster[member_index]
	var legs := game_data.catalog.get_part(member.loadout.legs)
	var level := game_data.member_level(member)
	var experience := int(member.get("experience", 0))
	var next_experience := MedalProgression.experience_for_level(mini(level + 1, MedalProgression.MAX_LEVEL))
	var ai_label := "強敵" if MedalProgression.ai_profile_for_level(level) == AiProfile.ELITE else "一般"
	var control_label := "手動" if bool(member.get("controllable", member.leader)) else "AUTO"
	var mf_names := PackedStringArray()
	for medaforce in MedalProgression.unlocked_medaforces(level): mf_names.append(medaforce.name)
	detail.text = "機体: %s　Lv.%d　EXP %d/%d　成功補正 +%.1f\n推進 %d　基礎回避 %d　防御 %d　操作 %s（AI %s）\nMF: %s" % [member.name, level, experience, next_experience, MedalProgression.success_bonus(level), legs.propulsion, legs.evasion_base, legs.defense_base, control_label, ai_label, " / ".join(mf_names)]
