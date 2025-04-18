class_name Battle
extends Node

# 定义位置枚举
enum Position {
	FRONT_TOP,    # 前排上
	FRONT_MID,    # 前排中
	FRONT_BOT,    # 前排下
	BACK_TOP,     # 后排上
	BACK_MID,     # 后排中
	BACK_BOT      # 后排下
}

var battle_info: Array = []

var turn_count = 1

var battle_scene: BattleScene

var active_characters: Array = []


# 战场数据结构

static var blue_team = {
	Position.FRONT_TOP: null,  # null 表示空位置
	Position.FRONT_MID: null,
	Position.FRONT_BOT: null,
	Position.BACK_TOP: null,
	Position.BACK_MID: null,
	Position.BACK_BOT: null
}

static var red_team = {
	Position.FRONT_TOP: null,
	Position.FRONT_MID: null,
	Position.FRONT_BOT: null,
	Position.BACK_TOP: null,
	Position.BACK_MID: null,
	Position.BACK_BOT: null
}

# 添加管理器

func _init():
	pass

# 初始化战斗
func init_battle(blue_team_id: String, red_team_id: String) -> void:
	turn_count = 1

	# 从JSON加载队伍数据
	var blue_team_data = DataManager.get_team_data(blue_team_id)
	var red_team_data = DataManager.get_team_data(red_team_id)
	if blue_team_data == null or red_team_data == null:
		print("Battle.init_battle 队伍数据为空")
		return

	#StateManager.battle = self
	# 根据数据创建角色并放置到对应位置
	setup_team(blue_team_data, blue_team)
	setup_team(red_team_data, red_team)

# 从JSON加载队伍数据

# 设置队伍
func setup_team(team_data: Dictionary, team_positions: Dictionary) -> void:
	# 遍历队伍数据中的每个位置
	#print("Battle.setup_team team_data: %s" % team_data)
	for position in team_data.positions:
		var character_id = team_data.positions[position]
		if character_id != null:
			var character: Character
			# 根据ID前缀判断是NPC还是怪物（假设怪物ID以"1"开头）
			if str(character_id).begins_with("1"):
				# 创建怪物副本
				character = DataManager.create_monster_copy(character_id)
			else:
				# 获取NPC实例
				character = DataManager.get_character_instance(character_id)
				
			if character != null:
				# 将角色放入对应位置
				team_positions[Position[position]] = character

# 主战斗流程
func process_battle() -> void:
	print("战斗开始")
	handle_battle_start()
	
	while not battle_is_end():
		process_turn()
	
	handle_battle_end()

# 回合流程
func process_turn() -> void:
	

	# 1. 回合开始处理	
	print("Battle.handle_turn_start 第%d回合开始" % turn_count)
	active_characters.clear()

	# 状态时点：回合开始
	var state_events = StateManager.check_states_at_timing("turn_start", self)
	record_state_events(state_events)
	
	# 2. 更新行动点并收集可行动角色
	for team in [blue_team, red_team]:
		for pos in team:
			var character = team[pos]
			if character != null and character.is_alive():
				if not character.has_state("stun"):
					if character.has_state("slow"):
						character.battle_stats["action_point"] += 0.5
					else: 
						character.battle_stats["action_point"] += 1
				if character.battle_stats["action_point"] >= character.battle_stats["action_threshold"]:
					active_characters.append(character)

						
	
	# 3. 角色行动阶段
	while not active_characters.is_empty() and not battle_is_end():
		var character = active_characters[0]
		process_character_action(character)
		active_characters.erase(character)
	
	# 状态时点：回合结束
	state_events = StateManager.check_states_at_timing("turn_end", self)
	record_state_events(state_events)
	
	# 4. 回合结束处理
	turn_count += 1

# 角色行动流程
func process_character_action(character: Character) -> void:
	if battle_is_end():
		return
		
	print("Battle.handle_character_action_start %s 行动开始" % character.character_name)
	
	# 状态时点：行动开始
	var state_events = StateManager.check_states_at_timing("action_start", self, character)
	record_state_events(state_events)
	
	# 检查角色是否因状态效果而死亡
	if not character.is_alive():
		print("Battle.handle_character_action %s 因状态效果死亡，取消行动" % character.character_name)
		return
	
	# 1. 使用主动技能
	var skill = character.get_available_active_skill(self)

	if skill != null:
		character.battle_stats["action_point"] = 0
		execute_skill(character, skill)
	else:
		execute_skill(character, IdleSkill.new()) 
	
	print("Battle.handle_character_action_end %s 行动结束" % character.character_name)
	
	# 状态时点：行动结束
	state_events = StateManager.check_states_at_timing("action_end", self, character)
	record_state_events(state_events)

