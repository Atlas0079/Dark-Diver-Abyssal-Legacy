extends Node
class_name CombatResolver

# 处理单次伤害判定的主函数
static func resolve_combat(attacker: Character, defender: Character, base_damage: int, attack_type: String) -> Dictionary:
	var result = {
		"target": defender,
		"damage": base_damage,
		"hit_type": "normal"  # normal, dodge, block, critical
	}
	
	# 1. 闪避判定
	if _check_dodge(attacker, defender):
		result.hit_type = "dodge"
		result.damage = 0
		return result
	
	# 2. 格挡判定
	if _check_block(attacker, defender,attack_type):
		result.hit_type = "block"
		result.damage = base_damage
		return result

	# 3. 暴击判定
	if _check_crit(attacker, defender,attack_type):
		result.hit_type = "critical"
		result.damage = base_damage
		return result
	

	return result

static func judge_dodge(attacker: Character, defender: Character, battle: Battle) -> Dictionary:
	var dodge_rate = defender.get_actual_combat_stat("dodge_rate")
	var hit_rate = attacker.get_actual_combat_stat("hit_rate")
	var final_dodge_rate = clamp(dodge_rate - hit_rate, 0, 100)
	var dodge_chance = final_dodge_rate / 100.0
	print("CombatResolver judge_dodge dodge_rate: ",dodge_rate," vs ",hit_rate," = ",final_dodge_rate
	)
	return {
		"target": defender,
		"hit_type": "dodge" if randf() < dodge_chance else "normal"
	}


static func judge_block(attacker: Character, defender: Character,battle: Battle) -> Dictionary:
	var block_rate = defender.get_actual_combat_stat("block_rate")

	var hit_rate = attacker.get_actual_combat_stat("hit_rate")
	if defender.has_state("block_prohibition"):
		block_rate = 0
	var final_block_rate = clamp(block_rate - hit_rate, 0, 100)
	print("CombatResolver judge_block final_block_rate: ",hit_rate," vs ",block_rate," = ",final_block_rate)
	var block_chance = final_block_rate / 100.0
	var block_value = defender.get_actual_combat_stat("block_value")
	if randf() < block_chance:
		var result = {
			"target": defender,
			"hit_type": "block",  # normal, dodge, block, critical
			"block_value": block_value
		}
		return result
	else:
		return {
			"target": defender,
			"hit_type": "normal",  # normal, dodge, block, critical
		}


static func judge_crit(attacker: Character, defender: Character,attack_value: int, battle: Battle) -> Dictionary:
	var crit_rate = attacker.get_actual_combat_stat("crit_rate")
	var final_crit_rate = clamp(crit_rate, 0, 100)
	var crit_chance = final_crit_rate / 100.0
	if randf() < crit_chance:
		var result = {
			"target": defender,
			"hit_type": "critical",  # normal, dodge, block, critical
			"crit_value": attack_value * 1.5
		}
		return result
	else:
		return {
			"target": defender,
			"hit_type": "normal",  # normal, dodge, block, critical
		}

static func calculate_damage(attacker: Character, defender: Character,attack_value: int, attack_type: String,battle: Battle) -> int:
	if attack_type == "physical":
		var defense = defender.get_actual_combat_stat("physical_defense")
		return int(max(attack_value - defense, 1))
	if attack_type == "magic":
		var defense = defender.get_actual_combat_stat("magic_defense")
		return int(max(attack_value - defense, 1))
	else:
		push_error("Combat_resolver _calculate_physical_block_damage Invalid attack type: " + attack_type)
		return 0


# 检查闪避

static func _check_dodge(attacker: Character, defender: Character) -> bool:

	# 获取基础属性
	var dodge_rate = defender.get_actual_combat_stat("dodge_rate")
	var hit_rate = attacker.get_actual_combat_stat("hit_rate")
	
	# 计算最终闪避率（限制在0-100之间）
	var final_dodge_rate = clamp(dodge_rate - hit_rate, 0, 100)
	
	# 转换为0-1之间的概率值
	var dodge_chance = final_dodge_rate / 100.0
	
	# 进行闪避判定
	return randf() < dodge_chance

# 检查格挡
static func _check_block(attacker: Character, defender: Character, attack_type: String) -> bool:
	var block_rate = defender.get_actual_combat_stat("block_rate")
	var hit_rate = attacker.get_actual_combat_stat("hit_rate")
	
	# 计算最终格挡率（限制在0-100之间）
	var final_block_rate = clamp(block_rate - hit_rate, 0, 100)
	
	# 转换为0-1之间的概率值
	var block_chance = final_block_rate / 100.0
	
	# 进行格挡判定  
	return randf() < block_chance

# 检查暴击
static func _check_crit(attacker: Character, defender: Character, attack_type: String) -> bool:
	var crit_rate = attacker.get_actual_combat_stat("crit_rate")
	# 计算最终暴击率（限制在0-100之间）
	var final_crit_rate = clamp(crit_rate, 0, 100)
	# 转换为0-1之间的概率值
	var crit_chance = final_crit_rate / 100.0
	# 进行暴击判定  
	return randf() < crit_chance

# 计算格挡伤害
static func _calculate_block_damage(attacker: Character, defender: Character, base_damage: int, attack_type: String) -> int:
	if attack_type == "physical":
		var defense = defender.get_actual_combat_stat("physical_defense") + defender.get_actual_combat_stat("block_value")
		return int(max(base_damage - defense, 1))
	if attack_type == "magic": 
		var defense = defender.get_actual_combat_stat("magic_defense") + defender.get_actual_combat_stat("block_value")
		return int(max(base_damage - defense, 1))
	else:
		push_error("Combat_resolver _calculate_physical_block_damage Invalid attack type: " + attack_type)
		return 0



# 计算暴击伤害
static func _calculate_physical_crit_damage(attacker: Character, defender: Character, base_damage: int) -> int:
	return int(base_damage * 1.5)
