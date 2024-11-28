class_name Skill
extends Resource

var id: String
var name: String
var description: String
var priority: int = 0
var tags: Array = []
var animation: String
var use_conditions: Array = []
var effects: Array = []
var timings: Array = []

func _init() -> void:
	pass

func init_from_data(skill_id: String, original_data: Dictionary, skill_priority: int, skill_timings: Array) -> void:
	# 创建原始数据的深度复制
	var data = original_data.duplicate(true)
	
	self.id = skill_id
	self.name = data.get("name", "")
	self.description = data.get("description", "")
	self.priority = skill_priority
	self.tags = data.get("tag", [])  # 数组已经在duplicate(true)时被复制
	self.animation = data.get("animation", "")
	self.use_conditions = data.get("use_conditions", [])  # 同上
	self.effects = data.get("effects", [])  # 同上
	self.timings = skill_timings.duplicate()  # 复制传入的timing数组


func apply_effects(user: Character, target: Character) -> Dictionary:
	var result = {}
	for effect in effects:
		match effect.type:
			"physical_damage":
				# 每次攻击时重新计算实际攻防值
				var actual_attack = user.get_actual_combat_stat("physical_attack")
				var actual_defense = target.get_actual_combat_stat("physical_defense")
				var damage = actual_attack - actual_defense
				damage = max(1, damage)
				target.modify_health(-damage)
				result = {"type": "physical_damage", "value": damage,"target": target}
				print("Skill apply_effects physical_damage : ", result)
			"magic_damage":
				# 每次攻击时重新计算实际魔法攻防值
				var actual_magic_attack = user.get_actual_combat_stat("magical_attack")
				var actual_magic_defense = target.get_actual_combat_stat("magical_defense")
				
				var base_reduction = actual_magic_defense * 0.015
				var magic_defense_reduction = min(0.75, 0.75 * (1 - exp(-base_reduction)))
				
				var damage = actual_magic_attack * (1 - magic_defense_reduction)
				damage = max(1, floor(damage))
				target.modify_health(-damage)
				result = {"type": "magic_damage", "value": damage,"target": target}
			"heal":
				# 治疗量也使用实际魔法攻击力
				var actual_magic_attack = user.get_actual_combat_stat("magical_attack")
				var heal_amount = actual_magic_attack + target.base_attributes.constitution
				target.modify_health(heal_amount)
				result = {"type": "heal", "value": heal_amount,"target": target}
			"status":
				# 这里需要实现状态系统
				pass
			_:
				pass
	return result

