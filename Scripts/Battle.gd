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

var turn_count = 1

# 每个回合需要的时间 秒钟
var battle_speed = 0.2

var active_characters: Array = []

signal turn_start
signal turn_end

signal character_action_start(character: Character)
signal character_action_end(character: Character)

signal battle_start
signal battle_end

signal animation_completed
signal action_completed

signal skill_and_targets_selected(skill: BaseSkill, targets: Array)

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

var is_animating: bool = false

# 初始化战斗
func init_battle(blue_team_id: String, red_team_id: String) -> void:
	turn_count = 1

	# 从JSON加载队伍数据
	var blue_team_data = DataManager.get_team_data(blue_team_id)
	var red_team_data = DataManager.get_team_data(red_team_id)
	if blue_team_data == null or red_team_data == null:
		print("Battle.init_battle 队伍数据为空")
		return
	
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


func process_battle() -> void:
	print("Battle.process_battle 战斗开始")
	handle_battle_start()
	# 启动回合处理
	start_next_turn()

func start_next_turn() -> void:
	if battle_is_end():
		handle_battle_end()
		return
		
	handle_turn_start()
	process_next_action()

func process_next_action() -> void:
	if active_characters.is_empty():
		# 所有角色行动完毕，结束回合
		handle_turn_end()
		# 创建计时器等待下一回合
		var timer = get_tree().create_timer(battle_speed)
		timer.timeout.connect(start_next_turn)
		return
		
	var character = active_characters[0]
	process_character_action(character)

# 修改角色行动处理
func process_character_action(character: Character) -> void: 
	handle_character_action_start(character)

	var available_skill_id = character.get_available_skill(self)
	if available_skill_id != null:
		var skill = character.get_skill(available_skill_id)
		var targets = skill.get_targets(character,self)
		#选择目标的时点
		emit_signal("skill_and_targets_selected", skill, targets)
		
		# 设置动画状态
		is_animating = true

		# 使用技能并获取效果结果
		var effects_results = character.use_skill(skill,targets,self) 
		
		# 播放技能动画
		SkillAnimation.play_skill_animation(skill, character, effects_results)
		# 等待动画完成信号
		await animation_completed
		
		# 动画完成，恢复状态
		is_animating = false
		character.battle_stats.action_point = 0
	else:
		print("Battle.process_character_action %s 没有可用技能，空过回合" % character.character_name)
		character.battle_stats.action_point = character.battle_stats.action_threshold

	handle_character_action_end(character)
	# 处理下一个角色的行动
	process_next_action()

# 修改回合开始处理，简化逻辑
func handle_turn_start() -> void:
	print("Battle.handle_turn_start 第%d回合开始" % turn_count)
	emit_signal("turn_start")
	
	active_characters.clear()  # 清空上回合可能残留的行动角色
	
	# 1. 所有存活角色增加行动点
	for team in [blue_team, red_team]:
		for pos in team:
			var character = team[pos]
			if character != null and character.is_alive():
				character.battle_stats.action_point += 1
				# 2. 检查是否达到行动阈值且有可用技能
				if character.battle_stats.action_point >= character.battle_stats.action_threshold:
					var available_skill_id = character.get_available_skill(self)
					if available_skill_id != null:
						active_characters.append(character)
	
	# 3. 可选：按照某种规则排序行动角色（比如速度）
	# active_characters.sort_custom(func(a, b): return a.get_speed() > b.get_speed())

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

# 处理战斗结束
func handle_battle_end() -> void:
	print("Battle.handle_battle_end 战斗结束")
	emit_signal("battle_end")

	# 重置所有角色状态（而不是删除实例）
	for team in [blue_team, red_team]:
		for pos in team:
			var character = team[pos]
			if character != null:
				character.reset_battle_state()
				team[pos] = null

	# TODO: 处理战斗结束

# 处理回合开始
func handle_turn_end() -> void:
	print("Battle.handle_turn_end 第%d回合结束" % turn_count)
	emit_signal("turn_end")  # 发出回合结束信号


	#TODO: 处理"回合结束"状态

	#回合结束增加回合数
	turn_count += 1

# 处理角色行动
func handle_character_action_start(character: Character) -> void:
	print("Battle.handle_character_action_start %s 行动开始" % character.character_name)
	emit_signal("character_action_start", character)

	#TODO: 处理"角色行动开始"状态


func handle_character_action_end(character: Character) -> void:
	print("Battle.handle_character_action_end %s 行动结束" % character.character_name)
	emit_signal("character_action_end", character)

	#TODO: 处理"角色行动结束"状态

	# 从可行动角色列表中移除
	active_characters.erase(character)
	
	# 检查是否需要结束回合
	if active_characters.is_empty():
		handle_turn_end()

func _ready():
	# 使用当前时间作为随机数种子
	randomize()
	# ... 其他初始化代码 ...
