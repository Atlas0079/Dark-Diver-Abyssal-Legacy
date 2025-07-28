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
	
	var skillinfo = _build_skill_info(user, battle)
	
	# 神圣斩击只攻击一个目标
	var target = targets[0]
	
	# 记录目标是否活着（用于之后判断是否击败）
	var target_was_alive = target.is_alive()
	
	# 1. 获取原始攻击结果
	var attack_result = Attack.perform_attack(user, target, "physical")
	
	# 2. 创建标准效果包
	var effect_package = {
		"targets": [target],
		"damage": attack_result.get("damage", 0),
		"hit_type": attack_result.get("hit_type", "miss"),
		"applied_states": [],
		"removed_states": []
	}
	
	# 将攻击效果包添加到数组中
	skillinfo.effects.append(effect_package)
	
	# 3. 处理后续效果
	if attack_result.get("hit_type") != "miss":
	# 命中时获得1行动力
		user.modify_battle_stats("action_point", 1)
		# 这是一个对自身的效果，所以目标是user
		var self_effect_package = {
			"targets": [user],
			"battle_stats_change": {"action_point": 1} # 使用更具描述性的键
		}
		skillinfo.effects.append(self_effect_package)
		print("%s使用神圣斩击命中了目标，获得1点行动力！" % user.character_name)
		
		# 检查是否击败了目标（之前活着，现在死亡）
		if target_was_alive and target.is_dead():
			user.modify_battle_stats("action_point", 1)
			# 可以创建另一个效果包，或在同一个包里追加
			var kill_effect_package = {
				"targets": [user],
				"battle_stats_change": {"action_point": 1}
			}
			skillinfo.effects.append(kill_effect_package)
			print("%s使用神圣斩击击败了目标，额外获得1点行动力！" % user.character_name)
	
	print("应用神圣斩击")
	return skillinfo 