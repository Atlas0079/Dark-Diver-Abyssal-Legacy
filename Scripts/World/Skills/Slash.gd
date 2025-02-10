class_name Slash
extends BaseSkill

func _setup() -> void:
	skill_name = "Slash"
	skill_type = "active"
	description = "对单个敌人造成物理伤害"
	priority = 0
	tags = ["enemy_only","melee","single_target","physical"]
	animation = "slash"
	use_conditions = []

func apply_effects(user: Character, targets: Array[Character], battle: Battle) -> Dictionary:
	# 1. 初始化基础数据
	var base_damage = user.get_actual_combat_stat("physical_attack")
	var attack_type = "physical"
	# HP低于50%时伤害提升
	if user.get_current_health() < user.get_max_health() * 0.5:
		base_damage *= 1.5

	var result = {
		"target": targets[0],
		"base_damage": base_damage,
		"attack_type": attack_type
	}
	
	# 2. 闪避判定
	var dodge_result = CombatResolver.judge_dodge(user, targets[0], battle)
	if dodge_result.hit_type == "dodge":
		result.merge(dodge_result, true)
		print("Slash apply_effects dodge success")
		return result
	


	# 3. 格挡判定
	var block_result = CombatResolver.judge_block(user, targets[0], battle)
	if block_result.hit_type == "block":
		result.merge(block_result, true)
		result.damage = CombatResolver.calculate_damage(user, targets[0], base_damage, attack_type, battle)
		print("Slash apply_effects block success ,block_value:",block_result.block_value)
		return result


	# 4. 暴击判定
	var crit_result = CombatResolver.judge_crit(user, targets[0], base_damage, battle)
	if crit_result.hit_type == "critical":
		result.merge(crit_result, true)
		result.damage = crit_result.crit_value
		print("Slash apply_effects crit success")
		return result
	

	# 5. 普通命中
	result.hit_type = "normal"
	result.damage = CombatResolver.calculate_damage(user, targets[0], base_damage, attack_type, battle)
	print("Slash apply_effects normal success ,damage:",result.damage)
	return result

func final_damage(attack: int,defense: int) -> int:
	return int(max(attack - defense, 1))
