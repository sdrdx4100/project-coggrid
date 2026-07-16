class_name BattleAi
extends RefCounted

var focus_targets: Dictionary = {}

func choose_action(battle, actor: Dictionary) -> Dictionary:
	var profile := AiProfile.create(actor.get("ai_profile", AiProfile.GENERAL))
	var candidates := ranked_candidates(battle, actor, profile)
	if candidates.is_empty(): return {}
	var pool_size := mini(profile.choice_pool, candidates.size())
	var choice_index := _deterministic_roll(battle.round_number * 100 + actor.id * 17, pool_size)
	var chosen: Dictionary = candidates[choice_index]
	if chosen.target_id >= 0: focus_targets[actor.team] = chosen.target_id
	return chosen

func ranked_candidates(battle, actor: Dictionary, profile: AiProfile) -> Array[Dictionary]:
	var candidates: Array[Dictionary] = []
	var enemies: Array[Dictionary] = []
	for unit in battle.units:
		if battle.is_active(unit) and unit.team != actor.team: enemies.append(unit)
	if enemies.is_empty(): return candidates
	for slot in ["head", "right", "left"]:
		var action: Dictionary = battle.action_data(slot, actor)
		if actor.parts[slot] <= 0 or actor.ap < action.cost: continue
		var movement_ap: int = actor.ap - action.cost
		for cell in _reachable_cells(battle, actor, movement_ap):
			var found_target := false
			for target in enemies:
				if _distance(cell, target.cell) <= action.range:
					found_target = true
					candidates.append(_make_candidate(battle, actor, profile, slot, action, cell, target, enemies))
			if not found_target:
				candidates.append(_make_candidate(battle, actor, profile, slot, action, cell, {}, enemies))
	for cell in _reachable_cells(battle, actor, actor.ap):
		candidates.append(_make_candidate(battle, actor, profile, "move", battle.action_data("move", actor), cell, {}, enemies))
	candidates.sort_custom(func(a: Dictionary, b: Dictionary): return a.score > b.score)
	return candidates

func _make_candidate(battle, actor: Dictionary, profile: AiProfile, action_slot: String, action: Dictionary, cell: Vector2i, target: Dictionary, enemies: Array[Dictionary]) -> Dictionary:
	var score := 0.0
	var target_id := -1
	if not target.is_empty():
		target_id = target.id
		var expected_damage: float = action.damage * battle.hit_chance(actor, target, action_slot) / 100.0
		score += expected_damage * profile.attack_weight
		if target.leader: score += profile.leader_attack_weight
		if _lowest_part_hp(target) <= action.damage: score += profile.part_break_weight
		if focus_targets.get(actor.team, -1) == target.id: score += profile.focus_weight
		if profile.id == AiProfile.BOSS and battle.active_team_count(actor.team) == 1 and target.leader:
			score += 20.0
	else:
		var nearest := 99
		for enemy in enemies: nearest = mini(nearest, _distance(cell, enemy.cell))
		score += (18 - nearest) * profile.approach_weight
	if battle.GENERATORS.has(cell) and battle.GENERATORS[cell] != actor.team:
		score += profile.generator_weight
	var own_leader := _team_leader(battle, actor.team)
	if not own_leader.is_empty():
		score += max(0, 4 - _distance(cell, own_leader.cell)) * profile.leader_guard_weight
	var threats := 0
	for enemy in enemies:
		if _distance(cell, enemy.cell) <= 3: threats += 1
	score -= threats * profile.survival_weight
	# Prefer spending AP efficiently when scores otherwise tie.
	score -= _distance(actor.cell, cell) * 0.02
	return {"action":action_slot,"cell":cell,"target_id":target_id,"score":score,"profile":profile.id}

func _reachable_cells(battle, actor: Dictionary, movement_ap: int) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	if actor.parts.legs <= 0: movement_ap = mini(movement_ap, 1)
	for y in battle.BOARD_SIZE:
		for x in battle.BOARD_SIZE:
			var cell := Vector2i(x, y)
			if _distance(actor.cell, cell) <= movement_ap:
				var occupant: Dictionary = battle.unit_at(cell)
				if occupant.is_empty() or occupant.id == actor.id: result.append(cell)
	return result

func _lowest_part_hp(unit: Dictionary) -> int:
	var lowest := 999
	for slot in PartData.SLOTS:
		if unit.parts[slot] > 0: lowest = mini(lowest, unit.parts[slot])
	return lowest

func _team_leader(battle, team: int) -> Dictionary:
	for unit in battle.units:
		if unit.team == team and unit.leader and battle.is_active(unit): return unit
	return {}

func _distance(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _deterministic_roll(seed_value: int, modulo: int) -> int:
	return abs(seed_value * 1103515245 + 12345) % maxi(1, modulo)
