extends BaseState
class_name CoverDodgeProhibitState

func _setup() -> void:
	state_name = "cover_dodge_prohibit"
	effect_trigger = ""  # 这个状态不需要主动触发效果
	reduce_trigger = "skill_end"  # 在技能结束时自动减少
	description = "盾牌格挡后暂时禁止闪避，在技能效果结束后自动消失"
	animation = "cover_effect"
	counter_state = ""

func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:
	# 这个状态不会主动应用效果，它只是作为一个标记
	print("CoverDodgeProhibitState: %s 处于闪避禁止状态" % character.character_name)
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": value,
		"state_effect": {"dodge_prohibited": true}
	}

func nature_decay(battle: Battle, character: Character) -> Dictionary:
	# 在reduce_trigger指定的时机（skill_end）自动移除状态
	StateManager.remove_state(character, state_name)
	print("CoverDodgeProhibitState: %s 的闪避禁止状态已移除" % character.character_name)
	return {
		"state_name": state_name,
		"animation": "",
		"state_duration": 0,
		"state_effect": {"removed": true}
	} 