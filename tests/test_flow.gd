extends SceneTree

var failures := 0

func _initialize() -> void:
	_run.call_deferred()

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var app = packed.instantiate()
	root.add_child(app)
	await process_frame
	_expect(app.current_screen is TitleScreen, "game opens on title screen")
	app.game_data.new_game()
	app.show_field()
	await process_frame
	_expect(app.current_screen is OverworldScreen, "new game opens field")
	app.show_menu()
	await process_frame
	_expect(app.menu.visible, "field menu opens")
	app.menu.hide()
	app.show_battle()
	await process_frame
	_expect(app.current_screen is BattleScreen, "NPC flow can open battle")
	_expect(app.current_screen.battle.equipped_part(app.current_screen.battle.units[0], "head").id == "cog_sensor", "battle receives field roster")
	app.current_screen.battle_completed.emit("retreat")
	await process_frame
	_expect(app.current_screen is OverworldScreen, "battle result returns to field")
	if failures == 0:
		print("PASS: screen flow tests")
		quit(0)
	else:
		push_error("%d screen flow test(s) failed" % failures)
		quit(1)
