# Scripts/HD2DBattleScene.gd
extends Node3D

var battle: Battle
var blue_team_nodes = {}
var red_team_nodes = {}
var is_animation_playing: bool = false

func _ready():
	# 初始化节点引用
	init_team_nodes()
	# 初始化动画系统

	start_battle("10001", "20001")

# 初始化队伍节点引用
func init_team_nodes():
	# 修改节点路径以匹配实际场景结构
	for pos in Battle.Position.values():
		var node_name = pos_to_node_name(pos)
		blue_team_nodes[pos] = $left_team.get_node(node_name)  # 改为 left_team
		red_team_nodes[pos] = $right_team.get_node(node_name)  # 改为 right_team

# 开始战斗的主函数
func start_battle(blue_team_id: String, red_team_id: String):
	# 创建战斗实例
	battle = Battle.new()
	add_child(battle)
	
	# 初始化动画系统 - 移到这里
	SkillAnimation.setup_scene(self)
	
	# 连接信号
	battle.turn_start.connect(_on_turn_start)
	battle.turn_end.connect(_on_turn_end)
	battle.character_action_start.connect(_on_character_action_start)
	battle.character_action_end.connect(_on_character_action_end)
	battle.battle_end.connect(_on_battle_end)
	
	# 初始化战斗
	battle.init_battle(blue_team_id, red_team_id)
	
	# 更新场景显示
	update_all_positions()
	update_all_ui()
	
	# 开始战斗流程
	battle.process_battle()

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

# 信号处理函数
func _on_turn_start():
	update_all_positions()
	update_all_ui()

func _on_turn_end():
	update_all_positions()
	update_all_ui()

func _on_character_action_start(character: Character):
	pass

func _on_character_action_end(character: Character):
	update_all_positions()
	update_all_ui()

func _on_battle_end():
	print("战斗结束")

# 添加一个用于查找角色精灵的辅助函数
func find_character_sprite(character: Character) -> Sprite3D:
	for pos in Battle.Position.values():
		if battle.blue_team[pos] == character:
			return blue_team_nodes[pos]
		if battle.red_team[pos] == character:
			return red_team_nodes[pos]
	return null

#test 更新ui
# Scripts/BattleScene.gd

# 更新单个角色的UI显示
func update_character_ui(character: Character, panel: Panel):
	if not character:
		panel.visible = false
		return
		
	panel.visible = true
	
	# 更新头像
	var avatar = panel.get_node("Avatar/Avatar")
	if character.image_path:
		avatar.texture = load(character.image_path)
		# 设置头像大小为48x48
		avatar.scale = Vector2(0.375, 0.375)  # 因为原始大小是128x128，所以用0.375缩放到48x48
		avatar.position = Vector2(24, 24)  # 保持在中心位置
	
	# 更新名字
	var name_label = panel.get_node("StatusBar/CharacterName")
	name_label.text = character.character_name
	
	# 更新状态条
	var hp_bar = panel.get_node("StatusBar/HP")
	hp_bar.max_value = character.resources.health.max
	hp_bar.value = character.resources.health.current
	
	var mp_bar = panel.get_node("StatusBar/MP")
	mp_bar.max_value = character.resources.mana.max
	mp_bar.value = character.resources.mana.current
	
	var ap_bar = panel.get_node("StatusBar/AP")
	ap_bar.max_value = character.battle_stats.action_threshold
	ap_bar.value = character.battle_stats.action_point
	
	var qi_bar = panel.get_node("StatusBar/QI")
	qi_bar.max_value = character.resources.qi.max
	qi_bar.value = character.resources.qi.current


# 更新所有角色的UI
func update_all_ui():
	var canvas_layer = $CanvasLayer
	var team_node = canvas_layer.get_node("Team")
	
	# 更新蓝队UI
	for pos in Battle.Position.values():
		var character = battle.blue_team[pos]
		var panel = team_node.get_node("left_team/" + pos_to_node_name(pos))
		update_character_ui(character, panel)
	
	# 更新红队UI
	for pos in Battle.Position.values():
		var character = battle.red_team[pos]
		var panel = team_node.get_node("right_team/" + pos_to_node_name(pos))
		update_character_ui(character, panel)
