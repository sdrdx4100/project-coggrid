class_name MedalProgression
extends RefCounted

const MIN_LEVEL := 1
const MAX_LEVEL := 99
const ELITE_AI_LEVEL := 20
const WIN_EXPERIENCE := 30
const LOSS_EXPERIENCE := 12

const MEDAFORCE_UNLOCKS := [
	{"level":1,"id":"boost_charge","name":"ブーストチャージ"},
	{"level":20,"id":"restore_wave","name":"リストアウェーブ"},
	{"level":40,"id":"overdrive","name":"オーバードライブ"},
]

static func experience_for_level(level: int) -> int:
	var normalized := clampi(level, MIN_LEVEL, MAX_LEVEL) - 1
	return normalized * 20 + normalized * normalized

static func level_for_experience(experience: int) -> int:
	var level := MIN_LEVEL
	while level < MAX_LEVEL and experience >= experience_for_level(level + 1):
		level += 1
	return level

static func success_bonus(level: int) -> float:
	# +0.1 every five levels. At level 99 this remains a modest +1.9 success.
	return float(clampi(level, MIN_LEVEL, MAX_LEVEL) / 5) * 0.1

static func ai_profile_for_level(level: int) -> String:
	return AiProfile.ELITE if level >= ELITE_AI_LEVEL else AiProfile.GENERAL

static func unlocked_medaforces(level: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for medaforce: Dictionary in MEDAFORCE_UNLOCKS:
		if level >= medaforce.level: result.append(medaforce.duplicate(true))
	return result

static func battle_experience(result: String) -> int:
	return WIN_EXPERIENCE if result == "win" else LOSS_EXPERIENCE if result == "loss" else 0
