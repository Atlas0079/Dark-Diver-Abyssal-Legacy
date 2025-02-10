extends Node
class_name Character

# 基础信息
var character_name: String
var race: String
var creature_type: String
var image_path: String

# 基础属性
var base_attributes = {
	"strength": 0,
	"dexterity": 0,
	"constitution": 0,
	"intelligence": 0,
	"perception": 0,
	"charisma": 0,
	"dodge_rate": 0,
	"block_rate": 0,
	"crit_rate": 0
}

# 战斗属性
var combat_stats = {
	"physical_attack": 0,
	"magical_attack": 0,
	"physical_defense": 0,
	"magical_defense": 0,
	"hit_rate": 0,
	"dodge_rate": 0,
	"crit_rate": 0,
	"crit_damage": 0,
	"equipment_boosts": {}
}

# 资源值
var resources = {
	"health": {"current": 0, "max": 0},
	"mana": {"current": 0, "max": 0},
	"stamina": {"current": 0, "max": 0},
	"qi": {"current": 0, "max": 0},
	"energy": {"current": 0, "max": 0},
	"stress": {"current": 0, "max": 0},
	"passive_point": {"current": 0, "max": 0}
}

# 装备
var equipment = {
	"weapon": null,
	"armor": null,
	"accessories": []
}

# 战斗相关
var battle_stats = {
	"action_point": 0,
	"action_threshold": 0,
	"active_skills": {},  # Dictionary<String, Skill>
}

# 其他属性
var learned_skills: Array = []
var traits: Array = []
var states: Array = []
var inventory: Inventory
var location: String = ""

# 临时背包,用于存放卸下的装备
var temp_inventory = {
	"items": [] # 临时背包不需要容量限制
}

# 用于战斗的行动次数计数
var act_count: int = 0

# 从数据初始化角色
func init_from_data(original_data: Dictionary) -> void:
	# 创建原始数据的深度复制
	var data = original_data.duplicate(true)
	
	# 基础信息
	self.character_name = data.get("name", "")
	self.race = data.get("race", "")
	self.creature_type = data.get("creature_type", "")
	self.image_path = data.get("image", "")
	
	# 基础属性
	if data.has("base_attributes"):
		self.base_attributes = data.base_attributes
	
	# 资源值
	if data.has("resources"):
		self.resources = data.resources
	
	# 装备
	if data.has("equipment"):
		var equip_data = data.equipment
		if equip_data.has("weapon") and equip_data.weapon:
			var weapon = DataManager.create_item(str(equip_data.weapon))
			print("Character init_from_data weapon: %s" % weapon)
			if weapon:
				equipment.weapon = weapon
				
		if equip_data.has("armor") and equip_data.armor:
			var armor = DataManager.create_item(str(equip_data.armor))
			if armor:
				equipment.armor = armor
				
		if equip_data.has("accessories"):
			for acc_id in equip_data.accessories:
				var accessory = DataManager.create_item(str(acc_id))
				if accessory:
					equipment.accessories.append(accessory)
	
	# 战斗相关
	if data.has("battle"):
		self.battle_stats.action_point = data.battle.get("action_point", 0)
		self.battle_stats.action_threshold = data.battle.get("action_threshold", 0)
		self.battle_stats.active_skills = {}  # 清空技能字典
		
# 初始化技能
	if data.battle.has("active_skills"):
		for skill_id in data.battle.active_skills:
			var skill = SkillRegistry.create_skill(skill_id) 
			if skill:
				skill.owner = self
				self.battle_stats.active_skills[skill_id] = skill
	
	# 其他属性
	self.learned_skills = data.get("learned_skills", [])
	self.traits = data.get("traits", [])
	self.states = data.get("states", [])
	self.location = data.get("location", "")
	
	# 初始化背包
	inventory = Inventory.new(data.get("inventory", {}).get("capacity", 20))
	if data.has("inventory"):
		for item_id in data.inventory.get("items", []):
			var item = DataManager.create_item(str(item_id))
			if item:
				inventory.add_item(item)
	
	# 初始化完基础属性后更新战斗属性
	_update_combat_stats()

# 获取当前生命值
func get_current_health() -> int:
	return resources.health.current

# 获取最大生命值
func get_max_health() -> int:
	return resources.health.max

# 修改生命值
func modify_health(amount: int) -> void:
	var was_alive = is_alive()
	resources.health.current = clamp(
		resources.health.current + amount,
		0,
		resources.health.max
	)
	
	# 如果角色刚死亡，重置行动点
	if was_alive and is_dead():
		battle_stats.action_point = 0

# 检查是否存活
func is_alive() -> bool:
	return resources.health.current > 0

# 检查是否死亡
func is_dead() -> bool:
	return resources.health.current <= 0

# 获取属性值
func get_attribute(attr_name: String) -> int:
	return base_attributes.get(attr_name, 0)

# 获取资源值
func get_resource(resource_name: String) -> Dictionary:
	return resources.get(resource_name, {"current": 0, "max": 0})

# 检查状态
func has_state(state_name: String) -> bool:
	for state in states:
		if state.has(state_name):
			return true
	return false

# 获取状态值
func get_state_value(state_name: String) -> int:
	for state in states:
		if state.has(state_name):
			return state[state_name]
	return 0

# 获取技能
func get_skill(skill_id: String) -> BaseSkill:
	if battle_stats.active_skills.has(skill_id):
		return battle_stats.active_skills[skill_id]
	return null

func has_skill(skill_id: String) -> bool:
	return battle_stats.active_skills.has(skill_id)

