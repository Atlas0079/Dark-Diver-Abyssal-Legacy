extends BaseSkill
signal targets_modified(new_targets: Array)

func _setup() -> void:
	skill_name = "Cover"
	skill_type = "passive"
	description = "代替一名队友成为技能目标"
	priority = 0
	tags = ["ally_only","single_target","physical"]
	animation = "cover"
	use_conditions = []
	passive_trigger = "skill_and_targets_selected"

func apply_effects(user: Character, targets: Array[Character], battle: Battle):
	# 从目标中选择一个队友进行掩护
	var original_targets = targets.duplicate()
	var protected_target = _choose_target_to_protect(user, original_targets)
	
	if protected_target:
		# 找到被保护目标在数组中的位置
		var target_index = original_targets.find(protected_target)
		if target_index != -1:
			# 只替换这一个目标
			original_targets[target_index] = user
			print("Cover: %s 掩护了 %s" % [user.character_name, protected_target.character_name])
			# 添加不能闪避的状态
			user.add_state("cover_dodge_prohibition")
			# 监听动画完成信号以移除状态
			battle.animation_completed.connect(
				func(): 
					user.remove_state("cover_dodge_prohibition")
					# 断开连接以避免重复调用
					battle.animation_completed.disconnect(battle.animation_completed.get_connections()[0]["callable"])
			, CONNECT_ONE_SHOT) # 使用 ONE_SHOT 确保信号只触发一次
	
	return {
		"modified_targets": original_targets,
		"protected_target": protected_target
	}

# 选择要保护的目标
func _choose_target_to_protect(user: Character, targets: Array[Character]) -> Character:
	# 优先选择生命值最低的队友
	var lowest_hp_target: Character = null
	var lowest_hp_percent = 1.0
	
	for target in targets:
		if target != user:  # 不保护自己
			var hp_percent = float(target.get_current_health()) / target.get_max_health()
			if lowest_hp_target == null or hp_percent < lowest_hp_percent:
				lowest_hp_target = target
				lowest_hp_percent = hp_percent
	
	return lowest_hp_target

func get_targets(user: Character, battle: Battle) -> Array[Character]:
	# 使用PassiveSkillManager中保存的当前技能目标
	var current_targets = PassiveSkillManager.current_targets
	if current_targets == null or current_targets.is_empty():
		return []
		
	# 只有当目标是友方单位时才能掩护
	var valid_targets: Array[Character] = []
	for target in current_targets:
		# 检查目标是否是友方且不是自己
		if target != user and _is_same_team(user, target):
			valid_targets.append(target)
			
	return valid_targets

# 判断是否同队
func _is_same_team(char1: Character, char2: Character) -> bool:
	var in_blue_team1 = char1 in Battle.blue_team.values()
	var in_blue_team2 = char2 in Battle.blue_team.values()
	return in_blue_team1 == in_blue_team2
	
