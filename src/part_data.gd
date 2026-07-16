class_name PartData
extends Resource

const SLOTS := ["head", "right", "left", "legs"]

var id := ""
var display_name := ""
var slot := ""
var armor := 1
var action: PartAction
var propulsion := 0
var evasion_base := 0
var defense_base := 0
var color := Color.WHITE
var visual_style := "standard"

static func create(values: Dictionary) -> PartData:
	var part := PartData.new()
	part.id = values.get("id", "")
	part.display_name = values.get("name", part.id)
	part.slot = values.get("slot", "")
	part.armor = values.get("armor", 1)
	part.action = PartAction.create(values)
	part.propulsion = values.get("propulsion", 0)
	part.evasion_base = values.get("evasion", 0)
	part.defense_base = values.get("defense", 0)
	part.color = values.get("color", Color.WHITE)
	part.visual_style = values.get("style", "standard")
	return part

func action_data() -> Dictionary:
	var data := action.to_battle_data()
	data.part_name = display_name
	return data

func summary() -> String:
	if slot == "legs":
		return "装甲%d 推進%d 回避%d 防御%d" % [armor, propulsion, evasion_base, defense_base]
	var family := "" if action.attack_family == PartAction.FAMILY_NONE else "/" + action.family_label()
	return "%s%s 装甲%d AP%d 威力%d 成功%d 射程%d" % [action.class_label(), family, armor, action.ap_cost, action.power, action.success, action.attack_range]
