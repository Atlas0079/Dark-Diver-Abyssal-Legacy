class_name FireballSkill

extends BaseSkill

func _setup(custom_timings: Array = [], custom_priority: int = -1) -> void:
	skill_name = "Fireball"
	skill_type = "active"
	description = "对单个敌人造成伤害，造成1层燃烧状态"
	priority = custom_priority if custom_priority >= 0 else 1
	
	tags = ["magic", "single_enemy", "enemy_only"]
	animation = "fireball"
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
	
	# 添加攻击效果
	skillinfo.effects.append(Attack.perform_attack(user, target, "magic"))
	StateManager.add_state(target, "burn", 1)
	skillinfo.effects.append({"burn": 1})
	print("应用Fireball")
	return skillinfo

