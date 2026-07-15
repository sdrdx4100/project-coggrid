class_name PartCatalog
extends RefCounted

var parts: Dictionary = {}

func _init() -> void:
	_register({"id":"cog_sensor","name":"コグセンサー","slot":"head","armor":40,"action":"索敵パルス","action_class":"support","attack_family":"none","effects":["scan"],"cost":12,"range":2,"power":12,"success":9,"color":Color("45a7ff"),"style":"antenna"})
	_register({"id":"fortress_core","name":"フォートレスコア","slot":"head","armor":52,"action":"ヘビープレス","action_class":"strike","attack_family":"gravity","cost":14,"range":2,"power":16,"success":5,"color":Color("e7a23b"),"style":"heavy"})
	_register({"id":"bolt_rifle","name":"ボルトライフル","slot":"right","armor":32,"action":"ライフル","action_class":"shoot","attack_family":"standard","cost":8,"range":3,"power":10,"success":7,"color":Color("3488d8"),"style":"barrel"})
	_register({"id":"prism_cannon","name":"プリズムカノン","slot":"right","armor":25,"action":"ビーム","action_class":"shoot","attack_family":"optical","cost":12,"range":4,"power":17,"success":5,"color":Color("d75ce8"),"style":"cannon"})
	_register({"id":"blast_launcher","name":"ブラストランチャー","slot":"right","armor":28,"action":"ミサイル","action_class":"shoot","attack_family":"gunpowder","effects":["blast"],"cost":10,"range":3,"power":15,"success":6,"color":Color("e88538"),"style":"cannon"})
	_register({"id":"impact_knuckle","name":"インパクトナックル","slot":"left","armor":32,"action":"ハンマー","action_class":"strike","attack_family":"impact","cost":6,"range":1,"power":14,"success":5,"color":Color("f0a63b"),"style":"fist"})
	_register({"id":"needle_claw","name":"ニードルクロー","slot":"left","armor":26,"action":"ソード","action_class":"strike","attack_family":"slash","cost":5,"range":1,"power":10,"success":9,"color":Color("62d3a5"),"style":"claw"})
	_register({"id":"walker_legs","name":"ウォーカーレッグ","slot":"legs","armor":45,"propulsion":13,"evasion":4,"defense":4,"color":Color("326cae"),"style":"biped"})
	_register({"id":"hover_base","name":"ホバーベース","slot":"legs","armor":36,"propulsion":16,"evasion":7,"defense":2,"color":Color("72d6e8"),"style":"hover"})
	# Enemy-side demo models use the same system and can later be added to inventories.
	_register({"id":"rivet_core","name":"リベットコア","slot":"head","armor":42,"action":"ジャマー","action_class":"disrupt","attack_family":"none","effects":["jam"],"cost":12,"range":2,"power":11,"success":8,"color":Color("ef5a5a"),"style":"heavy"})
	_register({"id":"red_rifle","name":"レッドライフル","slot":"right","armor":30,"action":"ライフル","action_class":"shoot","attack_family":"standard","cost":8,"range":3,"power":10,"success":7,"color":Color("cf3d49"),"style":"barrel"})
	_register({"id":"red_claw","name":"レッドクロー","slot":"left","armor":28,"action":"クロー","action_class":"strike","attack_family":"slash","cost":6,"range":1,"power":13,"success":6,"color":Color("e65c45"),"style":"claw"})
	_register({"id":"rivet_legs","name":"リベットレッグ","slot":"legs","armor":45,"propulsion":12,"evasion":4,"defense":4,"color":Color("a83845"),"style":"biped"})

func _register(values: Dictionary) -> void:
	var part := PartData.create(values)
	assert(part.id != "" and part.slot in PartData.SLOTS)
	parts[part.id] = part

func get_part(part_id: String) -> PartData:
	return parts.get(part_id)

func parts_for_slot(slot: String) -> Array[PartData]:
	var result: Array[PartData] = []
	for part: PartData in parts.values():
		if part.slot == slot: result.append(part)
	result.sort_custom(func(a: PartData, b: PartData): return a.display_name < b.display_name)
	return result
