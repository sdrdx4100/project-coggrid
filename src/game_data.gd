class_name GameData
extends RefCounted

const SAVE_PATH := "user://save.json"

var catalog := PartCatalog.new()
var inventory := {"cog_sensor":2,"fortress_core":2,"bolt_rifle":2,"prism_cannon":2,"impact_knuckle":2,"needle_claw":2,"walker_legs":2,"hover_base":2}
var roster: Array[Dictionary] = []
var player_cell := Vector2i(3, 10)
var battles_won := 0

func new_game() -> void:
	roster = [
		{"name":"COG-01","leader":true,"loadout":{"head":"cog_sensor","right":"bolt_rifle","left":"impact_knuckle","legs":"walker_legs"}},
		{"name":"BOLT-02","leader":false,"loadout":{"head":"fortress_core","right":"prism_cannon","left":"needle_claw","legs":"hover_base"}},
	]
	player_cell = Vector2i(3, 10)
	battles_won = 0

func player_loadouts() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for member in roster: result.append(member.loadout.duplicate(true))
	return result

func equipped_count(part_id: String, excluded_member := -1) -> int:
	var count := 0
	for index in roster.size():
		if index == excluded_member: continue
		for slot in PartData.SLOTS:
			if roster[index].loadout[slot] == part_id: count += 1
	return count

func available_parts(slot: String, member_index: int) -> Array[PartData]:
	var result: Array[PartData] = []
	for part_id: String in inventory:
		var part := catalog.get_part(part_id)
		if part != null and part.slot == slot and inventory[part_id] > equipped_count(part_id, member_index): result.append(part)
	result.sort_custom(func(a: PartData, b: PartData): return a.display_name < b.display_name)
	return result

func equip(member_index: int, slot: String, part_id: String) -> bool:
	if member_index < 0 or member_index >= roster.size() or not slot in PartData.SLOTS: return false
	var part := catalog.get_part(part_id)
	if part == null or part.slot != slot or inventory.get(part_id, 0) <= equipped_count(part_id, member_index): return false
	roster[member_index].loadout[slot] = part_id
	return true

func save_game() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null: return false
	var serial_roster: Array[Dictionary] = []
	for member in roster:
		serial_roster.append({"name":member.name,"leader":member.leader,"loadout":member.loadout})
	file.store_string(JSON.stringify({"version":1,"player_cell":[player_cell.x,player_cell.y],"battles_won":battles_won,"inventory":inventory,"roster":serial_roster}, "\t"))
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not parsed is Dictionary or parsed.get("version", 0) != 1: return false
	var cell: Array = parsed.get("player_cell", [3, 10])
	player_cell = Vector2i(int(cell[0]), int(cell[1]))
	battles_won = int(parsed.get("battles_won", 0))
	inventory = parsed.get("inventory", inventory)
	roster.clear()
	for member in parsed.get("roster", []):
		roster.append({"name":str(member.name),"leader":bool(member.leader),"loadout":member.loadout})
	return not roster.is_empty()
