extends BaseState 
class_name PhysicalAttackUpState

func _setup() -> void:
	state_name = "physical_attack_up"
	effect_trigger = "combat_stat_modify"
	description = "物理攻击力提升。每层增加10%物理攻击力。"
	animation = "buff_effect"
	counter_state = ""

# 这个状态不直接造成效果，而是影响角色属性计算
func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:
	print("PhysicalAttackUpState.apply_effect %s 拥有 %d 层物理攻击力提升状态" % [character.character_name, value])
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": value,
		"state_effect": {"bonus_percent": value * 10}
	}

# 计算加成到物理攻击力的百分比值
func get_attack_bonus_percent(value: int) -> float:
	return value * 0.1  # 每层提供10%加成

func nature_decay(battle: Battle, character: Character) -> Dictionary:
	# 如果有减少层数的需求，可以在这里实现
	return {} 