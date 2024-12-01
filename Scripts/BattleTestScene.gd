extends Control

# 角色节点字典 {position: sprite_node}
var blue_team_nodes = {}
var red_team_nodes = {}
var battle: Battle  # 保存Battle实例的引用
var is_animation_playing: bool = false
var selected_character: Character = null
var hover_character: Character = null

var Console = preload("res://Scripts/Console.gd").new()

func _ready():
	# 初始化场景
	setup_battle_field()
	setup_ui()
	randomize()
	# 创建战斗实例
	battle = Battle.new()
	add_child(battle)  # 将battle添加为子节点
	connect_signals()
	
	# 开始战斗测试
	battle.init_battle("10001", "20001")
	# 设置技能动画系统
	SkillAnimation.setup_scene(self)
	
	# 使用计时器延迟开始战斗，确保场景完全准备好
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(func(): battle.process_battle())
	timer.start()
	

	
	# 连接暂停按钮信号
	$System/HBoxContainer/PauseButton.toggled.connect(_on_pause_button_toggled)
	
	# 设置角色交互
	setup_character_sprites()

func setup_battle_field():
	# 初始化战场位置
	for pos in Battle.Position.values():
		# 蓝队位置
		var blue_sprite = $Characters/Blue.get_node(pos_to_node_name(pos))
		blue_team_nodes[pos] = blue_sprite
		
		# 红队位置
		var red_sprite = $Characters/Red.get_node(pos_to_node_name(pos))
		red_team_nodes[pos] = red_sprite
		
		# 初始化为空位置贴图
		update_position_sprite(pos, null, true)  # 蓝队
		update_position_sprite(pos, null, false) # 红队

func setup_character_sprites():
	# 为所有角色精灵添加鼠标事件
	for team_nodes in [blue_team_nodes, red_team_nodes]:
		for sprite in team_nodes.values():
			# 添加Area2D组件用于检测鼠标事件
			var area = Area2D.new()
			var collision = CollisionShape2D.new()
			var shape = RectangleShape2D.new()
			shape.size = Vector2(128, 128)  # 根据实际精灵大小调整
			collision.shape = shape
			area.add_child(collision)
			sprite.add_child(area)
			
			# 设置碰撞层和掩码
			area.collision_layer = 1
			area.collision_mask = 1
			
			# 连接信号
			area.mouse_entered.connect(func(): _on_character_mouse_entered(sprite))
			area.mouse_exited.connect(func(): _on_character_mouse_exited(sprite))
			area.input_event.connect(func(_viewport, event, _shape_idx): _on_character_input_event(sprite, event))

func setup_ui():
	# 设置控制台
	Console.setup_console($Console/RichTextLabel)
	
	# 设置回合显示
	$System/HBoxContainer/TurnLabel.text = "回合: 0"
	
	# 初始隐藏角色信息面板
	$CharacterInfo.hide()

func connect_signals():
	# 连接Battle实例的信号
	battle.battle_start.connect(_on_battle_start)
	battle.battle_end.connect(_on_battle_end)
	battle.turn_start.connect(_on_turn_start)
	battle.turn_end.connect(_on_turn_end)
	battle.character_action_start.connect(_on_character_action_start)
	battle.character_action_end.connect(_on_character_action_end)

# 信号处理函数也需要相应修改，使用battle实例而不是Battle类
func _on_battle_start():
	Console.log("战斗开始")
	update_all_positions()

func _on_battle_end():
	Console.log("战斗结束")

func _on_turn_start():
	$System/HBoxContainer/TurnLabel.text = "回合: %d" % battle.turn_count
	Console.log("第 %d 回合开始" % battle.turn_count)

func _on_turn_end():
	Console.log("第 %d 回合结束" % battle.turn_count)

func _on_character_action_start(character: Character):
	Console.log("%s 开始行动" % character.character_name)
	is_animation_playing = true
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_character_action_end(character: Character):
	Console.log("%s 结束行动" % character.character_name)
	is_animation_playing = false

func _on_character_mouse_entered(sprite: Sprite2D):
	if is_animation_playing:
		return
	
	var character = find_character_by_sprite(sprite)
	if character:
		hover_character = character
		Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_character_mouse_exited(sprite: Sprite2D):
	if is_animation_playing:
		return
		
	hover_character = null
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_character_input_event(_sprite: Sprite2D, event: InputEvent):
	if is_animation_playing:
		return
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_character = hover_character
		update_character_info()

