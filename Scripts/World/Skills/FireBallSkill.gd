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
	
	var skillinfo = _build_skill_info(user, battle)
	
	# 遍历所有目标，为每个目标生成效果
	for target in targets:
		# --- 攻击效果 ---
		# 1. 先获取攻击的计算结果
		var attack_result = Attack.perform_attack(user, target, "magic")
		
		# 2. 将它改造成标准格式
		var attack_effect_package = {
			"targets": [target],
			"damage": attack_result.get("damage", 0),
			"hit_type": attack_result.get("hit_type", "miss"),
			"applied_states": [], # 先初始化为空
			"removed_states": []
		}
		
		# --- 燃烧效果 ---
		# 3. 施加状态（逻辑上）
		if attack_result.get("hit_type", "miss") != "miss":
			StateManager.add_state(target, "burn", 1)
			# 4. 将状态效果附加到攻击效果包中
			attack_effect_package.applied_states.append({"burn": 1})
		
		# 5. 将最终完整的标准效果包添加到数组中
		skillinfo.effects.append(attack_effect_package)

	print("应用Fireball - 已使用标准格式")
	return skillinfo

