extends SceneTree

var failures := 0

func _initialize() -> void:
	_test_action_flow()
	_test_generator_capture()
	_test_defense_values()
	_test_evasion()
	_test_part_catalog_and_equipment()
	_test_action_taxonomy()
	_test_ai_profiles()
	_test_unit_id_index()
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

func _setup_standard_battle(battle: BattleState) -> void:
	battle.setup_demo([
		{"head":"cog_sensor","right":"bolt_rifle","left":"impact_knuckle","legs":"walker_legs"},
		{"head":"fortress_core","right":"prism_cannon","left":"needle_claw","legs":"walker_legs"},
	])

func _test_action_flow() -> void:
	var battle := BattleState.new()
	_setup_standard_battle(battle)
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
	_expect(battle.last_attack.outcome == "hit", "attack lands when hit roll beats evasion")
	_expect(battle.last_attack.part == "right", "damaged part is deterministic")
	_expect(battle.last_attack.damage == 4, "defense and leader guard reduce damage (10 - 4 - 2)")
	_expect(battle.units[0].mf == 1, "unused AP becomes MF")

func _test_defense_values() -> void:
	var battle := BattleState.new()
	_setup_standard_battle(battle)
	var attacker := battle.units[0] # COG-01, propulsion 13
	var target := battle.units[2] # RIVET-R, propulsion 12, full legs
	_expect(battle.evasion_value(target) == 8, "full legs give evasion")
	_expect(battle.defense_value(target) == 4, "full legs give defense")
	_expect(battle.hit_chance(attacker, target, "right") == 70, "hit chance combines success and evasion")
	target.parts.legs = 0
	_expect(battle.evasion_value(target) == 0, "broken legs remove evasion")
	_expect(battle.defense_value(target) == 0, "broken legs remove defense")
	_expect(battle.hit_chance(attacker, target, "right") == 95, "immobile targets are almost always hit")

func _test_evasion() -> void:
	var battle := BattleState.new()
	_setup_standard_battle(battle)
	battle.units[0].cell = Vector2i(5, 3)
	battle.units[2].cell = Vector2i(6, 3)
	_expect(battle.choose_action("left"), "left arm can be selected")
	_expect(battle.move_current(Vector2i(5, 3)), "unit can hold position")
	_expect(battle.phase == "target", "attack target follows movement")
	var hp_before: int = battle.units[2].parts.head + battle.units[2].parts.right + battle.units[2].parts.left + battle.units[2].parts.legs
	_expect(battle.attack(2), "attack resolves even on a miss")
	var hp_after: int = battle.units[2].parts.head + battle.units[2].parts.right + battle.units[2].parts.left + battle.units[2].parts.legs
	_expect(battle.last_attack.outcome == "evade", "high roll versus evasion is dodged")
	_expect(hp_after == hp_before, "evaded attack deals no damage")

func _test_generator_capture() -> void:
	var battle := BattleState.new()
	_setup_standard_battle(battle)
	battle.units[2].cell = Vector2i(1, 1)
	battle._start_round()
	_expect(battle.units[0].ap == 12, "captured friendly generator reduces team AP by 25 percent")
	_expect(battle.units[2].ap == 22, "capturing unit gets generator bonus without penalizing its own team")

func _test_part_catalog_and_equipment() -> void:
	var battle := BattleState.new()
	_setup_standard_battle(battle)
	var unit := battle.units[0]
	_expect(battle.catalog.get_part("cog_sensor").slot == "head", "catalog stores independent part data")
	_expect(battle.available_parts(0, "head").size() == 2, "inventory exposes owned head parts")
	_expect(battle.equipped_part(unit, "head").id == "cog_sensor", "unit has a four-slot loadout")
	_expect(battle.equip_part(0, "head", "fortress_core"), "owned matching part can be equipped")
	_expect(battle.equipped_part(unit, "head").id == "fortress_core", "equipment slot changes")
	_expect(unit.parts.head == 52 and unit.parts_max.head == 52, "equipping restores the new part armor")
	_expect(battle.action_data("head", unit).label == "ヘビープレス", "equipped part supplies its action")
	_expect(not battle.equip_part(0, "right", "hover_base"), "part cannot enter the wrong slot")
	_expect(battle.equip_part(0, "legs", "hover_base"), "owned legs can be equipped")
	_expect(unit.propulsion == 16, "leg part supplies propulsion")
	battle.choose_action("head")
	_expect(not battle.equip_part(0, "head", "cog_sensor"), "loadout cannot change after action begins")

