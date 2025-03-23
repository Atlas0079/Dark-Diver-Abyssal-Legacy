class_name CoverSkill

extends BaseSkill

func _setup(custom_timings: Array = [], custom_priority: int = -1) -> void:
	skill_name = "Cover"
	skill_type = "passive"
	description = "为单个队友提供掩护"
	priority = custom_priority
	
	tags = ["cover", "single_ally", "ally_only"]
	animation = "cover"
	use_conditions = []
	timings = custom_timings
	passive_trigger = "on_targets_selected"



# 将输入的列表中的一个队友替换为施法者，
func apply_effects(user: Character, original_targets: Array[Character], battle: Battle, context: Dictionary = {}) -> Dictionary:
	StateManager.add_state(user, "cover_dodge_prohibit", 1)
	var cover_targets = get_targets_with_context(user, battle, context) 
	
	# 创建新的目标数组，而不是直接修改原数组
	var new_targets = original_targets.duplicate()
	
	# 将匹配cover_targets的元素替换为user
	for i in range(new_targets.size()):
		if cover_targets.has(new_targets[i]):
			new_targets[i] = user
	
	# 构建技能信息
	var skill_info = _build_skill_info(user, battle)
	skill_info.effects.append({
		"type": "cover",
		"new_targets": new_targets  # 使用新的目标数组
	})
	return skill_info


func get_targets_with_context(user: Character, battle: Battle, context: Dictionary) -> Array[Character]: 
	# 如果不满足基本条件，直接返回空数组
	if not _is_valid_cover_trigger(user, context, battle):
		return []
	
	# 获取可能需要保护的队友列表
	var allies_to_protect = _get_allies_to_protect(user, context, battle)
	if allies_to_protect.is_empty():
		return []
	
	# 应用timing条件，获取最终要保护的队友
	# 这里简化为只保护第一个队友，可以根据需要扩展选择逻辑
	return [allies_to_protect[0]]

# 检查是否是有效的掩护触发条件
func _is_valid_cover_trigger(user: Character, context: Dictionary, battle: Battle) -> bool:
	# 检查必要的上下文信息是否存在
	if not (context.has("trigger_skill") and context.has("trigger_character") and context.has("trigger_targets")):
		return false
	
	# 检查触发技能是否为物理或魔法攻击
	var trigger_skill = context["trigger_skill"]
	if not (trigger_skill.tags.has("physical") or trigger_skill.tags.has("magic")):
		return false
	
	# 检查触发角色是否为敌方
	var trigger_character = context["trigger_character"]
	return not battle.are_characters_in_same_team(user, trigger_character)

func _get_allies_to_protect(user: Character, context: Dictionary, battle: Battle) -> Array:
	var allies_to_protect = []
	
	# 检查目标中是否有队友
	for target in context["trigger_targets"]:
		# 如果目标是队友（同队且不是自己）
		if battle.are_characters_in_same_team(user, target) and target != user:
			allies_to_protect.append(target)
	
	return allies_to_protect



	
