class_name BattleState
extends RefCounted

signal changed
signal log_added(message: String)
signal battle_finished(message: String)

const BOARD_SIZE := 9
const GENERATORS := {
	Vector2i(1, 1): 0, Vector2i(1, 7): 0,
	Vector2i(7, 1): 1, Vector2i(7, 7): 1,
}

var units: Array[Dictionary] = []
var round_number := 0
var action_order: Array[int] = []
var action_index := 0
var selected_action := ""
var phase := "idle" # choose, move, target, finished
var winner := -1
var last_attack: Dictionary = {}

func setup_demo() -> void:
	units = [
		_make_unit(0, "COG-01", 0, Vector2i(2, 6), 13, true, Color("45a7ff")),
		_make_unit(1, "BOLT-02", 0, Vector2i(1, 4), 10, false, Color("2d72cc")),
		_make_unit(2, "RIVET-R", 1, Vector2i(6, 2), 12, true, Color("ff5b5b")),
		_make_unit(3, "CLAW-R", 1, Vector2i(7, 4), 9, false, Color("cc3434")),
	]
	_start_round()

func _make_unit(id: int, label: String, team: int, cell: Vector2i, propulsion: int, leader: bool, color: Color) -> Dictionary:
	return {
		"id": id, "name": label, "team": team, "cell": cell,
		"propulsion": propulsion, "leader": leader, "color": color,
		"ap": 0, "max_ap": 0, "mf": 0, "acted": false,
		"parts": {"head": 40, "right": 32, "left": 32, "legs": 45},
		"parts_max": {"head": 40, "right": 32, "left": 32, "legs": 45},
	}

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
	action_order.sort_custom(func(a: int, b: int): return units[a].propulsion > units[b].propulsion)
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
	return units[action_order[action_index]]

func action_data(action: String) -> Dictionary:
	match action:
		"head": return {"label": "頭部", "cost": 12, "range": 2, "damage": 12, "success": 9}
		"right": return {"label": "右腕", "cost": 8, "range": 3, "damage": 10, "success": 7}
		"left": return {"label": "左腕", "cost": 6, "range": 1, "damage": 14, "success": 5}
		"move": return {"label": "移動のみ", "cost": 0, "range": 0, "damage": 0, "success": 0}
	return {}

# 脚部の残り装甲と推進値から算出する回避値。脚部破壊時は0（＝ほぼ確実に被弾）。
func evasion_value(unit: Dictionary) -> int:
	if unit.is_empty() or unit.parts.legs <= 0: return 0
	var ratio := float(unit.parts.legs) / unit.parts_max.legs
	return int((4.0 + unit.propulsion / 3.0) * ratio)

# 脚部の残り装甲から算出する防御値。命中したダメージをこの分だけ軽減する。
func defense_value(unit: Dictionary) -> int:
	if unit.is_empty() or unit.parts.legs <= 0: return 0
	var ratio := float(unit.parts.legs) / unit.parts_max.legs
	return int(4.0 * ratio)

# 攻撃側の成功値と対象の回避値から命中率(%)を求める。
func hit_chance(attacker: Dictionary, target: Dictionary, action: String) -> int:
	var success: int = action_data(action).success + int(attacker.propulsion / 4)
	return clampi(60 + (success - evasion_value(target)) * 5, 10, 95)

# 戦闘状態から決定論的に得る擬似乱数。テスト再現性のため乱数生成器を使わない。
func _battle_roll(seed_value: int, salt: int, modulo: int) -> int:
	var mixed: int = seed_value * 1103515245 + salt * 12345 + 1013904223
	return abs(mixed) % modulo

func choose_action(action: String) -> bool:
	if phase != "choose": return false
	var unit := current_unit()
	var data := action_data(action)
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
		var chances := PackedStringArray()
		for target_id in targetable_units():
			chances.append("%s %d%%" % [units[target_id].name, hit_chance(unit, units[target_id], selected_action)])
		var summary := "（命中: %s）" % ", ".join(chances) if not chances.is_empty() else "（射程内に対象なし）"
		_emit_log("%s：%dマス移動。攻撃対象を選択 %s" % [unit.name, distance, summary])
		changed.emit()
	return true

func targetable_units() -> Array[int]:
	var result: Array[int] = []
	if phase != "target": return result
	var attacker := current_unit()
	var attack_range: int = action_data(selected_action).range
	for unit in units:
		if is_active(unit) and unit.team != attacker.team and _distance(attacker.cell, unit.cell) <= attack_range:
			result.append(unit.id)
	return result

func attack(target_id: int) -> bool:
	if not target_id in targetable_units(): return false
	var attacker := current_unit()
	var target := units[target_id]
	var action := action_data(selected_action)
	var seed_value: int = round_number * 1000 + attacker.id * 100 + target.id * 10 + attacker.cell.x + attacker.cell.y
	var chance := hit_chance(attacker, target, selected_action)
	# 成功値 vs 回避値で命中判定。外れれば回避成功（ダメージ0）。
	if _battle_roll(seed_value, 7, 100) >= chance:
		last_attack = {"outcome": "evade", "attacker": attacker.id, "target": target.id, "part": "", "damage": 0, "chance": chance}
		_emit_log("%sの%s！ %sが回避成功（命中%d%%）。" % [attacker.name, action.label, target.name, chance])
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
	last_attack = {"outcome": "hit", "attacker": attacker.id, "target": target.id, "part": part, "damage": damage, "chance": chance}
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
	while action_index < action_order.size() and not is_active(units[action_order[action_index]]):
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
	var enemies: Array[Dictionary] = []
	for unit in units:
		if is_active(unit) and unit.team != actor.team: enemies.append(unit)
	if enemies.is_empty(): return
	enemies.sort_custom(func(a: Dictionary, b: Dictionary): return _distance(actor.cell, a.cell) < _distance(actor.cell, b.cell))
	var target := enemies[0]
	var action := "right" if actor.ap >= 8 and actor.parts.right > 0 else "move"
	choose_action(action)
	var desired: Vector2i = actor.cell
	var best_distance := _distance(actor.cell, target.cell)
	for cell in reachable_cells():
		var distance := _distance(cell, target.cell)
		if distance < best_distance:
			best_distance = distance
			desired = cell
	move_current(desired)
	if phase == "target":
		if target.id in targetable_units(): attack(target.id)
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
