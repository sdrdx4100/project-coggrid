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
	# Destroying the enemy leader head stops battle and opens an explicit result.
	app.current_screen.battle.units[2].parts.head = 0
	app.current_screen.battle._check_victory()
	await process_frame
	_expect(app.current_screen.result_panel.visible, "leader destruction opens result panel")
	_expect(app.current_screen.pending_result == "win", "enemy leader destruction is a win")
	app.current_screen.confirm_result()
	await process_frame
	_expect(app.current_screen is OverworldScreen, "battle result returns to field")
	_expect(app.game_data.battles_won == 1, "confirmed victory updates RPG progress")
	_expect(app.game_data.roster[0].experience == MedalProgression.WIN_EXPERIENCE, "confirmed victory grants medal experience")
	app.show_battle()
	await process_frame
	app.current_screen.battle.units[0].parts.head = 0
	app.current_screen.battle._check_victory()
	await process_frame
	_expect(app.current_screen.result_panel.visible, "player leader destruction opens result panel")
	_expect(app.current_screen.pending_result == "loss", "player leader destruction is a loss")
	app.current_screen.confirm_result()
	await process_frame
	_expect(app.current_screen is OverworldScreen, "confirmed loss also returns to field")
	_expect(app.game_data.battles_won == 1, "loss does not increase victories")
	_expect(app.game_data.roster[0].experience == MedalProgression.WIN_EXPERIENCE + MedalProgression.LOSS_EXPERIENCE, "confirmed loss grants the smaller experience reward")
	if failures == 0:
		print("PASS: screen flow tests")
		quit(0)
	else:
		push_error("%d screen flow test(s) failed" % failures)
		quit(1)
