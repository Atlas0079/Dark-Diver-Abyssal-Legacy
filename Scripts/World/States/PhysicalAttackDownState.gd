extends BaseState 
class_name PhysicalAttackDownState

func _setup() -> void:
	state_name = "physical_attack_down"
	effect_trigger = "combat_stat_modify"
	description = "物理攻击力下降。每层减少10%物理攻击力。"
	animation = "debuff_effect"
	counter_state = ""

# 这个状态不直接造成效果，而是影响角色属性计算
func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:
	print("PhysicalAttackDownState.apply_effect %s 拥有 %d 层物理攻击力下降状态" % [character.character_name, value])
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": value,
		"state_effect": {"penalty_percent": value * 10}
	}

# 获取攻击力减少百分比
func get_attack_penalty_percent(value: int) -> float:
	return value * 0.1  # 每层减少10%的攻击力

func nature_decay(battle: Battle, character: Character) -> Dictionary:
	# 如果有减少层数的需求，可以在这里实现
	return {} 