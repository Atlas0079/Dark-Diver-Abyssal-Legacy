class_name HolySlashSkill

extends BaseSkill

func _setup(custom_timings: Array = [], custom_priority: int = -1) -> void:
	skill_name = "神圣斩击"
	skill_type = "active"
	description = "对单个敌人造成伤害。命中时获得1行动力，击败目标时额外获得1行动力。"
	priority = custom_priority if custom_priority >= 0 else 2
	
	tags = ["slash", "holy", "physical", "single_enemy", "enemy_only"]
	animation = "holy_slash" 
	use_conditions = []
	timings = custom_timings
	passive_trigger = "no_trigger"

# 构建技能效果信息
func _build_skill_info(user: Character, battle: Battle) -> Dictionary:
	return {
		"skill_name": skill_name,
		"caster": user,
		"current_turn": battle.turn_count,
		"effects": []
	}

func apply_effects(user: Character, targets: Array[Character], battle: Battle, context: Dictionary = {}) -> Dictionary:
	
	var target = targets[0]
	
	# 构建技能信息
	var skillinfo = _build_skill_info(user, battle)
	
	# 记录目标是否活着（用于之后判断是否击败）
	var target_was_alive = target.is_alive()
	
	# 添加攻击效果
	skillinfo.effects.append(Attack.perform_attack(user, target, "physical"))
	
	# 命中时获得1行动力
	# Attack.perform_attack返回的字典中is_hit字段表示是否命中
	if skillinfo.effects[0].get("is_hit", false):
		user.modify_battle_stats("action_point", 1)
		skillinfo.effects.append({"hit_gain_action_point": 1})
		print("%s使用神圣斩击命中了目标，获得1点行动力！" % user.character_name)
		
		# 检查是否击败了目标（之前活着，现在死亡）
		if target_was_alive and target.is_dead():
			user.modify_battle_stats("action_point", 1)
			skillinfo.effects.append({"kill_gain_action_point": 1})
			print("%s使用神圣斩击击败了目标，额外获得1点行动力！" % user.character_name)
	
	print("应用神圣斩击")
	return skillinfo 