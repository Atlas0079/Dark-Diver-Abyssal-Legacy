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
		blue_team_status_bars[pos] = team_node.get_node("left_team/" + node_name + "/StatusBar")
	
	# 初始化红队UI面板引用
	for pos in Battle.Position.values():
		var node_name = pos_to_node_name(pos)
		red_team_status_bars[pos] = team_node.get_node("right_team/" + node_name + "/StatusBar")


# 开始战斗的主函数
func start_battle(blue_team_id: String, red_team_id: String):
	# 创建战斗实例
	battle = Battle.new()
	battle.battle_scene = self
	add_child(battle)
	
	# 初始化战斗
	battle.init_battle(blue_team_id, red_team_id)
	
	# 更新场景显示
	update_all_positions()
	
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
		sprite_node.texture = load("res://Assets/Character/empty_image.png")
		sprite_node.modulate = Color(1, 1, 1, 0.3)

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
		if battle.blue_team[pos] == character:
			return blue_team_nodes[pos]
		if battle.red_team[pos] == character:
			return red_team_nodes[pos]
	return null

func find_character_status_bar(character: Character) -> Control:
	for pos in Battle.Position.values():
		if battle.blue_team[pos] == character:
			return blue_team_status_bars[pos]
		if battle.red_team[pos] == character:
			return red_team_status_bars[pos]
	return null


# 根据角色和UI类型获取对应的UI组件
func find_character_ui(character: Character, ui_type: String):
	var status_bar = find_character_status_bar(character)
	if status_bar == null:
		return null
		
	match ui_type:
		"HP":
			return status_bar.get_node("HP")
		"MP":
			return status_bar.get_node("MP")
		"AP":
			return status_bar.get_node("AP")
		"QI":
			return status_bar.get_node("QI")
		"CharacterName":
			return status_bar.get_node("CharacterName")
		"StatusBar":
			return status_bar
		_:
			return null

func get_character_team(character: Character):
	for pos in Battle.Position.values():
		if battle.blue_team[pos] == character:
			return "blue"
		if battle.red_team[pos] == character:
			return "red"
	return null
