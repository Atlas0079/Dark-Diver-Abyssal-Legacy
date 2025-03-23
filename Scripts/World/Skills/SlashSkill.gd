class_name SlashSkill

extends BaseSkill

func _setup(custom_timings: Array = [], custom_priority: int = -1) -> void:
	skill_name = "Slash"
	skill_type = "active"
	description = "对单个敌人造成伤害。当自身生命值低于50%时，额外获得50%伤害加成。"
	priority = custom_priority if custom_priority >= 0 else 1
	
	tags = ["slash", "physical", "single_enemy", "enemy_only"]
	animation = "slash" 
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
	
	# 检查使用者生命值是否低于50%
	var user_health_percent = float(user.resources.health.current) / float(user.resources.health.max) * 100.0
	var damage_multiplier = 1.0
	
	if user_health_percent < 50.0:
		damage_multiplier = 1.5  # 50%伤害加成
		print("斩击强化：生命值低于50%，获得50%额外伤害加成！")
	
	# 添加攻击效果，并传递伤害倍率信息
	skillinfo.effects.append(Attack.perform_attack(user, target, "physical", damage_multiplier))
	print("应用Slash")
	return skillinfo