func update_character_info():
	if selected_character == null:
		$CharacterInfo.hide()
		return
		
	$CharacterInfo.show()
	$CharacterInfo/NameLabel.text = selected_character.character_name
	
	# 更新角色图像
	$CharacterInfo/Sprite2D.texture = load(selected_character.image_path)
	
	# 更新详细信息
	var info_text = """
	种族: {race}
	类型: {type}
	
	基础属性:
	力量: {str}  敏捷: {dex}
	体质: {con}  智力: {int}
	感知: {per}  魅力: {cha}
	
	战斗属性:
	物理攻击: {patk}  物理防御: {pdef}
	魔法攻击: {matk}  魔法防御: {mdef}
	命中率: {hit}     闪避率: {dodge}
	暴击率: {crit}
	
	资源值:
	生命: {hp}/{max_hp}
	魔法: {mp}/{max_mp}
	气: {qi}/{max_qi}
	行动点: {ap}/{ap_threshold}
	""".format({
		"race": selected_character.race,
		"type": selected_character.creature_type,
		"str": selected_character.base_attributes.strength,
		"dex": selected_character.base_attributes.dexterity,
		"con": selected_character.base_attributes.constitution,
		"int": selected_character.base_attributes.intelligence,
		"per": selected_character.base_attributes.perception,
		"cha": selected_character.base_attributes.charisma,
		"patk": selected_character.combat_stats.physical_attack,
		"pdef": selected_character.combat_stats.physical_defense,
		"matk": selected_character.combat_stats.magical_attack,
		"mdef": selected_character.combat_stats.magical_defense,
		"hit": selected_character.combat_stats.hit_rate,
		"dodge": selected_character.combat_stats.dodge_rate,
		"crit": selected_character.combat_stats.crit_rate,
		"hp": selected_character.resources.health.current,
		"max_hp": selected_character.resources.health.max,
		"mp": selected_character.resources.mana.current,
		"max_mp": selected_character.resources.mana.max,
		"qi": selected_character.resources.qi.current,
		"max_qi": selected_character.resources.qi.max,
		"ap": selected_character.battle_stats.action_point,
		"ap_threshold": selected_character.battle_stats.action_threshold
	})
	
	# 添加装备信息
	var equipment_text = "\n装备:\n"
	if selected_character.equipment.weapon:
		equipment_text += "武器: " + selected_character.equipment.weapon.get_item_name() + "\n"
	if selected_character.equipment.armor:
		equipment_text += "护甲: " + selected_character.equipment.armor.get_item_name() + "\n"
	if not selected_character.equipment.accessories.is_empty():
		equipment_text += "饰品: "
		for acc in selected_character.equipment.accessories:
			equipment_text += acc.get_item_name() + ", "
		equipment_text = equipment_text.trim_suffix(", ") + "\n"
	
	info_text += equipment_text
	
	$CharacterInfo/StatusRichTextLabel.text = info_text

func update_all_positions():
	for pos in Battle.Position.values():
		var blue_char = battle.blue_team[pos]
		var red_char = battle.red_team[pos]
		update_position_sprite(pos, blue_char, true)
		update_position_sprite(pos, red_char, false)

func update_position_sprite(pos: Battle.Position, character: Character, is_blue_team: bool):
	var sprite_node = blue_team_nodes[pos] if is_blue_team else red_team_nodes[pos]
	if character != null:
		sprite_node.texture = load(character.image_path)
		
		# 根据角色生死状态设置显示效果
		if character.is_dead():
			# 设置为低饱和度（0.3表示保留30%的饱和度）
			sprite_node.modulate = Color(0.7, 0.7, 0.7, 1.0)
		else:
			sprite_node.modulate = Color.WHITE
			
		# 设置状态条
		var status_bar = sprite_node.get_node("StatusBar")
		if status_bar:
			status_bar.setup_with_character(character)
			# 如果角色死亡，降低状态条的饱和度
			if character.is_dead():
				status_bar.modulate = Color(0.7, 0.7, 0.7, 1.0)
			else:
				status_bar.modulate = Color.WHITE
	else:
		sprite_node.texture = load("res://Assets/Character/empty_image.png")
		sprite_node.modulate = Color(1, 1, 1, 0.3)
		# 清空状态条
		var status_bar = sprite_node.get_node("StatusBar")
		if status_bar:
			status_bar.clear()

# 辅助函数
func pos_to_node_name(pos: Battle.Position) -> String:
	match pos:
		Battle.Position.FRONT_TOP: return "front_top"
		Battle.Position.FRONT_MID: return "front_mid"
		Battle.Position.FRONT_BOT: return "front_bot"
		Battle.Position.BACK_TOP: return "back_top"
		Battle.Position.BACK_MID: return "back_mid"
		Battle.Position.BACK_BOT: return "back_bot"
		_: return ""

func find_character_sprite(character: Character) -> Node:
	# 在两个队伍中查找角色对应的精灵节点
	for pos in Battle.Position.values():
		if battle.blue_team[pos] == character:
			return blue_team_nodes[pos]
		if battle.red_team[pos] == character:
			return red_team_nodes[pos]
	return null

func find_character_by_sprite(sprite: Node) -> Character:
	for pos in blue_team_nodes:
		if blue_team_nodes[pos] == sprite:
			return battle.blue_team[pos]
	for pos in red_team_nodes:
		if red_team_nodes[pos] == sprite:
			return battle.red_team[pos]
	return null

func _process(_delta):
	# 定期更新所有角色的状态显示
	update_all_positions()

# 添加暂停按钮处理函数
func _on_pause_button_toggled(button_pressed: bool) -> void:
	get_tree().paused = button_pressed
	var pause_button = $System/HBoxContainer/PauseButton
	pause_button.text = "继续" if button_pressed else "暂停"
