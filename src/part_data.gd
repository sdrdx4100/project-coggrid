class_name PartData
extends Resource

const SLOTS := ["head", "right", "left", "legs"]

var id := ""
var display_name := ""
var slot := ""
var armor := 1
var action_name := ""
var ap_cost := 0
var attack_range := 0
var power := 0
var success := 0
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
	part.action_name = values.get("action", "")
	part.ap_cost = values.get("cost", 0)
	part.attack_range = values.get("range", 0)
	part.power = values.get("power", 0)
	part.success = values.get("success", 0)
	part.propulsion = values.get("propulsion", 0)
	part.evasion_base = values.get("evasion", 0)
	part.defense_base = values.get("defense", 0)
	part.color = values.get("color", Color.WHITE)
	part.visual_style = values.get("style", "standard")
	return part

func action_data() -> Dictionary:
	return {
		"label": action_name,
		"part_name": display_name,
		"cost": ap_cost,
		"range": attack_range,
		"damage": power,
		"success": success,
	}

func summary() -> String:
	if slot == "legs":
		return "装甲%d 推進%d 回避%d 防御%d" % [armor, propulsion, evasion_base, defense_base]
	return "装甲%d AP%d 威力%d 成功%d 射程%d" % [armor, ap_cost, power, success, attack_range]