func get_targets(user: Character) -> Array[Character]:
	var targets: Array[Character] = []
	var user_team = null
	var enemy_team = null
	
	# 确定施法者所在队伍和敌方队伍
	if user in Battle.blue_team.values():
		user_team = Battle.blue_team
		enemy_team = Battle.red_team
	else:
		user_team = Battle.red_team
		enemy_team = Battle.blue_team
	
	# 根据tag决定目标收集范围，只收集存活的角色
	if "enemy_only" in tags:
		# 只收集敌方存活目标
		for pos in enemy_team:
			var character = enemy_team[pos]
			if character != null and character.is_alive():
				targets.append(character)
	elif "ally_only" in tags:
		# 只收集友方存活目标
		for pos in user_team:
			var character = user_team[pos]
			if character != null and character.is_alive():
				targets.append(character)
				
	print("Skill get_targets : ", targets)
	# 2. 查技能使用条件
	for condition in use_conditions:
		match condition.type:
			"mp_cost":
				if user.get_resource("mana").current < condition.value:
					return []
			"qi_cost":
				if user.get_resource("qi").current < condition.value:
					return []
			# ... 其他条件
	#print("Skill get_targets after use_conditions : ", targets)

	# 3. 根据timing筛选目标（所有条件都要满足）
	var filtered_targets = targets
	
	print("Skill get_targets timings : ", timings)
	for timing in timings:
		var current_valid_targets: Array[Character] = []
		
		match timing:
			"self_mana_above_50_percent":
				if user.get_resource("mana").current >= user.get_resource("mana").max * 0.5:
					current_valid_targets = filtered_targets
				else:
					return []  # 任何一个timing条件不满足，直接返回空数组

			"self_mana_below_50_percent":
				if user.get_resource("mana").current < user.get_resource("mana").max * 0.5:
					current_valid_targets = filtered_targets
				else:
					return []

			"enemy_hp_above_half":
				for target in filtered_targets:
					#print("Skill get_targets enemy_hp_above_half : ", target.get_resource("health").current, target.get_resource("health").max * 0.5)
					if target.get_resource("health").current >= target.get_resource("health").max * 0.5:
						current_valid_targets.append(target)
				if current_valid_targets.is_empty():
					return []  # 如果没有满足条件的目标，返回空数组
		
		filtered_targets = current_valid_targets  # 更新有效目标列表

	#print("Skill get_targets after timings : ", filtered_targets)
	# 如果目标包含自己，直接返回自己
	if filtered_targets.has(user):
		return [user]

	# 获取user的位置信息
	var user_pos = null
	for team in [Battle.blue_team, Battle.red_team]:
		for pos in team:
			if team[pos] == user:
				user_pos = pos
				break
		if user_pos != null:
			break

	# 获取目标所在队伍
	var target_team = null
	if not filtered_targets.is_empty():
		for team in [Battle.blue_team, Battle.red_team]:
			if filtered_targets[0] in team.values():
				target_team = team
				break

	# 将目标按距离优先级分组
	var targets_by_priority = {
		"front_same": [],    # 前排同列
		"front_near": [],    # 前排近列
		"front_far": [],     # 前排远列
		"back_same": [],     # 后排同列
		"back_near": [],     # 后排近列
		"back_far": [],      # 后排远列
	}

	var user_column = _get_column(user_pos)
	for target in filtered_targets:
		# 找到目标的位置
		var target_pos = null
		for pos in target_team:
			if target_team[pos] == target:
				target_pos = pos
				break
		
		var target_column = _get_column(target_pos)
		var is_front = target_pos in [Battle.Position.FRONT_TOP, Battle.Position.FRONT_MID, Battle.Position.FRONT_BOT]
		
		# 判断距离
		if is_front:
			if target_column == user_column:
				targets_by_priority.front_same.append(target)
			elif abs(target_column - user_column) == 1:
				targets_by_priority.front_near.append(target)
			else:
				targets_by_priority.front_far.append(target)
		else:
			if target_column == user_column:
				targets_by_priority.back_same.append(target)
			elif abs(target_column - user_column) == 1:
				targets_by_priority.back_near.append(target)
			else:
				targets_by_priority.back_far.append(target)

	#print("Skill get_targets targets_by_priority : ", targets_by_priority)

	# 按新的优先级返回第一个非空组的随机目标
	var selected_targets: Array[Character] = []
	for group in ["front_same", "front_near", "front_far", "back_same", "back_near", "back_far"]:
		if not targets_by_priority[group].is_empty():
			selected_targets = [targets_by_priority[group].pick_random()]
			break

	print("Skill get_targets after common rule : ", selected_targets)

	# 如果技能tag包含"row"或"column"或"all"，添加扩展后的目标
	if "row" in tags or "column" in tags or "all" in tags:
		# 获取选中目标的位置
		var selected_pos = null
		for pos in target_team:
			if target_team[pos] == selected_targets[0]:
				selected_pos = pos
				break

		if "row" in tags:
			# 添加同一行的目标
			var row = "FRONT" if selected_pos in [Battle.Position.FRONT_TOP, Battle.Position.FRONT_MID, Battle.Position.FRONT_BOT] else "BACK"
			for pos in target_team:
				if pos.begins_with(row) and target_team[pos] != null and target_team[pos] not in selected_targets:
					selected_targets.append(target_team[pos])
		elif "column" in tags:
			# 添加同一列的目标
			var column = _get_column(selected_pos)
			for pos in target_team:
				if _get_column(pos) == column and target_team[pos] != null and target_team[pos] not in selected_targets:
					selected_targets.append(target_team[pos])
		elif "all" in tags:
			# 添加所有目标
			for pos in target_team:
				if target_team[pos] != null and target_team[pos] not in selected_targets:
					selected_targets.append(target_team[pos])

	print("Skill get_targets after all rule : ", selected_targets)

	return selected_targets



# 获取位置所在的列（0=上列，1=中列，2=下列）
func _get_column(pos: Battle.Position) -> int:
	match pos:
		Battle.Position.FRONT_TOP, Battle.Position.BACK_TOP:
			return 0
		Battle.Position.FRONT_MID, Battle.Position.BACK_MID:
			return 1
		Battle.Position.FRONT_BOT, Battle.Position.BACK_BOT:
			return 2
		_:
			return -1
