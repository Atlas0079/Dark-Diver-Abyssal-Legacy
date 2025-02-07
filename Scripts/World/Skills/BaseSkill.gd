extends Resource
class_name BaseSkill
var owner: Character

# 这些属性由具体技能类定义
var skill_name: String
var description: String
var priority: int
var tags: Array[String]
var animation: String
var use_conditions: Array
var timings: Array

func _init() -> void:
	_setup()

# 由子类实现的初始化方法
func _setup() -> void:
	push_error("BaseSkill._setup() 需要被子类重写")

# 获取技能目标
func get_targets(user: Character,battle: Battle) -> Array[Character]: 
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
				
	#print("Skill get_targets : ", targets)
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
	
	for timing in timings:
		filtered_targets = SkillTimingHandler.check_timing_condition(timing, user, filtered_targets)
		if filtered_targets.is_empty():
			return []

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

	#print("Skill get_targets after common rule : ", selected_targets)

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

	#print("Skill get_targets after all rule : ", selected_targets)

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


# 应用技能效果
func apply_effects(user: Character,targets: Array[Character], battle: Battle) -> Dictionary:
	push_error("BaseSkill.apply_effects() 需要被子类重写")
	return {}

# 检查技能是否可用
func can_use(battle: Battle) -> bool:
	# 检查使用条件
	for condition in use_conditions:
		if not _check_condition(condition):
			return false
	return true

# 由子类实现的条件检查
func _check_condition(condition: Dictionary) -> bool:
	return true

# 由子类实现的目标过滤
func _filter_targets(targets: Array[Character]) -> Array[Character]:
	return targets