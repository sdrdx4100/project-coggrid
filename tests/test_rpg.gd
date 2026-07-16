extends SceneTree

var failures := 0

func _initialize() -> void:
	_test_medal_progression()
	_test_roster_equipment_reaches_battle()
	_test_battle_experience()
	_test_save_and_load()
	_test_v1_save_migration()
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
	_expect(data.roster[0].controllable and not data.roster[1].controllable, "new game assigns manual leader and auto partner")
	_expect(data.equip(0, "right", "prism_cannon"), "RPG menu data can equip an owned part")
	var battle := BattleState.new()
	battle.setup_demo(data.player_loadouts())
	_expect(battle.equipped_part(battle.units[0], "right").id == "prism_cannon", "battle receives the RPG loadout")
	_expect(battle.action_data("right", battle.units[0]).damage == 17, "battle uses equipped RPG part stats")

func _test_medal_progression() -> void:
	_expect(MedalProgression.level_for_experience(0) == 1, "new medals begin at level 1")
	_expect(MedalProgression.level_for_experience(21) == 2, "experience raises medal level")
	_expect(is_equal_approx(MedalProgression.success_bonus(1), 0.0), "level 1 has no success bonus")
	_expect(is_equal_approx(MedalProgression.success_bonus(20), 0.4), "success grows by 0.1 every five levels")
	_expect(is_equal_approx(MedalProgression.success_bonus(99), 1.9), "success bonus remains capped below 2.0")
	_expect(MedalProgression.ai_profile_for_level(19) == AiProfile.GENERAL, "low-level ally auto AI stays general")
	_expect(MedalProgression.ai_profile_for_level(20) == AiProfile.ELITE, "level 20 unlocks elite ally auto AI")
	_expect(MedalProgression.unlocked_medaforces(1).size() == 1, "one medaforce is available initially")
	_expect(MedalProgression.unlocked_medaforces(40).size() == 3, "higher levels unlock more medaforce choices")

func _test_battle_experience() -> void:
	var data := GameData.new()
	data.new_game()
	_expect(data.grant_battle_experience("retreat") == 0, "retreat gives no experience")
	_expect(data.grant_battle_experience("win") == 30, "victory grants the configured experience")
	_expect(data.member_level(data.roster[0]) == 2, "first victory raises a new medal to level 2")
	_expect(data.roster[1].experience == 30, "all participating roster members gain experience")
	data.roster[0].experience = MedalProgression.experience_for_level(20)
	var battle := BattleState.new()
	battle.setup_demo(data.player_battle_members())
	_expect(battle.units[0].level == 20, "medal level reaches battle units")
	_expect(battle.units[0].ai_profile == AiProfile.ELITE, "ally auto AI profile reaches battle units")
	_expect(battle.units[0].medaforces.size() == 2, "unlocked medaforces reach battle units")
	_expect(is_equal_approx(battle.hit_chance(battle.units[0], battle.units[2], "right"), 72.0), "level 20 adds only a small hit chance bonus")
	_expect(battle.action_data("right", battle.units[0]).damage == 10, "level never changes part damage")

func _test_save_and_load() -> void:
	var data := GameData.new()
	data.new_game()
	data.player_cell = Vector2i(8, 9)
	data.battles_won = 3
	data.roster[0].experience = 125
	data.equip(0, "legs", "hover_base")
	_expect(data.save_game(), "game data saves")
	var loaded := GameData.new()
	_expect(loaded.load_game(), "game data loads")
	_expect(loaded.player_cell == Vector2i(8, 9), "field position survives save")
	_expect(loaded.battles_won == 3, "progress survives save")
	_expect(loaded.roster[0].experience == 125, "medal experience survives save")
	_expect(loaded.roster[0].controllable and not loaded.roster[1].controllable, "control modes survive save")
	_expect(loaded.roster[0].loadout.legs == "hover_base", "equipment survives save")

func _test_v1_save_migration() -> void:
	var legacy := {
		"version":1,
		"player_cell":[3,10],
		"battles_won":1,
		"inventory":{"cog_sensor":1,"bolt_rifle":1,"impact_knuckle":1,"walker_legs":1},
		"roster":[{"name":"LEGACY","leader":true,"loadout":{"head":"cog_sensor","right":"bolt_rifle","left":"impact_knuckle","legs":"walker_legs"}}],
	}
	var file := FileAccess.open(GameData.SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var loaded := GameData.new()
	_expect(loaded.load_game(), "version 1 saves remain loadable")
	_expect(loaded.roster[0].experience == 0, "legacy saves start with zero experience")
	_expect(loaded.member_level(loaded.roster[0]) == 1, "legacy saves migrate to level 1")
	_expect(loaded.roster[0].controllable, "legacy leaders default to manual control")
	_expect(typeof(loaded.inventory.cog_sensor) == TYPE_INT, "JSON inventory counts normalize back to integers")
