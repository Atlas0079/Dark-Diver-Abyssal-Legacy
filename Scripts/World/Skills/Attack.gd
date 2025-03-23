extends Node
class_name Attack


# 攻击结果的字典结构
# {
#   "attacker": Character, # 攻击发起者
#   "target": Character,   # 受击者
#   "hit_type": String,   # 命中类型 miss、block、crit、normal
#   "damage": int,         # 造成的伤害
#   "is_hit": bool         # 是否命中（包括普通、暴击、格挡）
# }

# 进行一次攻击计算
# power: 攻击力，可选参数，如果不提供则使用attacker的attack_power
# attack_type: 攻击类型，默认为物理攻击
# damage_multiplier: 伤害倍率，如1.5表示最终伤害增加50%

static func perform_attack(attacker: Character, target: Character, attack_type: String = "physical", damage_multiplier: float = 1.0) -> Dictionary:

	# 计算命中类型
	var hit_type = calculate_hit_type(attacker, target) 
	
	# 计算伤害
	var damage = calculate_damage(attacker, target, hit_type, attack_type, damage_multiplier)
	
	# 如果不是闪避，则造成伤害
	var is_hit = hit_type != "miss"
	if is_hit:
		target.modify_health(-damage)
	else:
		damage = 0
	
	# 返回攻击结果
	return {
		"attacker": attacker,
		"target": target,
		"hit_type": hit_type,
		"damage": damage,
		"is_hit": is_hit
	}

# 计算命中类型
static func calculate_hit_type(attacker: Character, target: Character) -> String:
	# 获取并应用状态修饰后的属性
	var modified_attrs = get_modified_attributes(attacker, target)
	
	# 判定流程：按照闪避->格挡->暴击的顺序进行判定
	
	# 1. 闪避判定
	if check_evasion(attacker, target, modified_attrs.attacker_accuracy, modified_attrs.target_evasion):
		return "miss"
	
	# 2. 格挡判定
	if check_block(attacker, target, modified_attrs.target_block_rate):
		return "block"
	
	# 3. 暴击判定
	if check_critical(attacker, modified_attrs.attacker_crit_rate):
		return "crit"
	
	# 4. 如果以上都不是，则为普通命中
	return "normal"

# 获取经过状态修饰的角色属性
static func get_modified_attributes(attacker: Character, target: Character) -> Dictionary:
	# 获取基础属性
	var attacker_accuracy = attacker.base_attributes["hit_rate"]
	var attacker_crit_rate = attacker.base_attributes["crit_rate"]
	var target_evasion = target.base_attributes["dodge_rate"]
	var target_block_rate = target.base_attributes["block_rate"]
	
	print("命中计算 - 攻击者:%s 命中率:%s, 目标:%s 闪避率:%s" % [
		attacker.character_name, 
		attacker_accuracy, 
		target.character_name, 
		target_evasion
	])
	
	# 应用状态修饰
	# 检查命中率提升状态
	if attacker.has_state("accuracy_up"):
		var accuracy_layers = attacker.get_state_value("accuracy_up")
		attacker_accuracy += accuracy_layers * 5  # 每层提升5%命中率
	
	# 检查暴击率提升状态
	if attacker.has_state("crit_rate_up"):
		var crit_layers = attacker.get_state_value("crit_rate_up")
		attacker_crit_rate += crit_layers * 5  # 每层提升5%暴击率
	
	# 检查闪避率提升状态
	if target.has_state("evasion_up"):
		var evasion_layers = target.get_state_value("evasion_up")
		target_evasion += evasion_layers * 5  # 每层提升5%闪避率
	
	if target.has_state("block_rate_up"):
		var block_layers = target.get_state_value("block_rate_up")
		target_block_rate += block_layers * 5  # 每层提升5%格挡率

	# 返回经过修饰的属性
	return {
		"attacker_accuracy": attacker_accuracy,
		"attacker_crit_rate": attacker_crit_rate,
		"target_evasion": target_evasion,
		"target_block_rate": target_block_rate
	}

# 检查闪避是否成功
# 返回true表示闪避成功，返回false表示闪避失败
static func check_evasion(attacker: Character, target: Character, attacker_accuracy: int, target_evasion: int) -> bool:
	# 如果目标有cover_dodge_prohibit状态，则无法闪避
	if target.has_state("cover_dodge_prohibit"):
		print("命中判定 - 目标%s处于闪避禁止状态，跳过闪避判定" % target.character_name)
		return false
	
	# 计算命中率
	var hit_chance = attacker_accuracy - target_evasion
	hit_chance = clamp(hit_chance, 1, 99)
	
	# 掷骰
	var roll = randf() * 100
	print("命中判定 - 最终命中率:%s, 骰点:%s" % [hit_chance, roll])
	
	# 判断是否闪避成功
	if roll > hit_chance or attacker.has_state("blind"):
		StateManager.remove_state(attacker, "blind")
		return true  # 闪避成功
	
	return false  # 闪避失败

