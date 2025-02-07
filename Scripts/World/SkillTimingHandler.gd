extends Node
class_name SkillTimingHandler

static func _get_column(pos: Battle.Position):
	match pos:
		Battle.Position.FRONT_TOP, Battle.Position.BACK_TOP:
			return 0
		Battle.Position.FRONT_MID, Battle.Position.BACK_MID:
			return 1
		Battle.Position.FRONT_BOT, Battle.Position.BACK_BOT:
			return 2
		_:
			return -1

static func _check_self_resource_percent(user: Character, filtered_targets: Array, resource_name: String, percent: float, above: bool) -> Array:
	var resource = user.get_resource(resource_name)
	var current_percent = (resource.current / resource.max) * 100
	if above:
		if current_percent >= percent:
			return filtered_targets
	else:
		if current_percent < percent:
			return filtered_targets
	return []

static func _check_act_number(user: Character, filtered_targets: Array, act_num: int) -> Array:
	if user.act_count == act_num:
		return filtered_targets
	return []

static func _check_enemy_hp_percent(filtered_targets: Array, percent: float, above: bool) -> Array:
	var current_valid_targets: Array[Character] = []
	for target in filtered_targets:
		var health = target.get_resource("health")
		var current_percent = (health.current / health.max) * 100
		if above:
			if current_percent >= percent:
				current_valid_targets.append(target)
		else:
			if current_percent < percent:
				current_valid_targets.append(target)
	return current_valid_targets

static func _check_enemy_in_column(filtered_targets: Array, required_count: int) -> Array:
	var current_valid_targets: Array[Character] = []
	for target in filtered_targets:
		var target_pos = null
		var target_team = null
		
		for team in [Battle.blue_team, Battle.red_team]:
			for pos in team:
				if team[pos] == target:
					target_pos = pos
					target_team = team
					break
			if target_pos != null:
				break
		
		if target_pos == null:
			continue
			
		var column = _get_column(target_pos)
		var column_positions = []
		
		match column:
			0:
				column_positions = [Battle.Position.FRONT_TOP, Battle.Position.BACK_TOP]
			1:
				column_positions = [Battle.Position.FRONT_MID, Battle.Position.BACK_MID]
			2:
				column_positions = [Battle.Position.FRONT_BOT, Battle.Position.BACK_BOT]
		
		var enemies_in_column = 0
		for pos in column_positions:
			if target_team[pos] != null and target_team[pos].is_alive():
				enemies_in_column += 1
		
		if enemies_in_column >= required_count:
			current_valid_targets.append(target)
	return current_valid_targets

static func _check_enemy_in_row(filtered_targets: Array, required_count: int) -> Array:
	var current_valid_targets: Array[Character] = []
	for target in filtered_targets:
		var target_pos = null
		var target_team = null
		
		for team in [Battle.blue_team, Battle.red_team]:
			for pos in team:
				if team[pos] == target:
					target_pos = pos
					target_team = team
					break
			if target_pos != null:
				break
		
		if target_pos == null:
			continue
		
		var is_front = target_pos in [Battle.Position.FRONT_TOP, Battle.Position.FRONT_MID, Battle.Position.FRONT_BOT]
		var row_positions = []
		
		if is_front:
			row_positions = [Battle.Position.FRONT_TOP, Battle.Position.FRONT_MID, Battle.Position.FRONT_BOT]
		else:
			row_positions = [Battle.Position.BACK_TOP, Battle.Position.BACK_MID, Battle.Position.BACK_BOT]
		
		var enemies_in_row = 0
		for pos in row_positions:
			if target_team[pos] != null and target_team[pos].is_alive():
				enemies_in_row += 1
		
		if enemies_in_row >= required_count:
			current_valid_targets.append(target)
	return current_valid_targets

# 静态函数，处理技能timing条件的检查
static func check_timing_condition(timing: Dictionary, user: Character, filtered_targets: Array) -> Array:
	match timing.type:
		# 使用者-属性
		"self_mana_above_percent":
			return _check_self_resource_percent(user, filtered_targets, "mana", timing.value, true)
		"self_mana_below_percent":
			return _check_self_resource_percent(user, filtered_targets, "mana", timing.value, false)
		"self_hp_above_percent":
			return _check_self_resource_percent(user, filtered_targets, "health", timing.value, true)
		"self_hp_below_percent":
			return _check_self_resource_percent(user, filtered_targets, "health", timing.value, false)

		#使用者-第x次行动
		"act_number":
			return _check_act_number(user, filtered_targets, timing.value)

		# 敌人-属性
		"enemy_hp_above_percent":
			return _check_enemy_hp_percent(filtered_targets, timing.value, true)
		"enemy_hp_below_percent":
			return _check_enemy_hp_percent(filtered_targets, timing.value, false)

		# 敌人-位置
		"enemy_in_column":
			return _check_enemy_in_column(filtered_targets, timing.value)
		"enemy_in_row_at_least":
			return _check_enemy_in_row(filtered_targets, timing.value)
	
	return []
	
