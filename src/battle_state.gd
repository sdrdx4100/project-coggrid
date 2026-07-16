class_name BattleState
extends RefCounted

signal changed
signal log_added(message: String)
signal battle_finished(message: String)

const BOARD_SIZE := 9
const CONTROL_PLAYER := "player"
const CONTROL_AUTO := "auto"
const GENERATORS := {
	Vector2i(1, 1): 0, Vector2i(1, 7): 0,
	Vector2i(7, 1): 1, Vector2i(7, 7): 1,
}

var units: Array[Dictionary] = []
var units_by_id: Dictionary = {}
var round_number := 0
var action_order: Array[int] = []
var action_index := 0
var selected_action := ""
var phase := "idle" # choose, move, target, finished
var winner := -1
var last_attack: Dictionary = {}
var catalog := PartCatalog.new()
var ai_controller := BattleAi.new()
var team_inventory := {
	0: {"cog_sensor": 2, "fortress_core": 2, "bolt_rifle": 2, "prism_cannon": 2, "blast_launcher": 2, "impact_knuckle": 2, "needle_claw": 2, "walker_legs": 2, "hover_base": 2},
	1: {"rivet_core": 2, "red_rifle": 2, "red_claw": 2, "rivet_legs": 2},
}

func setup_demo(player_members: Array[Dictionary] = []) -> void:
	var blue_a := _player_member(player_members, 0, {"head":"cog_sensor","right":"bolt_rifle","left":"impact_knuckle","legs":"walker_legs"})
	var blue_b := _player_member(player_members, 1, {"head":"fortress_core","right":"prism_cannon","left":"needle_claw","legs":"hover_base"})
	units = [
		_make_unit(0, "COG-01", 0, Vector2i(2, 6), true, Color("45a7ff"), blue_a.loadout, blue_a.ai_profile, blue_a.level, blue_a.control_mode),
		_make_unit(1, "BOLT-02", 0, Vector2i(1, 4), false, Color("2d72cc"), blue_b.loadout, blue_b.ai_profile, blue_b.level, blue_b.control_mode),
		_make_unit(2, "RIVET-R", 1, Vector2i(6, 2), true, Color("ff5b5b"), {"head":"rivet_core","right":"red_rifle","left":"red_claw","legs":"rivet_legs"}, AiProfile.BOSS, 40, CONTROL_AUTO),
		_make_unit(3, "CLAW-R", 1, Vector2i(7, 4), false, Color("cc3434"), {"head":"rivet_core","right":"red_rifle","left":"red_claw","legs":"rivet_legs"}, AiProfile.ELITE, 20, CONTROL_AUTO),
	]
	_rebuild_unit_index()
	_start_round()

func _rebuild_unit_index() -> void:
	units_by_id.clear()
	for unit in units:
		var unit_id := int(unit.id)
		if units_by_id.has(unit_id):
			push_error("Duplicate battle unit id: %d" % unit_id)
			continue
		units_by_id[unit_id] = unit

func unit_by_id(unit_id: int) -> Dictionary:
	return units_by_id.get(unit_id, {})

func is_player_controlled(unit: Dictionary) -> bool:
	return not unit.is_empty() and unit.get("control_mode", CONTROL_AUTO) == CONTROL_PLAYER

func should_auto_act(unit: Dictionary) -> bool:
	return not unit.is_empty() and unit.get("control_mode", CONTROL_AUTO) == CONTROL_AUTO

func _player_member(player_members: Array[Dictionary], index: int, fallback_loadout: Dictionary) -> Dictionary:
	var fallback_control := CONTROL_PLAYER if index == 0 else CONTROL_AUTO
	if index >= player_members.size():
		return {"loadout":fallback_loadout,"level":1,"ai_profile":AiProfile.GENERAL,"control_mode":fallback_control}
	var source: Dictionary = player_members[index]
	# Raw loadout dictionaries from older callers remain valid.
	if not source.has("loadout"):
		return {"loadout":source,"level":1,"ai_profile":AiProfile.GENERAL,"control_mode":fallback_control}
	var level := clampi(int(source.get("level", 1)), MedalProgression.MIN_LEVEL, MedalProgression.MAX_LEVEL)
	return {"loadout":source.loadout,"level":level,"ai_profile":str(source.get("ai_profile", MedalProgression.ai_profile_for_level(level))),"control_mode":str(source.get("control_mode", fallback_control))}

