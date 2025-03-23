class_name ShieldBlockSkill

extends BaseSkill

func _setup(custom_timings: Array = [], custom_priority: int = -1) -> void:
	skill_name = "盾格挡"
	skill_type = "passive"
	description = "在被攻击时，获得一层盾格挡状态，必定触发格挡且无法闪避。"
	priority = custom_priority if custom_priority >= 0 else 2
	
	tags = ["shield", "defense", "self"]
	animation = "shield_block"
	use_conditions = []
	timings = custom_timings
	passive_trigger = "on_skill_before"

# 构建技能效果信息
func _build_skill_info(user: Character, battle: Battle) -> Dictionary:
	return {
		"skill_name": skill_name,
		"caster": user,
		"current_turn": battle.turn_count,
		"effects": []
	}

# 检查是否应该触发盾格挡
func get_targets_with_context(user: Character, battle: Battle, context: Dictionary) -> Array[Character]:
	# 检查是否已经有盾格挡状态
	if user.has_state("shield_block_state"):
		return []
		
	# 只有当用户是攻击目标时才会触发
	if not context.has("trigger_targets") or not (user in context.trigger_targets):
		return []
		
	# 检查触发技能是否为物理或魔法攻击
	var trigger_skill = context.get("trigger_skill")
	if not trigger_skill or not (trigger_skill.tags.has("physical") or trigger_skill.tags.has("magic")):
		return []
		
	# 检查使用者是否装备了盾牌
	var has_shield = false
	for accessory in user.equipment.accessories:
		if accessory and accessory.has_tag("shield"):
			has_shield = true
			break
			
	if not has_shield:
		return []
		
	# 满足所有条件，返回自己作为目标
	return [user]

func apply_effects(user: Character, targets: Array[Character], battle: Battle, context: Dictionary = {}) -> Dictionary:
	# 构建技能信息
	var skillinfo = _build_skill_info(user, battle)
	
	# 添加盾格挡状态
	StateManager.add_state(user, "shield_block_state", 1)
	print("%s 触发盾格挡，获得1层盾格挡状态！" % user.character_name)
	
	skillinfo.effects.append({
		"type": "add_state",
		"state": "shield_block_state",
		"value": 1
	})
	
	return skillinfo 