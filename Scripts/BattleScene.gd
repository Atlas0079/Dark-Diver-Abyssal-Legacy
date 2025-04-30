# Scripts/HD2DBattleScene.gd
extends Node3D

class_name BattleScene

var battle: Battle
var blue_team_nodes = {}
var red_team_nodes = {}
var is_animation_playing: bool = false
# UI相关实例变量
var canvas_layer
var team_node
var blue_team_status_bars = {}
var red_team_status_bars = {}
var animation_manager

func _ready():
	# 初始化节点引用
	init_team_nodes()
	# 初始化UI节点引用
	init_ui_nodes()
	# 初始化动画系统
	init_animation_system()

	start_battle("10001", "20001")

# 初始化队伍节点引用
func init_team_nodes():
	# 修改节点路径以匹配实际场景结构
	for pos in Battle.Position.values():
		var node_name = pos_to_node_name(pos)
		blue_team_nodes[pos] = $left_team.get_node(node_name)  # 改为 left_team
		red_team_nodes[pos] = $right_team.get_node(node_name)  # 改为 right_team

func init_animation_system():
	animation_manager = BattleAnimationManager.new(self)
	add_child(animation_manager)


# 初始化UI节点引用
func init_ui_nodes():
	canvas_layer = $CanvasLayer
	team_node = canvas_layer.get_node("Team")
	
	# 初始化蓝队UI面板引用
	for pos in Battle.Position.values():
		var node_name = pos_to_node_name(pos)
		var status_bar_node = team_node.get_node_or_null("left_team/" + node_name + "/StatusBar")
		if status_bar_node:
			blue_team_status_bars[pos] = status_bar_node
		else:
			push_error("未能找到蓝队UI节点: left_team/%s/StatusBar" % node_name)

	# 初始化红队UI面板引用
	for pos in Battle.Position.values():
		var node_name = pos_to_node_name(pos)
		var status_bar_node = team_node.get_node_or_null("right_team/" + node_name + "/StatusBar")
		if status_bar_node:
			red_team_status_bars[pos] = status_bar_node
		else:
			push_error("未能找到红队UI节点: right_team/%s/StatusBar" % node_name)


# 开始战斗的主函数
func start_battle(blue_team_id: String, red_team_id: String):
	# 创建战斗实例
	battle = Battle.new()
	battle.battle_scene = self
	add_child(battle)
	
	# 初始化战斗
	battle.init_battle(blue_team_id, red_team_id)
	
	# 更新场景显示 (3D 精灵)
	update_all_positions()
	
	# 初始化UI显示
	init_all_character_ui()
	
	# 开始战斗流程
	battle.process_battle()

func process_battle_animation(battle_events: Array):
	var animation_queue = animation_manager.build_animation_queue(battle_events)
	animation_manager.play_animation_with_queue(animation_queue)

# 更新所有位置的显示
func update_all_positions():
	for pos in Battle.Position.values():
		update_position_sprite(pos, battle.blue_team[pos], true)
		update_position_sprite(pos, battle.red_team[pos], false)

# 更新单个位置的精灵显示
func update_position_sprite(pos: Battle.Position, character: Character, is_blue_team: bool):
	var sprite_node: Sprite3D = blue_team_nodes[pos] if is_blue_team else red_team_nodes[pos]
	if character != null:
		# 修改为3D精灵的属性设置方式
		sprite_node.texture = load(character.image_path)
		sprite_node.modulate = Color(0.7, 0.7, 0.7, 1.0) if character.is_dead() else Color.WHITE
		sprite_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED  # 确保始终面向摄像机
	else:
		sprite_node.texture = load("res://Assets/Character/empty_image.png") # 假设有一个空占位图
		sprite_node.modulate = Color(1, 1, 1, 0.3) # 半透明显示空位

# 新增：初始化所有角色的UI
func init_all_character_ui():
	for pos in Battle.Position.values():
		_init_single_character_ui(pos, true)  # 初始化蓝队UI
		_init_single_character_ui(pos, false) # 初始化红队UI

