extends BaseState
class_name PoisonState

func _setup() -> void:
	state_name = "poison"

	description = "行动开始时造成当前生命值的10%伤害"
	animation = "poison_effect"
	effect_trigger = "turn_start" 
	reduce_trigger = "" 
	# 中毒状态不会自然减少，需要治疗解除

func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:

	var current_health = character.get_current_health()
	var damage = int(current_health * 0.1 * value)
	
	# 确保至少造成1点伤害
	damage = max(1, damage)
	
	# 应用伤害
	character.modify_health(-damage)
	
	print("PoisonState.apply_effect %s 受到 %d 层中毒效果影响，损失 %d 点生命值" % [character.character_name, value, damage])
	
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": value,
		"state_effect": {"damage": damage}
	} 