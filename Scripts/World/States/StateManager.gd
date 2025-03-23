extends Node
# 状态注册表 - 用于创建状态的实例
var state_registry = {
	"burn": preload("res://Scripts/World/States/BurnState.gd"),
	"poison": preload("res://Scripts/World/States/PoisonState.gd"),
	#"cold": preload("res://Scripts/World/States/ColdState.gd"),
	#"stun": preload("res://Scripts/World/States/StunState.gd"),
	#"slow": preload("res://Scripts/World/States/SlowState.gd"), 
	"heal": preload("res://Scripts/World/States/HealState.gd"),  
	#"blind": preload("res://Scripts/World/States/BlindState.gd") #实现了
	"cover_dodge_prohibit": preload("res://Scripts/World/States/CoverDodgeProhibitState.gd"),
	"physical_attack_up": preload("res://Scripts/World/States/PhysicalAttackUpState.gd"),
	"magical_attack_up": preload("res://Scripts/World/States/MagicalAttackUpState.gd")
}

# 状态实例缓存 - 每种状态只创建一次实例
var state_instances = {}

func _ready():
	# 在初始化时创建所有状态的实例
	for state_name in state_registry:
		var state_class = state_registry[state_name]
		state_instances[state_name] = state_class.new()

# 获取状态实例
func get_state(state_name: String) -> BaseState:
	if state_instances.has(state_name):
		return state_instances[state_name]
	return null

# 检查角色是否拥有指定状态
func has_state(character: Character, state_name: String) -> bool:
	for state in character.states:
		if state.has(state_name):
			return true
	return false

# 获取角色状态值
func get_state_value(character: Character, state_name: String) -> int:
	for state in character.states:
		if state.has(state_name):
			return state[state_name]
	return 0

# 添加状态到角色
func add_state(character: Character, state_name: String, value: int = 1) -> void:
	# 检查是否已存在该状态
	for state in character.states:
		if state.has(state_name):
			state[state_name] += value
			check_counter_states(character)
			return
	
	# 不存在则添加新状态
	character.states.append({state_name: value})
	check_counter_states(character)

# 移除角色指定状态
func remove_state(character: Character, state_name: String) -> void:
	for i in range(character.states.size()):
		var state = character.states[i]
		if state.has(state_name):
			character.states.remove_at(i)

# 移除角色指定状态（指定层数）
func remove_state_by_value(character: Character, state_name: String, value: int) -> void:
	for i in range(character.states.size()):
		var state = character.states[i]
		if state.has(state_name):
			state[state_name] -= value
			if state[state_name] <= 0:
				character.states.remove_at(i)
			break

# 获取角色所有状态名称
func get_all_state_names(character: Character) -> Array:
	var state_names = []
	for state in character.states:
		for state_name in state:
			state_names.append(state_name)
	return state_names

# 应用状态对角色属性的影响
func apply_state_effects_to_attribute(character: Character, attr_name: String, base_value: int) -> int:
	# 应用状态修饰
	if attr_name == "dodge_rate" and has_state(character, "cold"):
		base_value -= get_state_value(character, "cold")
	if attr_name == "dodge_rate" and has_state(character, "slow"):
		base_value -= get_state_value(character, "slow")
	if attr_name == "dodge_rate" and has_state(character, "stun"):
		base_value = 0  # 眩晕时闪避为0
		
	# 确保属性不会为负
	return max(0, base_value)

# 应用状态对战斗属性的影响
func apply_state_effects_to_battle_stat(character: Character, stat_name: String, base_value: int) -> int:
	# 应用状态修饰
	if stat_name == "action_threshold" and has_state(character, "cold"):
		base_value += get_state_value(character, "cold")
		
	return base_value

# 检查时机并触发状态效果，返回需要记录的状态效果信息
# character参数为空时检查所有角色，否则只检查指定角色
func check_states_at_timing(timing: String, battle: Battle, character: Character = null) -> Array:
	var state_events = []
	
	# 如果提供了特定角色，只检查该角色
	if character != null:
		if character.is_alive():
			state_events = _check_character_states_at_timing(character, timing, battle)
	else:
		# 否则检查所有角色（原有行为）
		for team in [battle.blue_team, battle.red_team]:
			for char in team.values():
				if char and char.is_alive():
					var char_events = _check_character_states_at_timing(char, timing, battle)
					state_events.append_array(char_events)
	
	return state_events

# 辅助函数：检查单个角色的状态
func _check_character_states_at_timing(character: Character, timing: String, battle: Battle) -> Array:
	var state_events = []
	var states_to_apply = []
	var states_to_remove = []
	
	# 检查该角色的所有状态
	for i in range(character.states.size()):
		var state_dict = character.states[i]
		for state_name in state_dict:
			var state = get_state(state_name)
			if state:
				var state_value = state_dict[state_name]
				
				# 检查是否该触发状态效果
				if state.should_trigger_at(timing):
					states_to_apply.append({"state": state, "value": state_value})
				
				# 检查是否该清除状态
				if state.should_reduce_at(timing):
					var decay_result = state.nature_decay(battle, character)
					if not decay_result.is_empty():
						state_events.append({"character": character, "effect_result": decay_result})
	
	# 从后往前移除已结束的状态 
	for i in range(states_to_remove.size() - 1, -1, -1):
		if states_to_remove[i] < character.states.size():
			character.states.remove_at(states_to_remove[i])
	
	# 应用状态效果
	for state_data in states_to_apply:
		var state = state_data.state
		var value = state_data.value
		var effect_result = state.apply_effect(battle, character, value)
		if not effect_result.is_empty():
			state_events.append({"character": character, "effect_result": effect_result})

	return state_events
	
# 检查状态抵消
func check_counter_states(character: Character) -> void:
	var states_to_process = character.states.duplicate()
	var states_to_update = {}
	
	# 检查所有状态
	for state_dict in states_to_process:
		for state_name in state_dict:
			var state = get_state(state_name)
			if state:
				var state_value = state_dict[state_name]
				
				if state.counter_state != "":
					var counter_value = get_state_value(character, state.counter_state)
					if counter_value > 0:
						# 计算抵消的层数
						var cancel_amount = min(state_value, counter_value)
						
						# 更新状态和反制状态的值
						if not states_to_update.has(state_name):
							states_to_update[state_name] = state_value - cancel_amount
						else:
							states_to_update[state_name] -= cancel_amount
							
						if not states_to_update.has(state.counter_state):
							states_to_update[state.counter_state] = counter_value - cancel_amount
						else:
							states_to_update[state.counter_state] -= cancel_amount
	
	# 更新角色的状态
	var new_states = []
	for state_name in states_to_update:
		if states_to_update[state_name] > 0:
			new_states.append({state_name: states_to_update[state_name]})
			
	if not new_states.is_empty():
		character.states = new_states
