extends Control

var game_data := GameData.new()
var current_screen: Control
var menu: RpgMenu

func _ready() -> void:
	show_title()

func _replace_screen(screen: Control) -> void:
	if current_screen != null:
		remove_child(current_screen)
		current_screen.queue_free()
	current_screen = screen
	current_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(current_screen)

func show_title() -> void:
	if menu != null: menu.queue_free(); menu = null
	var title := TitleScreen.new()
	title.new_game_requested.connect(func(): game_data.new_game(); show_field())
	title.continue_requested.connect(func():
		if game_data.load_game(): show_field()
	)
	_replace_screen(title)

func show_field() -> void:
	var field := OverworldScreen.new()
	field.game_data = game_data
	field.battle_requested.connect(show_battle)
	field.menu_requested.connect(show_menu)
	_replace_screen(field)
	menu = RpgMenu.new()
	menu.closed.connect(func(): current_screen.set_process_unhandled_input(true))
	menu.title_requested.connect(show_title)
	menu.hide()
	add_child(menu)

func show_menu() -> void:
	if menu == null: return
	current_screen.set_process_unhandled_input(false)
	menu.open_for(game_data)

func show_battle() -> void:
	if menu != null: menu.queue_free(); menu = null
	var battle_screen := BattleScreen.new()
	battle_screen.game_data = game_data
	battle_screen.battle_completed.connect(_on_battle_completed)
	_replace_screen(battle_screen)

func _on_battle_completed(result: String) -> void:
	if result == "win": game_data.battles_won += 1
	show_field()
