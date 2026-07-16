class_name TitleScreen
extends Control

signal new_game_requested
signal continue_requested

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("071126")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-230, -160)
	center.custom_minimum_size = Vector2(460, 320)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_theme_constant_override("separation", 18)
	add_child(center)
	var title := Label.new()
	title.text = "PROJECT\nCOGGRID"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color("8de8ff"))
	center.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "NAVI-STYLE ROBOT TACTICAL RPG"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color("8fffc1"))
	center.add_child(subtitle)
	var start := Button.new()
	start.text = "NEW GAME"
	start.pressed.connect(new_game_requested.emit)
	center.add_child(start)
	var resume := Button.new()
	resume.text = "CONTINUE"
	resume.disabled = not FileAccess.file_exists(GameData.SAVE_PATH)
	resume.pressed.connect(continue_requested.emit)
	center.add_child(resume)
	var note := Label.new()
	note.text = "Prototype 0.2"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_color_override("font_color", Color("66789b"))
	center.add_child(note)
