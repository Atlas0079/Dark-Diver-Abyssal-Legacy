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




func apply_effects(user: Character, targets: Array[Character], battle: Battle, context: Dictionary = {}) -> Dictionary:
	
	var skillinfo = _build_skill_info(user, battle)
	
	# 检查使用者生命值是否低于50%
	var user_health_percent = float(user.resources.health.current) / float(user.resources.health.max) * 100.0
	var damage_multiplier = 1.0
	
	if user_health_percent < 50.0:
		damage_multiplier = 1.5  # 50%伤害加成
		print("斩击强化：生命值低于50%，获得50%额外伤害加成！")

	# --- 核心修改在这里 ---
	# 遍历所有目标，为每个目标生成一个标准的效果包
	for target in targets:
		# 1. 获取原始攻击结果
		var attack_result = Attack.perform_attack(user, target, "physical", damage_multiplier)
		
		# 2. 转换成标准格式，符合 BattleEvent.gd 规范
		var effect_package = {
			"targets": [target], # 注意：这里是数组
			"damage": attack_result.get("damage", 0),
			"hit_type": attack_result.get("hit_type", "miss"),
			# 根据规范，applied_states 和 removed_states 即使为空也应该存在
			"applied_states": [], 
			"removed_states": []
		}
		
		# 3. 将标准格式的效果包添加到数组中
		skillinfo.effects.append(effect_package)

	print("应用Slash")
	return skillinfo