func _make_unit(id: int, label: String, team: int, cell: Vector2i, leader: bool, color: Color, loadout: Dictionary, ai_profile: String = AiProfile.GENERAL, level: int = 1, control_mode: String = CONTROL_AUTO) -> Dictionary:
	var normalized_level := clampi(level, MedalProgression.MIN_LEVEL, MedalProgression.MAX_LEVEL)
	var unit := {
		"id": id, "name": label, "team": team, "cell": cell,
		"propulsion": 0, "leader": leader, "color": color, "ai_profile": ai_profile, "control_mode": control_mode,
		"level": normalized_level, "success_bonus": MedalProgression.success_bonus(normalized_level),
		"medaforces": MedalProgression.unlocked_medaforces(normalized_level),
		"ap": 0, "max_ap": 0, "mf": 0, "acted": false,
		"equipment": {}, "parts": {}, "parts_max": {},
	}
	for slot in PartData.SLOTS:
		_equip_unchecked(unit, slot, loadout[slot], true)
	return unit

func _equip_unchecked(unit: Dictionary, slot: String, part_id: String, restore_armor: bool) -> void:
	var part := catalog.get_part(part_id)
	unit.equipment[slot] = part
	unit.parts_max[slot] = part.armor
	if restore_armor or not unit.parts.has(slot): unit.parts[slot] = part.armor
	else: unit.parts[slot] = mini(unit.parts[slot], part.armor)
	if slot == "legs": unit.propulsion = part.propulsion

func equipped_part(unit: Dictionary, slot: String) -> PartData:
	if unit.is_empty() or not unit.equipment.has(slot): return null
	return unit.equipment[slot]

func _equipped_count(team: int, part_id: String, excluded_unit_id: int = -1) -> int:
	var count := 0
	for unit in units:
		if unit.id != excluded_unit_id and unit.team == team:
			for slot in PartData.SLOTS:
				if equipped_part(unit, slot).id == part_id: count += 1
	return count

func available_parts(team: int, slot: String, unit_id: int = -1) -> Array[PartData]:
	var result: Array[PartData] = []
	for part_id: String in team_inventory.get(team, {}):
		var part := catalog.get_part(part_id)
		var owned: int = team_inventory[team][part_id]
		if part != null and part.slot == slot and owned > _equipped_count(team, part_id, unit_id): result.append(part)
	result.sort_custom(func(a: PartData, b: PartData): return a.display_name < b.display_name)
	return result

func can_reconfigure(unit_id: int) -> bool:
	var unit := unit_by_id(unit_id)
	return not unit.is_empty() and unit.team == 0 and round_number == 1 and action_index == 0 and phase == "choose"

func equip_part(unit_id: int, slot: String, part_id: String) -> bool:
	if not can_reconfigure(unit_id) or not slot in PartData.SLOTS: return false
	var part := catalog.get_part(part_id)
	var unit := unit_by_id(unit_id)
	var team: int = unit.team
	if part == null or part.slot != slot or team_inventory[team].get(part_id, 0) <= _equipped_count(team, part_id, unit_id): return false
	_equip_unchecked(unit, slot, part_id, true)
	_emit_log("%s：%sを%sへ装着しました。" % [unit.name, part.display_name, part_label(slot)])
	changed.emit()
	return true

func _start_round() -> void:
	round_number += 1
	for unit in units:
		if is_active(unit):
			var ap_gain := 12 + int(unit.propulsion / 3)
			if GENERATORS.has(unit.cell):
				ap_gain += 6
			var captured_generators := _captured_generators(unit.team)
			ap_gain = int(ap_gain * (1.0 - 0.25 * captured_generators))
			unit.ap = max(1, ap_gain)
			unit.max_ap = unit.ap
			unit.acted = false
	action_order.clear()
	for unit in units:
		if is_active(unit): action_order.append(unit.id)
	action_order.sort_custom(func(a: int, b: int): return unit_by_id(a).propulsion > unit_by_id(b).propulsion)
	action_index = 0
	selected_action = ""
	phase = "choose"
	_emit_log("TURN %d — AP供給完了。推進順に行動します。" % round_number)
	changed.emit()