# 检查格挡是否成功
# 返回true表示格挡成功，返回false表示格挡失败
static func check_block(attacker: Character, target: Character, target_block_rate: int) -> bool:
	# 如果攻击者有"unblockable"状态，则目标无法格挡
	if attacker.has_state("unblockable"):
		print("格挡判定 - 攻击者%s拥有无法格挡状态，跳过格挡判定" % attacker.character_name)
		return false
	
	# 计算格挡率
	var block_chance = target_block_rate
	


	
	block_chance = clamp(block_chance, 0, 100)
	
	# 掷骰
	var roll = randf() * 100
	print("格挡判定 - 格挡率:%s, 骰点:%s" % [block_chance, roll])
	
	# 判断是否格挡成功
	if roll < block_chance:
		return true  # 格挡成功
	
	return false  # 格挡失败

# 检查暴击是否触发
# 返回true表示暴击成功，返回false表示普通命中
static func check_critical(attacker: Character, attacker_crit_rate: int) -> bool:
	# 计算暴击率
	var crit_chance = attacker_crit_rate
	
	# 如果有必定暴击状态
	if attacker.has_state("always_crit"):
		print("暴击判定 - 攻击者%s拥有必定暴击状态" % attacker.character_name)
		crit_chance = 100
	
	crit_chance = clamp(crit_chance, 0, 100)
	
	# 掷骰
	var roll = randf() * 100
	print("暴击判定 - 暴击率:%s, 骰点:%s" % [crit_chance, roll])
	
	# 判断是否暴击成功
	if roll < crit_chance:
		return true  # 暴击成功
	
	return false  # 普通命中

# 计算伤害值
# damage_multiplier: 伤害倍率，如1.5表示最终伤害增加50%
static func calculate_damage(attacker: Character, target: Character, hit_type: String, attack_type: String, damage_multiplier: float = 1.0) -> int:
	# 1. 获取基础攻击力和防御力
	var base_stats = get_attack_defense_stats(attacker, target, attack_type)
	var attack_power = base_stats.attack_power
	var defense = base_stats.defense
	
	# 2. 计算基础伤害
	var base_damage = max(1, attack_power - defense)
	
	# 3. 应用命中类型对伤害的修正
	var hit_modified_damage = apply_hit_type_modifiers(attacker, target, hit_type, base_damage)
	
	# 4. 应用伤害倍率
	var final_damage = int(hit_modified_damage * damage_multiplier)
	if damage_multiplier != 1.0:
		print("伤害倍率：%s × %.2f = %s" % [hit_modified_damage, damage_multiplier, final_damage])
	
	print("最终伤害:%s, 命中类型:%s" % [final_damage, hit_type])
	return final_damage

# 获取角色的攻击力和防御力数值
static func get_attack_defense_stats(attacker: Character, target: Character, attack_type: String) -> Dictionary:
	# 获取实际战斗属性
	var attack_power = attacker.get_actual_combat_stat("physical_attack") if attack_type == "physical" else attacker.get_actual_combat_stat("magical_attack")
	var defense = target.get_actual_combat_stat("physical_defense") if attack_type == "physical" else target.get_actual_combat_stat("magical_defense")
	
	print("伤害计算 - 攻击力:%s, 防御力:%s" % [attack_power, defense])
	
	return {
		"attack_power": attack_power,
		"defense": defense
	}

# 应用命中类型对伤害的修正
static func apply_hit_type_modifiers(attacker: Character, target: Character, hit_type: String, base_damage: int) -> int:
	var final_damage = base_damage
	
	# 根据命中类型调整伤害
	match hit_type:
		"crit":
			# 暴击伤害修正
			final_damage = apply_critical_modifier(attacker, final_damage)
		"block":
			# 格挡伤害修正
			final_damage = apply_block_modifier(target, final_damage)
		"normal":
			# 普通命中不做修正
			pass
		"miss":
			# 闪避伤害为0
			final_damage = 0
	
	return final_damage

# 应用暴击伤害修正
static func apply_critical_modifier(attacker: Character, damage: int) -> int:
	var crit_multiplier = attacker.get_actual_combat_stat("crit_damage")
	var crit_damage = int(damage * crit_multiplier)
	print("暴击伤害：基础伤害 %s × 暴击倍率 %s = %s" % [damage, crit_multiplier, crit_damage])
	return crit_damage

# 应用格挡伤害修正
static func apply_block_modifier(target: Character, damage: int) -> int:
	var block_value = target.get_block_value()
	var blocked_damage = max(1, damage - block_value)
	print("格挡伤害：基础伤害 %s - 格挡值 %s = %s" % [damage, block_value, blocked_damage])
	return blocked_damage