# 新增：初始化单个角色的UI
func _init_single_character_ui(pos: Battle.Position, is_blue_team: bool):
	var team_data = battle.blue_team if is_blue_team else battle.red_team
	var team_status_bars = blue_team_status_bars if is_blue_team else red_team_status_bars
	
	var character = team_data.get(pos)
	var status_bar = team_status_bars.get(pos)

	if status_bar == null:
		push_error("在 %s 队伍的位置 %s 找不到 StatusBar 引用！" % ["蓝队" if is_blue_team else "红队", pos])
		return

	if character != null:
		status_bar.visible = true
		
		# 更新角色名
		var name_label = status_bar.get_node_or_null("CharacterName") as Label
		if name_label:
			name_label.text = character.character_name
		else:
			push_error("StatusBar 中找不到 CharacterName Label")

		# 更新HP条
		var hp_bar = status_bar.get_node_or_null("HP") as TextureProgressBar
		if hp_bar:
			hp_bar.max_value = character.get_max_health() # 假设 Character 有此方法
			hp_bar.value = character.get_current_health() # 假设 Character 有此方法
		else:
			push_error("StatusBar 中找不到 HP TextureProgressBar")

		# 更新MP条 (假设存在)
		var mp_bar = status_bar.get_node_or_null("MP") as TextureProgressBar
		if mp_bar:
			# 你需要确保 Character 类有获取 MP 的方法
			# mp_bar.max_value = character.get_max_mana() # 假设 Character 有此方法
			# mp_bar.value = character.get_current_mana() # 假设 Character 有此方法
			# 临时处理，如果你的角色类还没有 MP
			mp_bar.max_value = character.battle_stats.get("max_mp", 100) # 示例
			mp_bar.value = character.battle_stats.get("current_mp", 50) # 示例
		else:
			push_warning("StatusBar 中找不到 MP TextureProgressBar (可能不需要?)")

		# 更新AP条
		var ap_bar = status_bar.get_node_or_null("AP") as TextureProgressBar
		if ap_bar:
			# AP 的 max_value 通常是固定的行动阈值
			ap_bar.max_value = character.battle_stats.get("action_threshold", 1.0)
			ap_bar.value = character.battle_stats.get("action_point", 0.0)
		else:
			push_error("StatusBar 中找不到 AP TextureProgressBar")
			
		# 更新QI条 (假设存在)
		var qi_bar = status_bar.get_node_or_null("QI") as TextureProgressBar
		if qi_bar:
			# 你需要确保 Character 类有获取 QI 的方法
			# qi_bar.max_value = character.get_max_qi() # 假设 Character 有此方法
			# qi_bar.value = character.get_current_qi() # 假设 Character 有此方法
			# 临时处理
			qi_bar.max_value = character.battle_stats.get("max_qi", 100) # 示例
			qi_bar.value = character.battle_stats.get("current_qi", 10) # 示例
		else:
			push_warning("StatusBar 中找不到 QI TextureProgressBar (可能不需要?)")

		# TODO: 更新头像 (如果需要动态加载)
		# var avatar_sprite = status_bar.get_node_or_null("../Avatar/Avatar") as Sprite2D # 路径可能需要调整
		# if avatar_sprite:
		# 	avatar_sprite.texture = load(character.avatar_path) # 假设 Character 有头像路径

	else:
		# 如果该位置没有角色，隐藏对应的UI面板
		status_bar.visible = false
		# 或者可以设置一个空状态的样式


# 辅助函数：位置枚举转节点名称
func pos_to_node_name(pos: Battle.Position) -> String:
	match pos:
		Battle.Position.FRONT_TOP: return "front_top"
		Battle.Position.FRONT_MID: return "front_mid"
		Battle.Position.FRONT_BOT: return "front_bot"
		Battle.Position.BACK_TOP: return "back_top"
		Battle.Position.BACK_MID: return "back_mid"
		Battle.Position.BACK_BOT: return "back_bot"
		_: return ""



# 添加一个用于查找角色精灵的辅助函数
func find_character_sprite(character: Character) -> Sprite3D:
	#print("BattleScene.find_character_sprite %s" % character.character_name)

	for pos in Battle.Position.values():
		if battle.blue_team.get(pos) == character: # 使用 get() 避免无效键错误
			return blue_team_nodes.get(pos)
		if battle.red_team.get(pos) == character:
			return red_team_nodes.get(pos)
	return null

func find_character_status_bar(character: Character) -> Control:
	for pos in Battle.Position.values():
		if battle.blue_team.get(pos) == character:
			return blue_team_status_bars.get(pos)
		if battle.red_team.get(pos) == character:
			return red_team_status_bars.get(pos)
	return null


# 根据角色和UI类型获取对应的UI组件
func find_character_ui(character: Character, ui_type: String):
	var status_bar = find_character_status_bar(character)
	if status_bar == null:
		print("BattleScene.find_character_ui 未找到角色 %s 的 status_bar" % character.character_name)
		return null
		
	var node = status_bar.get_node_or_null(ui_type) # 直接尝试按名字查找
	if node:
		return node
	else:
		# 为了兼容旧逻辑，但最好直接使用节点名
		match ui_type:
			"HP":
				return status_bar.get_node_or_null("HP")
			"MP":
				return status_bar.get_node_or_null("MP")
			"AP":
				return status_bar.get_node_or_null("AP")
			"QI":
				return status_bar.get_node_or_null("QI")
			"CharacterName":
				return status_bar.get_node_or_null("CharacterName")
			"StatusBar": # 这个分支其实没必要了，因为上面已经找到了 status_bar
				return status_bar 
			_:
				push_error("BattleScene.find_character_ui 未知的 UI 类型: %s" % ui_type)
				return null

func get_character_team(character: Character):
	for pos in Battle.Position.values():
		if battle.blue_team.get(pos) == character:
			return "blue"
		if battle.red_team.get(pos) == character:
			return "red"
	return null
