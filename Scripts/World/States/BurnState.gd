extends BaseState 
class_name BurnState

func _setup() -> void:
	state_name = "burn"
	effect_trigger = "action_start"
	description = "行动开始时造成4点伤害，与寒冷状态抵消"
	animation = "burn_effect"
	counter_state = "cold"

func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:
	var damage = value * 2  # 每层2点伤害
	character.modify_health(-damage)
	print("BurnState.apply_effect %s 受到 %d 层燃烧效果影响，损失 %d 点生命值" % [character.character_name, value, damage])
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": value,
		"state_effect": {"damage": damage}
	} 

