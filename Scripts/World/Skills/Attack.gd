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

static func perform_attack(attacker: Character, target: Character, attack_type: String = "physical") -> Dictionary:

	# 计算命中类型
	var hit_type = calculate_hit_type(attacker, target) 
	
	# 计算伤害
	var damage = calculate_damage(attacker, target, hit_type, attack_type)
	
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
	# 获取角色属性
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
	
	# 检查状态修饰
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
	


	# 随机数生成器
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# 闪避判定
	var hit_chance = attacker_accuracy - target_evasion
	hit_chance = clamp(hit_chance, 1, 99)
	var roll = randf() * 100
	print("命中判定 - 最终命中率:%s, 骰点:%s" % [hit_chance, roll])
	
	if roll > hit_chance or attacker.has_state("blind"):
		StateManager.remove_state(attacker,"blind")
		return "miss"
	
	# 格挡判定（如果攻击者有"unblockable"状态则跳过）
	if not attacker.has_state("unblockable"):
		var block_chance = target_block_rate
		# 检查格挡率提升状态
		if target.has_state("block_rate_up"):
			var block_layers = target.get_state_value("block_rate_up")
			block_chance += block_layers * 5  # 每层提升5%格挡率
		
		block_chance = clamp(block_chance, 0, 100)
		if rng.randf() * 100 < block_chance:
			return "block"
	
	# 暴击判定（如果攻击者有"always_crit"状态则必定暴击）
	var crit_chance = attacker_crit_rate
	if attacker.has_state("always_crit"):
		crit_chance = 100
	crit_chance = clamp(crit_chance, 0, 100)
	if rng.randf() * 100 < crit_chance:
		return "crit"
	
	# 普通命中
	return "normal"

# 计算伤害值
static func calculate_damage(attacker: Character, target: Character, hit_type: String, attack_type: String) -> int:
	# 获取实际战斗属性
	var attack_power = attacker.get_actual_combat_stat("physical_attack") if attack_type == "physical" else attacker.get_actual_combat_stat("magical_attack")
	var defense = target.get_actual_combat_stat("physical_defense") if attack_type == "physical" else target.get_actual_combat_stat("magical_defense")
	
	print("伤害计算 - 攻击力:%s, 防御力:%s" % [attack_power, defense])
	
	# 基础伤害计算
	var base_damage = max(1, attack_power - defense)
	
	# 根据命中类型调整伤害
	match hit_type:
		"crit":
			var crit_multiplier = attacker.get_actual_combat_stat("crit_damage")
			base_damage = int(base_damage * crit_multiplier)
		"block":
			var block_value = target.get_block_value()
			base_damage = max(1, base_damage - block_value)
	
	print("最终伤害:%s, 命中类型:%s" % [base_damage, hit_type])
	return base_damage