func _captured_generators(team: int) -> int:
	var count := 0
	for cell in GENERATORS:
		if GENERATORS[cell] == team:
			var occupant := unit_at(cell)
			if not occupant.is_empty() and occupant.team != team:
				count += 1
	return count

func current_unit() -> Dictionary:
	if action_index < 0 or action_index >= action_order.size(): return {}
	return unit_by_id(action_order[action_index])

func action_data(action: String, unit: Dictionary = {}) -> Dictionary:
	if action == "move": return {"label": "移動のみ", "part_name": "脚部", "cost": 0, "range": 0, "damage": 0, "success": 0}
	if not action in ["head", "right", "left"]: return {}
	var owner := current_unit() if unit.is_empty() else unit
	var part := equipped_part(owner, action)
	return {} if part == null else part.action_data()

# 脚部の残り装甲と推進値から算出する回避値。脚部破壊時は0（＝ほぼ確実に被弾）。
func evasion_value(unit: Dictionary) -> int:
	if unit.is_empty() or unit.parts.legs <= 0: return 0
	var ratio: float = float(unit.parts.legs) / unit.parts_max.legs
	var legs := equipped_part(unit, "legs")
	return int((legs.evasion_base + unit.propulsion / 3.0) * ratio)

# 脚部の残り装甲から算出する防御値。命中したダメージをこの分だけ軽減する。
func defense_value(unit: Dictionary) -> int:
	if unit.is_empty() or unit.parts.legs <= 0: return 0
	var ratio: float = float(unit.parts.legs) / unit.parts_max.legs
	return int(equipped_part(unit, "legs").defense_base * ratio)

# 攻撃側の成功値と対象の回避値から命中率(%)を求める。
func hit_chance(attacker: Dictionary, target: Dictionary, action: String) -> float:
	var success: float = float(action_data(action, attacker).success + int(attacker.propulsion / 4)) + float(attacker.get("success_bonus", 0.0))
	return clampf(60.0 + (success - evasion_value(target)) * 5.0, 10.0, 95.0)

# 戦闘状態から決定論的に得る擬似乱数。テスト再現性のため乱数生成器を使わない。
func _battle_roll(seed_value: int, salt: int, modulo: int) -> int:
	var mixed: int = seed_value * 1103515245 + salt * 12345 + 1013904223
	return abs(mixed) % modulo

func choose_action(action: String) -> bool:
	if phase != "choose": return false
	var unit := current_unit()
	var data := action_data(action, unit)
	if unit.is_empty() or data.is_empty() or unit.ap < data.cost: return false
	if action != "move" and unit.parts[action] <= 0: return false
	selected_action = action
	unit.ap -= data.cost
	phase = "move"
	_emit_log("%s：%sを選択（AP -%d）" % [unit.name, data.label, data.cost])
	changed.emit()
	return true

func reachable_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if phase != "move": return result
	var unit := current_unit()
	var move_ap: int = unit.ap
	if unit.parts.legs <= 0: move_ap = min(move_ap, 1)
	for y in BOARD_SIZE:
		for x in BOARD_SIZE:
			var cell := Vector2i(x, y)
			if _distance(unit.cell, cell) <= move_ap and (unit_at(cell).is_empty() or cell == unit.cell):
				result.append(cell)
	return result

func move_current(cell: Vector2i) -> bool:
	if not cell in reachable_cells(): return false
	var unit := current_unit()
	var distance := _distance(unit.cell, cell)
	unit.ap -= distance
	unit.cell = cell
	if selected_action == "move":
		finish_action()
	else:
		phase = "target"
		var guidance := "攻撃対象を選択してください。" if not targetable_units().is_empty() else "射程内に対象はいません。"
		_emit_log("%s：%dマス移動。%s" % [unit.name, distance, guidance])
		changed.emit()
	return true

