extends SceneTree

var failures := 0

func _initialize() -> void:
	_test_roster_equipment_reaches_battle()
	_test_save_and_load()
	if failures == 0:
		print("PASS: RPG data tests")
		quit(0)
	else:
		push_error("%d RPG data test(s) failed" % failures)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _test_roster_equipment_reaches_battle() -> void:
	var data := GameData.new()
	data.new_game()
	_expect(data.roster.size() == 2, "new game creates a two-unit roster")
	_expect(data.equip(0, "right", "prism_cannon"), "RPG menu data can equip an owned part")
	var battle := BattleState.new()
	battle.setup_demo(data.player_loadouts())
	_expect(battle.equipped_part(battle.units[0], "right").id == "prism_cannon", "battle receives the RPG loadout")
	_expect(battle.action_data("right", battle.units[0]).damage == 17, "battle uses equipped RPG part stats")

func _test_save_and_load() -> void:
	var data := GameData.new()
	data.new_game()
	data.player_cell = Vector2i(8, 9)
	data.battles_won = 3
	data.equip(0, "legs", "hover_base")
	_expect(data.save_game(), "game data saves")
	var loaded := GameData.new()
	_expect(loaded.load_game(), "game data loads")
	_expect(loaded.player_cell == Vector2i(8, 9), "field position survives save")
	_expect(loaded.battles_won == 3, "progress survives save")
	_expect(loaded.roster[0].loadout.legs == "hover_base", "equipment survives save")
