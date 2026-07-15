extends SceneTree

var failures := 0

func _initialize() -> void:
	_test_action_flow()
	_test_generator_capture()
	if failures == 0:
		print("PASS: battle model tests")
		quit(0)
	else:
		push_error("%d battle model test(s) failed" % failures)
		quit(1)

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _test_action_flow() -> void:
	var battle := BattleState.new()
	battle.setup_demo()
	_expect(battle.round_number == 1, "battle starts on turn 1")
	_expect(battle.current_unit().name == "COG-01", "highest propulsion unit acts first")
	_expect(battle.current_unit().ap == 16, "AP uses base plus propulsion")
	_expect(battle.choose_action("right"), "right arm can be selected")
	_expect(battle.current_unit().ap == 8, "part AP is paid before movement")
	_expect(battle.move_current(Vector2i(5, 2)), "unit can move with remaining AP")
	_expect(battle.phase == "target", "attack target follows movement")
	var hp_before: int = battle.units[2].parts.head + battle.units[2].parts.right + battle.units[2].parts.left + battle.units[2].parts.legs
	_expect(battle.attack(2), "enemy in range can be attacked")
	var hp_after: int = battle.units[2].parts.head + battle.units[2].parts.right + battle.units[2].parts.left + battle.units[2].parts.legs
	_expect(hp_after < hp_before, "attack damages one part")
	_expect(battle.units[0].mf == 1, "unused AP becomes MF")

func _test_generator_capture() -> void:
	var battle := BattleState.new()
	battle.setup_demo()
	battle.units[2].cell = Vector2i(1, 1)
	battle._start_round()
	_expect(battle.units[0].ap == 12, "captured friendly generator reduces team AP by 25 percent")
	_expect(battle.units[2].ap == 22, "capturing unit gets generator bonus without penalizing its own team")