func _test_action_taxonomy() -> void:
	var catalog := PartCatalog.new()
	var beam := catalog.get_part("prism_cannon").action
	var missile := catalog.get_part("blast_launcher").action
	var hammer := catalog.get_part("impact_knuckle").action
	var sensor := catalog.get_part("cog_sensor").action
	_expect(beam.action_class == PartAction.CLASS_SHOOT, "beam belongs to shoot class")
	_expect(beam.attack_family == PartAction.FAMILY_OPTICAL, "beam belongs to optical family")
	_expect(missile.action_class == PartAction.CLASS_SHOOT, "missile belongs to shoot class")
	_expect(missile.attack_family == PartAction.FAMILY_GUNPOWDER, "missile belongs to gunpowder family")
	_expect(hammer.action_class == PartAction.CLASS_STRIKE, "hammer belongs to strike class")
	_expect(sensor.action_class == PartAction.CLASS_SUPPORT and "scan" in sensor.effect_ids, "support actions can declare future effects")
	_expect(not sensor.is_attack(), "support is distinct from attack classes")

func _test_ai_profiles() -> void:
	var general := AiProfile.create(AiProfile.GENERAL)
	var elite := AiProfile.create(AiProfile.ELITE)
	var boss := AiProfile.create(AiProfile.BOSS)
	_expect(general.choice_pool == 3, "general AI varies among its top three choices")
	_expect(elite.choice_pool == 2, "elite AI varies among its top two choices")
	_expect(boss.choice_pool == 1, "boss AI always takes its highest-scored choice")

	var battle := BattleState.new()
	_setup_standard_battle(battle)
	_expect(battle.units[2].ai_profile == AiProfile.BOSS, "enemy leader uses the boss profile")
	_expect(battle.units[3].ai_profile == AiProfile.ELITE, "enemy partner uses the elite profile")

	var actor: Dictionary = battle.units[2]
	actor.cell = Vector2i(4, 4)
	battle.units[0].cell = Vector2i(3, 4)
	battle.units[1].cell = Vector2i(5, 4)
	var first: Dictionary = BattleAi.new().choose_action(battle, actor)
	var second: Dictionary = BattleAi.new().choose_action(battle, actor)
	_expect(not first.is_empty(), "AI produces a legal tactical decision")
	_expect(first == second, "AI choice is deterministic for the same battle state")
	_expect(first.target_id == battle.units[0].id, "boss profile prioritizes the enemy leader")

func _test_unit_id_index() -> void:
	var battle := BattleState.new()
	_setup_standard_battle(battle)
	var replacement_ids := [10, 20, 30, 40]
	for index in battle.units.size(): battle.units[index].id = replacement_ids[index]
	battle.units.reverse()
	battle._rebuild_unit_index()
	battle.unit_by_id(10).propulsion = 20
	battle.round_number = 0
	battle._start_round()
	_expect(battle.current_unit().id == 10, "turn order resolves non-contiguous ids after unit reordering")
	_expect(battle.can_reconfigure(10), "configuration resolves a unit by id rather than array position")
	_expect(battle.equip_part(10, "head", "fortress_core"), "equipment changes resolve a reordered unit by id")
	_expect(battle.choose_action("right"), "reordered unit can choose an action")
	_expect(battle.move_current(Vector2i(5, 2)), "reordered unit can move")
	_expect(battle.attack(30), "target lookup resolves a non-contiguous id")
