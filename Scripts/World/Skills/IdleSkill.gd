class_name IdleSkill

extends BaseSkill

func _setup(custom_timings: Array = [], custom_priority: int = -1) -> void:
	skill_name = "Idle"
	skill_type = "active"
	description = "空闲"
	priority = 100 # 优先级最低
	
	tags = ["self"]
	animation = "idle"
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
	# 构建技能信息
	var skillinfo = _build_skill_info(user, battle)
	
	# 添加攻击效果
	user.resources["health"]["current"] += 1
	user.resources["mana"]["current"] += 1
	print("应用Idle")
	return skillinfo

