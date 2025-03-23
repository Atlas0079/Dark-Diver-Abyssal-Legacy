extends BaseState 
class_name ShieldBlockState

func _setup() -> void:
	state_name = "shield_block_state"
	effect_trigger = ""  # 技能结束时触发效果
	reduce_trigger = "skill_end"  # 技能结束时减少状态层数
	description = "必定触发格挡且无法闪避。技能结束后消失。"
	animation = "shield_block_effect"
	counter_state = ""

# 这个状态不直接造成效果，而是影响命中类型判定
func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:
	print("ShieldBlockState.apply_effect %s 拥有盾格挡状态，必定格挡且无法闪避" % character.character_name)
	# 不再在这里移除状态，交给nature_decay处理
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": value,
		"state_effect": {"applied": true}
	}

# 在技能结束时清除状态
func nature_decay(battle: Battle, character: Character) -> Dictionary:
	print("ShieldBlockState.nature_decay %s 的盾格挡状态在技能结束时消失" % character.character_name)
	# 移除盾格挡状态
	StateManager.remove_state(character, state_name)
	return {
		"state_name": state_name,
		"animation": animation,
		"state_duration": 0,
		"state_effect": {"removed": true}
	}

# 不需要覆盖should_reduce_at方法，直接使用BaseState的实现 