# 新增方法：记录状态事件
func record_state_events(state_events: Array) -> void:
	for event_data in state_events:
		var character = event_data.character
		var effect_result = event_data.effect_result
		var battle_event = create_state_resolve_event(character, effect_result)
		battle_info.append(battle_event)

func execute_skill(character: Character, skill: BaseSkill) -> Dictionary:
	var targets = skill.get_targets(character, self)
	

	
	if not targets.is_empty():
		#状态时点：技能发动前
	

		#处理Cover类技能改变目标
		var context = {
			"trigger_skill": skill,
			"trigger_character": character,
			"trigger_targets": targets,
			"trigger_result": {}
		}

		if skill.skill_type == "active": #只有主动技能才会触发被动技能。Cover类技能的特殊时点：技能选择目标时
			var new_targets = check_cover_skills(context) # 只调用一次保存到变量中
			if new_targets != null:
				targets = new_targets

		#被动时点：技能发动前
		if skill.skill_type == "active": #只有主动技能才会触发被动技能
			check_passive_skills("on_skill_before", context)

		character.battle_stats["action_point"] = 0
		var result_skill_info = skill.apply_effects(character, targets, self, context)
		
		# 记录技能事件
		battle_info.append(_create_active_skill_event(character, skill, targets, result_skill_info))
		

		#状态时点：技能发动后
		# 检查状态时点：skill_end，处理如cover_dodge_prohibit等需要在技能结束时清除的状态
		var state_events = StateManager.check_states_at_timing("skill_end", self, character)
		record_state_events(state_events)
		
		#被动时点：技能发动后
		if skill.skill_type == "active": #只有主动技能才会触发被动技能
			check_passive_skills("on_skill_used", context)

		return result_skill_info
	else:
		push_error("Battle.execute_skill 技能 %s 没有目标" % skill.skill_name)
		return {}

# 判断战斗是否结束
func battle_is_end() -> bool:
	var blue_alive = false
	var red_alive = false 
	
	# 检查蓝队是否还有存活角色
	for pos in blue_team:
		if blue_team[pos] != null and blue_team[pos].get_current_health() > 0:
			blue_alive = true
			break
	
	# 检查红队是否还有存活角色
	for pos in red_team:
		if red_team[pos] != null and red_team[pos].get_current_health() > 0:
			red_alive = true
			break
	
	# 如果任意一方全部阵亡，战斗结束
	return not (blue_alive and red_alive)

# 处理战斗开始
func handle_battle_start() -> void:
	print("Battle.handle_battle_start 战斗开始")
	#时点：战斗开始时
	check_passive_skills("on_battle_start")

# 处理战斗结束
func handle_battle_end() -> void:
	print("Battle.handle_battle_end 战斗结束")
	print_battle_info()

	battle_scene.process_battle_animation(battle_info)

	# TODO: 处理战斗结束





# 检查并触发被动技能
func check_passive_skills(trigger: String, context: Dictionary = {}):

	# 遍历所有存活角色
	for team in [blue_team, red_team]:
		for character in team.values():
			if character and character.is_alive():
				var skill_id = character.get_available_passive_skill(self, trigger)
				if skill_id:
					var skill = character.get_skill(skill_id)
					var targets: Array[Character]
					if skill.tags.has("need_context"):
						targets = skill.get_targets_with_context(character, self, context)
					else:
						targets = skill.get_targets(character, self) 

					if not targets.is_empty():
						# 使用技能并记录结果
						var skill_result = execute_skill(character, skill)
						battle_info.append(_create_passive_skill_event(character, skill, targets, skill_result))

