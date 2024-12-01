#res://Script/DataManager.gd
# AutoLoad

extends Node

# 缓存数据
var _character_instances = {}  # 角色实例缓存（NPC）
var _monster_templates = {}   # 怪物模板实例缓存
var _team_data = {}          # 队伍数据缓存
var _skill_data = {}         # 技能数据缓存
var _npc_data = {}          # NPC数据缓存
var _monster_data = {}      # 怪物数据缓存
var _item_data = {}         # 统一的物品数据缓存
var _event_data = {}
var _event_instances = {}

func _ready():
	# 加载所有必要的数据
	_load_all_data()

# 加载所有数据
func _load_all_data() -> void:
	_load_team_data()
	_load_skill_data()
	_load_npc_data()
	_load_monster_data()
	_load_item_data()
	_load_event_data()
	_create_all_character_instances()
	for npc in _character_instances:
		print("DataManager _load_all_data npc: %s" % npc)

# 加载队伍数据
func _load_team_data() -> void:
	var file = FileAccess.open("res://Dataset/Teams.json", FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		_team_data = json.get_data()
	file.close()

# 加载技能数据
func _load_skill_data() -> void:
	var file = FileAccess.open("res://Dataset/Skills.json", FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		_skill_data = json.get_data()
	file.close()

# 加载NPC数据
func _load_npc_data() -> void:
	var file = FileAccess.open("res://Dataset/NPC/NPCData.json", FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		_npc_data = json.get_data()
	file.close()

# 加载怪物数据
func _load_monster_data() -> void:
	var file = FileAccess.open("res://Dataset/Monster/MonsterTemplate.json", FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		_monster_data = json.get_data()
	file.close()

# 加载物品数据
func _load_item_data() -> void:
	var json = JSON.new()
	
	# 加载装备数据
	var equipment_file = FileAccess.open("res://Dataset/Item/ItemEquipment.json", FileAccess.READ)
	if json.parse(equipment_file.get_as_text()) == OK:
		var equipment_data = json.get_data()
		for id in equipment_data:
			_item_data[id] = equipment_data[id]
			_item_data[id]["item_type"] = "equipment"
	equipment_file.close()
	
	# 加载消耗品数据
	var consumable_file = FileAccess.open("res://Dataset/Item/ItemConsumable.json", FileAccess.READ)
	if json.parse(consumable_file.get_as_text()) == OK:
		var consumable_data = json.get_data()
		for id in consumable_data:
			_item_data[id] = consumable_data[id]
			_item_data[id]["item_type"] = "consumable"
	consumable_file.close()
	
	# 加载杂项数据
	var misc_file = FileAccess.open("res://Dataset/Item/ItemMisc.json", FileAccess.READ)
	if json.parse(misc_file.get_as_text()) == OK:
		var misc_data = json.get_data()
		for id in misc_data:
			_item_data[id] = misc_data[id]
			_item_data[id]["item_type"] = "misc"
	misc_file.close()
	#print("DataManager _load_item_data _item_data: %s" % _item_data)

# 加载事件数据
func _load_event_data() -> void:
	var file = FileAccess.open("res://Dataset/Events.json", FileAccess.READ)
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	if error == OK:
		_event_data = json.get_data()
	file.close()

# 创建所有角色实例
func _create_all_character_instances() -> void:
	# 创建NPC实例
	for npc_id in _npc_data:
		var character = Character.new()
		character.init_from_data(_npc_data[npc_id])
		_character_instances[npc_id] = character

	# 创建怪物模板实例
	for monster_id in _monster_data:
		print("DataManager _load_all_data _monster_data[monster_id]: %s" % _monster_data[monster_id])
		var monster = Character.new()
		monster.init_from_data(_monster_data[monster_id])
		_monster_templates[monster_id] = monster

# 公共接口
func get_team_data(team_id: String) -> Dictionary:
	return _team_data.get(str(team_id), {})

# 获取角色实例（仅用于NPC）
func get_character_instance(character_id: String) -> Character:
	return _character_instances.get(str(character_id))

# 获取怪物模板实例
func get_monster_template(monster_id: String) -> Character:
	return _monster_templates.get(str(monster_id))

# 创建怪物副本
func create_monster_copy(monster_id: String) -> Character:
	print("DataManager create_monster_copy monster_id: %s" % monster_id)
	var template = get_monster_template(monster_id)
	if template == null:
		return null
	print("DataManager create_monster_copy _monster_data[str(monster_id)]: %s" % _monster_data[str(monster_id)])
	var new_monster = Character.new()
	new_monster.init_from_data(_monster_data[str(monster_id)])
	return new_monster

func get_whole_skill_data() -> Dictionary:
	return _skill_data

func get_equipment_boosts(item_id: String) -> Dictionary:
	var data = get_item_data(item_id)
	if data.get("item_type") == "equipment":
		return data.get("attribute_boosts", {})
	return {}

func get_equipment_conditions(item_id: String) -> Dictionary:
	var data = get_item_data(item_id)
	if data.get("item_type") == "equipment":
		return data.get("equip_conditions", {})
	return {}

func get_consumable_effects(item_id: String) -> Dictionary:
	var data = get_item_data(item_id)
	if data.get("item_type") == "consumable":
		return data.get("effects", {})
	return {}

# 获取事件实例
func get_event(event_id: String) -> Event:
	if not _event_instances.has(event_id):
		if not _event_data.has(event_id):
			print("Event不存在: ", event_id)
			return null
			
		var event = Event.new()
		event.init_from_data(_event_data[event_id])
		_event_instances[event_id] = event
		
	return _event_instances[event_id]

# 清理数据（在需要时调用）
func cleanup():
	_character_instances.clear()
	_monster_templates.clear()

# 获取物品数据
func get_item_data(item_id: String) -> Dictionary:
	return _item_data.get(str(item_id), {})

# 检查物品是否存在
func item_exists(item_id: String) -> bool:
	return _item_data.has(str(item_id))

# 创建物品实例
func create_item(item_id: String) -> Item:
	if not item_exists(item_id):
		return null
	
	var data = get_item_data(item_id)
	var item: Item
	
	# 根据物品类型创建对应的子类实例
	match data.get("item_type", ""):
		"equipment":
			item = Equipment.new(item_id)
		"consumable":
			item = Consumable.new(item_id)
		"misc":
			item = MiscItem.new(item_id)
		_:
			push_error("Unknown item type for item: " + item_id)
			return null
	
	# 初始化物品数据
	item.init_from_template()
	return item
