extends BaseState 
class_name MagicalAttackUpState

func _setup() -> void:
	state_name = "magical_attack_up"
	effect_trigger = "combat_stat_modify"
	description = "魔法攻击力提升。每层增加10%魔法攻击力。"
	animation = "buff_effect"
	counter_state = ""

# 这个状态不直接造成效果，而是影响角色属性计算
func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:
	print("MagicalAttackUpState.apply_effect %s 拥有 %d 层魔法攻击力提升状态" % [character.character_name, value])
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": value,
		"state_effect": {"bonus_percent": value * 10}
	}

# 计算加成到魔法攻击力的百分比值
func get_attack_bonus_percent(value: int) -> float:
	return value * 0.1  # 每层提供10%加成

func nature_decay(battle: Battle, character: Character) -> Dictionary:
	# 如果有减少层数的需求，可以在这里实现
	return {} 