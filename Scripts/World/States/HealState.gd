extends BaseState
class_name HealState

func _setup() -> void:
	state_name = "heal"
	effect_trigger = "turn_start"
	reduce_trigger = "turn_start"
	description = "每回合开始时回复每层1点生命值"
	animation = "heal_effect"

func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:
	var heal_amount = 1  	
	# 应用治疗
	character.modify_health(heal_amount)
	StateManager.remove_state_by_value(character,state_name,1)
	
	print("%s 受到 %d 层治愈效果影响，回复 %d 点生命值" % [character.character_name, value, heal_amount])
	
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": value,
		"state_effect": {"heal": heal_amount}
	} 
func nature_decay(battle: Battle, character: Character) -> Dictionary:
	StateManager.remove_state_by_value(character, state_name, 1)
	print("%s 的治愈状态自然消除了1层" % character.character_name)
	
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": 1,
		"state_effect": {"decay": 1},
	}
