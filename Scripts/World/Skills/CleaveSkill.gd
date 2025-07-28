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
	
	var skillinfo = _build_skill_info(user, battle)
	
	# 遍历所有目标
	for target in targets:
		# --- 攻击效果 ---
		var damage_multiplier = 1.0
		var attack_result = Attack.perform_attack(user, target, "physical", damage_multiplier)
		
		var effect_package = {
			"targets": [target],
			"damage": attack_result.get("damage", 0),
			"hit_type": attack_result.get("hit_type", "miss"),
			"applied_states": [], # 初始化
			"removed_states": []
		}
		
		# --- 状态效果 ---
		if attack_result.get("hit_type", "miss") != "miss":
			StateManager.add_state(target, "physical_attack_down", 2)
			effect_package.applied_states.append({"physical_attack_down": 2}) # 假设持续2回合
		
		# 添加到最终效果列表
		skillinfo.effects.append(effect_package)
	
	print("应用Cleave")
	return skillinfo 