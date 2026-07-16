class_name AiProfile
extends RefCounted

const GENERAL := "general"
const ELITE := "elite"
const BOSS := "boss"

var id := GENERAL
var choice_pool := 3
var attack_weight := 1.0
var approach_weight := 1.0
var part_break_weight := 0.0
var leader_attack_weight := 0.0
var generator_weight := 0.0
var survival_weight := 0.0
var focus_weight := 0.0
var leader_guard_weight := 0.0

static func create(profile_id: String) -> AiProfile:
	var profile := AiProfile.new()
	profile.id = profile_id
	match profile_id:
		ELITE:
			profile.choice_pool = 2
			profile.attack_weight = 1.2
			profile.approach_weight = 1.4
			profile.part_break_weight = 8.0
			profile.leader_attack_weight = 6.0
			profile.generator_weight = 5.0
			profile.survival_weight = 1.0
			profile.focus_weight = 5.0
			profile.leader_guard_weight = 3.0
		BOSS:
			profile.choice_pool = 1
			profile.attack_weight = 1.5
			profile.approach_weight = 1.5
			profile.part_break_weight = 10.0
			profile.leader_attack_weight = 16.0
			profile.generator_weight = 6.0
			profile.survival_weight = 2.0
			profile.focus_weight = 8.0
			profile.leader_guard_weight = 4.0
		_:
			profile.choice_pool = 3
			profile.attack_weight = 1.0
			profile.approach_weight = 1.0
			profile.part_break_weight = 2.0
			profile.leader_attack_weight = 2.0
			profile.generator_weight = 2.0
			profile.survival_weight = 0.25
			profile.focus_weight = 0.0
			profile.leader_guard_weight = 0.5
	return profile
