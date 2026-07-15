class_name PartAction
extends Resource

const CLASS_SHOOT := "shoot"
const CLASS_STRIKE := "strike"
const CLASS_GUARD := "guard"
const CLASS_RESTORE := "restore"
const CLASS_SUPPORT := "support"
const CLASS_DISRUPT := "disrupt"
const CLASS_SPECIAL := "special"

const FAMILY_NONE := "none"
const FAMILY_STANDARD := "standard"
const FAMILY_OPTICAL := "optical"
const FAMILY_GUNPOWDER := "gunpowder"
const FAMILY_GRAVITY := "gravity"
const FAMILY_ELECTRIC := "electric"
const FAMILY_IMPACT := "impact"
const FAMILY_SLASH := "slash"

const TARGET_ENEMY_SINGLE := "enemy_single"
const TARGET_ALLY_SINGLE := "ally_single"
const TARGET_SELF := "self"
const TARGET_TILE := "tile"
const TARGET_ENEMY_ALL := "enemy_all"

var id := ""
var display_name := ""
var action_class := CLASS_SHOOT
var attack_family := FAMILY_STANDARD
var targeting := TARGET_ENEMY_SINGLE
var ap_cost := 0
var attack_range := 0
var power := 0
var success := 0
var effect_ids: PackedStringArray = []

static func create(values: Dictionary) -> PartAction:
	var action := PartAction.new()
	action.id = values.get("action_id", values.get("id", "") + "_action")
	action.display_name = values.get("action", "")
	action.action_class = values.get("action_class", CLASS_SHOOT)
	action.attack_family = values.get("attack_family", FAMILY_STANDARD)
	action.targeting = values.get("targeting", TARGET_ENEMY_SINGLE)
	action.ap_cost = values.get("cost", 0)
	action.attack_range = values.get("range", 0)
	action.power = values.get("power", 0)
	action.success = values.get("success", 0)
	action.effect_ids = PackedStringArray(values.get("effects", []))
	return action

func is_attack() -> bool:
	return action_class in [CLASS_SHOOT, CLASS_STRIKE]

func class_label() -> String:
	return {CLASS_SHOOT:"うつ",CLASS_STRIKE:"なぐる",CLASS_GUARD:"まもる",CLASS_RESTORE:"なおす",CLASS_SUPPORT:"たすける",CLASS_DISRUPT:"しかける",CLASS_SPECIAL:"とくしゅ"}.get(action_class, action_class)

func family_label() -> String:
	return {FAMILY_NONE:"—",FAMILY_STANDARD:"通常",FAMILY_OPTICAL:"光学",FAMILY_GUNPOWDER:"火薬",FAMILY_GRAVITY:"重力",FAMILY_ELECTRIC:"電気",FAMILY_IMPACT:"打撃",FAMILY_SLASH:"斬撃"}.get(attack_family, attack_family)

func to_battle_data() -> Dictionary:
	return {"id":id,"label":display_name,"class":action_class,"family":attack_family,"targeting":targeting,"cost":ap_cost,"range":attack_range,"damage":power,"success":success,"effects":effect_ids}