func targetable_units() -> Array[int]:
	var result: Array[int] = []
	if phase != "target": return result
	var attacker := current_unit()
	var attack_range: int = action_data(selected_action, attacker).range
	for unit in units:
		if is_active(unit) and unit.team != attacker.team and _distance(attacker.cell, unit.cell) <= attack_range:
			result.append(unit.id)
	return result

func attack(target_id: int) -> bool:
	if not target_id in targetable_units(): return false
	var attacker := current_unit()
	var target := unit_by_id(target_id)
	if target.is_empty(): return false
	var action := action_data(selected_action, attacker)
	var seed_value: int = round_number * 1000 + attacker.id * 100 + target.id * 10 + attacker.cell.x + attacker.cell.y
	var chance := hit_chance(attacker, target, selected_action)
	# 成功値 vs 回避値で命中判定。外れれば回避成功（ダメージ0）。
	if _battle_roll(seed_value, 7, 100) >= chance:
		last_attack = {"outcome":"evade","attacker":attacker.id,"target":target.id,"part":"","damage":0,"chance":chance,"action_class":action["class"],"attack_family":action.family}
		_emit_log("%sの%s！ %sが回避した！" % [attacker.name, action.label, target.name])
		finish_action()
		return true
	var candidates: Array[String] = []
	for part in ["head", "right", "left", "legs"]:
		if target.parts[part] > 0: candidates.append(part)
	var part: String = candidates[_battle_roll(seed_value, 3, candidates.size())]
	# 命中したダメージを防御値で軽減。リーダー機はさらに残存機体数だけ軽減。
	var defense := defense_value(target)
	var damage: int = action.damage - defense
	if target.leader:
		damage -= active_team_count(target.team)
	damage = max(1, damage)
	target.parts[part] = max(0, target.parts[part] - damage)
	last_attack = {"outcome":"hit","attacker":attacker.id,"target":target.id,"part":part,"damage":damage,"chance":chance,"action_class":action["class"],"attack_family":action.family}
	var note := "（防御-%d）" % defense if defense > 0 else ""
	_emit_log("%sの%s命中！ %sの%sへ%dダメージ%s。" % [attacker.name, action.label, target.name, part_label(part), damage, note])
	if target.parts[part] == 0:
		_emit_log("%sの%sパーツが破壊されました。" % [target.name, part_label(part)])
		if part == "head":
			_check_victory()
	finish_action()
	return true

func finish_action() -> void:
	if phase == "finished": return
	var unit := current_unit()
	if not unit.is_empty():
		unit.mf += unit.ap
		unit.ap = 0
		unit.acted = true
	selected_action = ""
	action_index += 1
	while action_index < action_order.size() and not is_active(unit_by_id(action_order[action_index])):
		action_index += 1
	if winner >= 0:
		phase = "finished"
	elif action_index >= action_order.size():
		_start_round()
	else:
		phase = "choose"
	changed.emit()

func auto_act() -> void:
	var actor := current_unit()
	if actor.is_empty(): return
	var decision := ai_controller.choose_action(self, actor)
	if decision.is_empty():
		finish_action()
		return
	choose_action(decision.action)
	move_current(decision.cell)
	if phase == "target":
		if decision.target_id in targetable_units(): attack(decision.target_id)
		else: finish_action()

func unit_at(cell: Vector2i) -> Dictionary:
	for unit in units:
		if is_active(unit) and unit.cell == cell: return unit
	return {}

func is_active(unit: Dictionary) -> bool:
	return not unit.is_empty() and unit.parts.head > 0

func active_team_count(team: int) -> int:
	var count := 0
	for unit in units:
		if unit.team == team and is_active(unit): count += 1
	return count

func _check_victory() -> void:
	for team in [0, 1]:
		var leader_alive := false
		for unit in units:
			if unit.team == team and unit.leader and is_active(unit): leader_alive = true
		if not leader_alive:
			winner = 1 - team
			phase = "finished"
			battle_finished.emit("BLUE TEAM WIN" if winner == 0 else "RED TEAM WIN")

func _distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func part_label(part: String) -> String:
	return {"head": "頭部", "right": "右腕", "left": "左腕", "legs": "脚部"}.get(part, part)

func _emit_log(message: String) -> void:
	log_added.emit(message)
