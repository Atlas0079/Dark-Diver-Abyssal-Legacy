class_name Character
extends Node

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
	"charisma": 0
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
	"stress": {"current": 0, "max": 0}
}

# 装备
var equipment = {
	"weapon": "",
	"armor": "",
	"accessories": []
}

# 战斗相关
var battle_stats = {
	"action_point": 0,
	"action_threshold": 0,
	"active_skills": {}  # Dictionary<String, Skill>
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
		self.equipment = data.equipment
	
	# 战斗相关
	if data.has("battle"):
		self.battle_stats.action_point = data.battle.get("action_point", 0)
		self.battle_stats.action_threshold = data.battle.get("action_threshold", 0)
		self.battle_stats.active_skills = {}  # 清空技能字典
		
		# 初始化技能
		var skill_data = DataManager.get_whole_skill_data()
		if data.battle.has("active_skills"):
			for skill_id in data.battle.active_skills:
				if skill_data.has(skill_id):
					var skill = Skill.new()
					skill.init_from_data(skill_id, skill_data[skill_id], 
						data.battle.active_skills[skill_id].get("priority", 0),
						data.battle.active_skills[skill_id].get("timings", []))
					self.battle_stats.active_skills[skill_id] = skill
	
	# 其他属性
	self.learned_skills = data.get("learned_skills", [])
	self.traits = data.get("traits", [])
	self.states = data.get("states", [])
	self.location = data.get("location", "")
	
	# 初始化背包
	inventory = Inventory.new(data.get("inventory", {}).get("capacity", 20))
	if data.has("inventory"):
		for item in data.inventory.get("items", []):
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
func get_skill(skill_id: String) -> Skill:
	if battle_stats.active_skills.has(skill_id):
		return battle_stats.active_skills[skill_id]
	return null

func has_skill(skill_id: String) -> bool:
	return battle_stats.active_skills.has(skill_id)

func get_available_skill() -> String:
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
		if get_skill(skill_id).get_targets(self).size() > 0:
			return skill_id
	
	return ""  # 如果没有可用技能则返回空字符串

func use_skill(skill_id: String) -> Array:
	var targets = get_skill(skill_id).get_targets(self)
	var results = []
	for target in targets:
		var result = get_skill(skill_id).apply_effects(self, target)
		results.append(result)
	return results
	
# 修改基础属性的设置方法
func set_attribute(attr_name: String, value: int) -> void:
	if base_attributes.has(attr_name):
		base_attributes[attr_name] = value
		_update_combat_stats()  # 当基础属性改变时更新战斗属性

# 添加更新战斗属性的方法
func _update_combat_stats() -> void:
	# 获取装备加成
	var base_boosts = get_equipment_base_stat_boosts()
	var fixed_combat_boosts = get_equipment_fixed_combat_boosts()
	var random_combat_boosts = get_equipment_random_combat_boosts()
	
	# 计算实际基础属性（原始 + 装备固定加成）
	var actual_base_stats = base_attributes.duplicate()
	for stat in base_boosts:
		actual_base_stats[stat] += base_boosts[stat]
	
	# 根据实际基础属性计算战斗属性
	combat_stats.physical_attack = actual_base_stats.strength * 1.5 + actual_base_stats.dexterity * 0.5
	combat_stats.magical_attack = actual_base_stats.intelligence * 1.5 + actual_base_stats.perception * 0.5
	combat_stats.physical_defense = actual_base_stats.constitution * 1 + actual_base_stats.dexterity * 0.5
	combat_stats.magical_defense = actual_base_stats.perception * 1 + actual_base_stats.intelligence * 0.5
	
	# 添加装备固定战斗属性加成
	for stat in fixed_combat_boosts:
		combat_stats[stat] += fixed_combat_boosts[stat]
	
	# 存储装备浮动加成范围，供实际战斗时使用
	combat_stats.equipment_boosts = random_combat_boosts


# 获取战斗属性（不包含随机加成）
func get_combat_stat(stat_name: String) -> float:
	return combat_stats.get(stat_name, 0.0)

# 获取实际战斗属性（包含随机加成）
func get_actual_combat_stat(stat_name: String) -> float:
	var base_value = get_combat_stat(stat_name)
	
	# 如果有装备加成范围，计算随机加成
	var boosts = combat_stats.get("equipment_boosts", {})
	if boosts.has(stat_name):
		if boosts[stat_name] is Dictionary:
			var min_boost = boosts[stat_name].get("min", 0)
			var max_boost = boosts[stat_name].get("max", 0)
			base_value += randf_range(min_boost, max_boost)
	
	return base_value

# 获取装备提供的固定基础属性加成
func get_equipment_base_stat_boosts() -> Dictionary:
	var total_boosts = {
		"strength": 0,、
		
		"dexterity": 0,
		"constitution": 0,
		"intelligence": 0,
		"perception": 0,
		"charisma": 0
	}
	
	# 处理所有装备
	for item_id in [equipment.weapon, equipment.armor] + equipment.accessories:
		if item_id:
			var boosts = DataManager.get_equipment_boosts(item_id)
			for stat in boosts:
				if stat in total_boosts:  # 只处理基础属性
					if not (boosts[stat] is Dictionary):  # 只处理固定值
						total_boosts[stat] += boosts[stat]
	
	return total_boosts

# 获取装备提供的固定战斗属性加成
func get_equipment_fixed_combat_boosts() -> Dictionary:
	var total_boosts = {
		"physical_attack": 0,
		"magical_attack": 0,
		"physical_defense": 0,
		"magical_defense": 0,
		"hit_rate": 0,
		"dodge_rate": 0,
		"crit_rate": 0
	}
	
	# 处理所有装备
	for item_id in [equipment.weapon, equipment.armor] + equipment.accessories:
		if item_id:
			var boosts = DataManager.get_equipment_boosts(item_id)
			for stat in boosts:
				if stat in total_boosts:  # 只处理战斗属性
					if not (boosts[stat] is Dictionary):  # 只处理固定值
						total_boosts[stat] += boosts[stat]
	
	return total_boosts

# 获取装备提供的浮动战斗属性加成范围
func get_equipment_random_combat_boosts() -> Dictionary:
	var total_boosts = {
		"physical_attack": {"min": 0, "max": 0},
		"magical_attack": {"min": 0, "max": 0},
		"physical_defense": {"min": 0, "max": 0},
		"magical_defense": {"min": 0, "max": 0}
	}
	
	# 处理所有装备
	for item_id in [equipment.weapon, equipment.armor] + equipment.accessories:
		if item_id:
			var boosts = DataManager.get_equipment_boosts(item_id)
			for stat in boosts:
				if stat in total_boosts:  # 只处理战斗属性
					if boosts[stat] is Dictionary:  # 只处理范围值
						total_boosts[stat].min += boosts[stat].get("min", 0)
						total_boosts[stat].max += boosts[stat].get("max", 0)
	
	return total_boosts

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
		if not _check_equip_conditions(equipment.weapon):
			all_requirements_met = false
	
	# 检查护甲
	if equipment.armor:
		if not _check_equip_conditions(equipment.armor):
			all_requirements_met = false
	
	# 检查饰品
	for accessory in equipment.accessories:
		if not _check_equip_conditions(accessory):
			all_requirements_met = false
	
	# 恢复原始状态
	equipment = original_equipment
	combat_stats = original_combat_stats
	
	return all_requirements_met

# 装备物品
func equip(item_id: String, equip_type: String) -> bool:
	# 检查物品是否在背包中
	if not inventory.has_item(item_id) and not inventory.has_item_in_overflow(item_id):
		print("Character equip 背包中没有该物品: ", item_id)
		return false
		
	# 检查物品类型是否匹配
	var item_data = DataManager.get_item_data(item_id)
	if item_data.get("equipment_type") != equip_type:
		print("Character equip 物品类型不匹配: ", item_id)
		return false
		
	# 检查是否满足装备条件
	if not _check_equip_conditions(item_id):
		print("Character equip 不满足装备条件: ", item_id)
		return false
	
	# 如果是更换装备，需要检查卸下当前装备是否会影响其他装备
	match equip_type:
		"weapon":
			if equipment.weapon:
				# 先检查新装备是否满足要求
				if not _check_equip_conditions(item_id):
					return false
				# 再检查卸下当前装备的影响
				if not _check_unequip_impact(equipment.weapon, "weapon"):
					return false
		"armor":
			if equipment.armor:
				if not _check_equip_conditions(item_id):
					return false
				if not _check_unequip_impact(equipment.armor, "armor"):
					return false
		"accessory":
			if equipment.accessories.size() >= 3:
				if not _check_equip_conditions(item_id):
					return false
				if not _check_unequip_impact(equipment.accessories.back(), "accessory"):
					return false
	
	match equip_type:
		"weapon":
			if equipment.weapon:
				if not unequip(equipment.weapon, "weapon"):
					return false
			equipment.weapon = item_id
		"armor":
			if equipment.armor:
				if not unequip(equipment.armor, "armor"):
					return false
			equipment.armor = item_id
		"accessory":
			if equipment.accessories.size() >= 3:
				if not unequip(equipment.accessories.back(), "accessory"):
					return false
			equipment.accessories.append(item_id)
		_:
			push_error("Invalid equip type: " + equip_type)
			return false
	
	# 从背包中移除物品
	if inventory.has_item(item_id):
		inventory.remove_item(item_id)
	else:
		inventory.remove_from_overflow(item_id)
	
	# 更新战斗属性
	_update_combat_stats()
	
	return true

# 卸下装备
func unequip(item_id: String, equip_type: String) -> bool:
	# 首先检查是否装备了该物品
	var is_equipped = false
	match equip_type:
		"weapon": is_equipped = equipment.weapon == item_id
		"armor": is_equipped = equipment.armor == item_id
		"accessory": is_equipped = equipment.accessories.has(item_id)
		
	if not is_equipped:
		print("Character unequip 未装备该物品: ", item_id)
		return false
	
	# 检查卸下该装备是否会影响其他装备的需求
	if not _check_unequip_impact(item_id, equip_type):
		print("Character unequip 卸下该装备会导致其他装备需求不满足: ", item_id)
		return false
	
	# 尝试放入普通背包
	if inventory.can_add_item(item_id):
		# 从装备栏移除
		match equip_type:
			"weapon": equipment.weapon = null
			"armor": equipment.armor = null
			"accessory": equipment.accessories.erase(item_id)
		# 使用背包的add_item方法添加物品
		if not inventory.add_item(item_id):
			push_error("Character unequip 添加物品到背包失败: " + item_id)
			return false
	else:
		# 如果普通背包放不下，放入溢出区
		match equip_type:
			"weapon": equipment.weapon = null
			"armor": equipment.armor = null
			"accessory": equipment.accessories.erase(item_id)
		if not inventory.add_to_overflow(item_id):
			push_error("Character unequip 添加物品到溢出区失败: " + item_id)
			return false
	
	# 更新战斗属性
	_update_combat_stats()
	
	return true

# 检查装备条件
func _check_equip_conditions(item_id: String) -> bool:
	var item_data = DataManager.get_item_data(item_id)
	var conditions = item_data.get("equip_conditions", {})
	
	for attr_name in conditions:
		if get_attribute(attr_name) < conditions[attr_name]:
			return false
	return true