# 检查Cover类技能，对应一个主动技能只能有一个角色发动Cover类技能
# 最后返回一个新的targets列表，这个列表会直接用于应对技能的的apply_effects
func check_cover_skills(context: Dictionary): 
	var cover_candidates = []
	
	# 遍历所有角色的所有passive_trigger为"on_targets_selected"的技能
	for team in [blue_team, red_team]:
		for pos in team:
			var character = team[pos]
			if character != null and character.is_alive():
				# 检查角色是否有掩护类技能
				for skill_id in character.battle_stats.active_skills:
					var skill = character.get_skill(skill_id)
					if skill != null and skill.skill_type == "passive" and skill.passive_trigger == "on_targets_selected":
						# 调用get_targets_with_context，如果不是空列表，把该技能对应的角色放进列表
						var potential_targets = skill.get_targets_with_context(character, self, context)
						if not potential_targets.is_empty():
							cover_candidates.append({
								"character": character,
								"skill": skill,
								"targets": potential_targets,
								"priority": skill.priority
							})
	
	# 根据规则排序列表（按优先级从高到低）
	if not cover_candidates.is_empty():
		cover_candidates.sort_custom(func(a, b): return a.priority > b.priority)
		
		# 选列表第一个角色发动
		var cover_data = cover_candidates[0]
		var cover_character = cover_data.character
		var cover_skill = cover_data.skill
		
		# 直接调用apply_cover_effects获取新的目标列表
		var cover_result_skill_info = cover_skill.apply_effects(cover_character, context["trigger_targets"], self, context)
		battle_info.append(_create_passive_skill_event(cover_character, cover_skill, cover_result_skill_info.effects[0].new_targets, cover_result_skill_info))
		print("Battle.check_cover_skills %s 发动Cover技能 %s ，原目标：%s，新目标：%s" % [cover_character.character_name, cover_skill.skill_name, context["trigger_targets"], cover_result_skill_info.effects[0].new_targets])
		
		return cover_result_skill_info.effects[0].new_targets
	
	# 如果没有掩护技能触发，返回原始目标列表
	return context["trigger_targets"]



# 创建主动技能事件
func _create_active_skill_event(user: Character, skill: BaseSkill, targets: Array, skill_result: Dictionary) -> BattleEvent:
	var event = BattleEvent.new()
	event.event_type = BattleEvent.EventType.ACTIVE_SKILL
	event.turn_number = turn_count
	event.source = user
	event.targets = targets
	event.skill_info = {
		"skill_name": skill.skill_name,
		"skill_type": skill.skill_type,
		"animation": skill.animation,
		"effects": skill_result.effects,
	}
	
	return event


# 创建被动技能事件
func _create_passive_skill_event(user: Character, skill: BaseSkill, targets: Array[Character], skill_result: Dictionary) -> BattleEvent:
	var event = BattleEvent.new()
	event.event_type = BattleEvent.EventType.PASSIVE_SKILL
	event.turn_number = turn_count
	event.source = user
	event.targets = targets
	
	# 基本信息
	event.skill_info = {
		"skill_name": skill.skill_name,
		"skill_type": skill.skill_type,
		"animation": skill.animation,
		"effects": skill_result.effects,
		"trigger": skill.passive_trigger,
	}
	
	# 合并skill_result中的其他字段
	for key in skill_result:
		if key != "effects" and not event.skill_info.has(key):
			event.skill_info[key] = skill_result[key]
	
	return event

func create_state_resolve_event(user: Character,state_result: Dictionary) -> BattleEvent:
	var event = BattleEvent.new()
	event.event_type = BattleEvent.EventType.STATE_RESOLVE
	event.turn_number = turn_count
	event.source = user
	event.targets = [user]
	event.state_info = {
		"state_name": state_result.state_name,
		"animation": state_result.animation,
		"state_duration": state_result.state_duration,
		"state_effect": state_result.state_effect
	}
	return event

func _ready():
	# 使用当前时间作为随机数种子
	randomize()
	# ... 其他初始化代码 ...

func print_battle_info() -> void:
	print("Battle.print_battle_info 战斗信息:")
	
	if battle_info.is_empty():
		print("  没有记录任何战斗事件")
		return
	
	print("  总计记录了 %d 个战斗事件" % battle_info.size())
	print("  ===================================")
	
	for event_idx in range(battle_info.size()):
		print("事件 #%d:" % (event_idx + 1))
		battle_info[event_idx].print_event_info()
		print("  -----------------------------------")

# 检查两个角色是否属于同一队伍
func are_characters_in_same_team(character1: Character, character2: Character) -> bool:
	var team1 = get_character_team(character1)
	var team2 = get_character_team(character2)
	
	return team1 == team2 and team1 != ""

# 获取角色所属的队伍（"blue", "red" 或空字符串如果没找到）
func get_character_team(character: Character) -> String:
	# 检查蓝队
	for pos in blue_team:
		if blue_team[pos] == character:
			return "blue"
	
	# 检查红队
	for pos in red_team:
		if red_team[pos] == character:
			return "red"
	
	# 如果没有找到角色
	push_error("Battle.get_character_team 没有找到角色 %s" % character.character_name)
	return ""