func get_available_skill(battle: Battle) -> String:
	# 创建一个包含技能ID和优先级的数组
	var prioritized_skills = []
	for skill_id in battle_stats.active_skills:
		prioritized_skills.append({
			"id": skill_id,
			"priority": battle_stats.active_skills[skill_id].priority
		})
	
	# 按优先级从高到低排序
	prioritized_skills.sort_custom(func(a, b): return a.priority > b.priority)
	
	# 返回第一个可用的技能ID
	for skill_data in prioritized_skills:
		var skill_id = skill_data.id
		if get_skill(skill_id).get_targets(self,battle).size() > 0:
			return skill_id
	
	return ""  # 如果没有可用技能则返回空字符串

func use_skill(skill: BaseSkill,targets: Array[Character],battle: Battle) -> Dictionary:
	return skill.apply_effects(self,targets,battle)
	
# 修改基础属性的设置方法
func set_attribute(attr_name: String, value: int) -> void:
	if base_attributes.has(attr_name):
		base_attributes[attr_name] = value
		_update_combat_stats()  # 当基础属性改变时更新战斗属性

# 添加更新战斗属性的方法
func _update_combat_stats() -> void:
	# 重置装备加成
	combat_stats.equipment_boosts.clear()
	#计算基础属性
	for attr in base_attributes:
		combat_stats[attr] = base_attributes[attr]


	# 计算所有装备的属性加成
	var all_equipment = [equipment.weapon, equipment.armor] + equipment.accessories
	for equipped_item in all_equipment:
		if equipped_item:
			var boosts = equipped_item.get_attribute_boosts()
			for attr in boosts:
				if not combat_stats.equipment_boosts.has(attr):
					combat_stats.equipment_boosts[attr] = 0
				combat_stats.equipment_boosts[attr] += boosts[attr]
	print("update_combat_stats dodge_rate:",combat_stats.dodge_rate)



# 获取战斗属性（不包含随机加成）
func get_combat_stat(stat_name: String) -> float:
	return combat_stats.get(stat_name, 0.0)

# 获取实际战斗属性（包含随机加成）
func get_actual_combat_stat(stat_name: String) -> float:
	var base_value = get_combat_stat(stat_name)
	# 获取所有装备的当前属性加成
	var all_equipment = [equipment.weapon, equipment.armor] + equipment.accessories
	for equipped_item in all_equipment:
		if equipped_item:
			var boosts = equipped_item.calculate_current_attributes()
			if boosts.has(stat_name):
				base_value += boosts[stat_name]
				print("get_actual_combat_stat %s 计算 %s 装备随机值 %s: %s" % [self.character_name, equipped_item.custom_name, stat_name, boosts[stat_name]])


	return base_value

# 检查卸下装备后是否会影响其他装备的需求
func _check_unequip_impact(item_id: String, equip_type: String) -> bool:
	# 模拟卸下装备后的状态
	var original_equipment = equipment.duplicate(true)
	var original_combat_stats = combat_stats.duplicate(true)
	
	# 临时移除装备
	match equip_type:
		"weapon": equipment.weapon = null
		"armor": equipment.armor = null
		"accessory": equipment.accessories.erase(item_id)
	
	# 更新战斗属性
	_update_combat_stats()
	
	# 检查所有剩余装备的需求是否仍然满足
	var all_requirements_met = true
	
	# 检查武器
	if equipment.weapon:
		if not equipment.weapon.check_equip_conditions(self):
			all_requirements_met = false
	
	# 检查护甲
	if equipment.armor:
		if not equipment.armor.check_equip_conditions(self):
			all_requirements_met = false
	
	# 检查饰品
	for accessory in equipment.accessories:
		if not accessory.check_equip_conditions(self):
			all_requirements_met = false
	
	# 恢复原始状态
	equipment = original_equipment
	combat_stats = original_combat_stats
	
	return all_requirements_met

# 装备物品
func equip(item: Item) -> bool:
	var equip_type = item.get_type()
	if not can_equip(item):
		return false
		
	match equip_type:
		"weapon":
			if equipment.weapon != null:
				unequip(equipment.weapon)
			equipment.weapon = item
		"armor":
			if equipment.armor != null:
				unequip(equipment.armor)
			equipment.armor = item
		"accessory":
			if equipment.accessories.size() >= 3:
				unequip(equipment.accessories[0])
			equipment.accessories.append(item)
	
	# 从背包移除物品
	inventory.remove_item(item)
	
	# 更新战斗属性
	_update_combat_stats()
	return true

# 卸下装备
func unequip(item: Item) -> bool:
	# 检查是否装备了该物品
	var equip_type = item.get_type()
	var is_equipped = false
	match equip_type:
		"weapon": is_equipped = equipment.weapon == item
		"armor": is_equipped = equipment.armor == item
		"accessory": is_equipped = equipment.accessories.has(item)
		
	if not is_equipped:
		return false
	
	# 尝试放入背包
	if inventory.can_add_item(item):
		match equip_type:
			"weapon": equipment.weapon = null
			"armor": equipment.armor = null
			"accessory": equipment.accessories.erase(item)
		return inventory.add_item(item)
	else:
		# 如果背包满了，放入溢出区
		return inventory.add_to_overflow(item)

# 检查是否可以装备
# 先检查装备条件，再检查背包是否可以容纳替换后的装备
# 背包剩余容量-放入背包的装备占用空间+替换上的装备占用空间
func can_equip(item: Item) -> bool:
	var item_size = item.get_size()
	var remaining_space = inventory.get_remaining_space()
	return item.check_equip_conditions(self) and remaining_space >= item_size

func get_block_value() -> int:
	var block_value = 0
	for accessory in equipment.accessories:
		if accessory.get_type() == "shield":
			block_value += accessory.get_block_value()
	return block_value

func get_block_rate() -> int:
	var block_rate = 0
	for accessory in equipment.accessories:
		if accessory.get_type() == "shield":
			block_rate += accessory.get_block_rate()
	return block_rate
