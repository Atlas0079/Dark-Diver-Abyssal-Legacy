class_name CleaveSkill

extends BaseSkill

func _setup(custom_timings: Array = [], custom_priority: int = -1) -> void:
	skill_name = "Cleave"
	skill_type = "active"
	description = "对单个敌人造成伤害，并降低目标的物理攻击力（两层）"
	priority = custom_priority if custom_priority >= 0 else 1
	
	tags = ["slash", "physical", "single_enemy", "enemy_only"]
	animation = "cleave"
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
	
	# 添加攻击效果，1倍伤害
	var damage_multiplier = 1.0
	skillinfo.effects.append(Attack.perform_attack(user, target, "physical", damage_multiplier))
	
	# 添加物理攻击力下降状态（两层）
	StateManager.add_state(target, "physical_attack_down", 2)
	skillinfo.effects.append({"physical_attack_down": 2})
	
	print("应用Cleave")
	return skillinfo 