class_name NiNardUI
extends Control


# 场景引用
@onready var hand_container = $"../HandContainer"
@onready var board_container = $"../BoardContainer"
@onready var info_panel = $"../InfoPanel"
@onready var initial_choice_panel = $"../InitialCardChoice"
#@onready var end_game_panel = $"../EndGamePanel"
@onready var tutorial_button = $"../TutorialButton"  # 添加教程按钮引用
@onready var restart_button = $"../InfoPanel/Panel/RestartButton" # 添加重新开始按钮引用

@onready var game_logic = $".."

# 状态变量
var selected_card: NiNardCard = null
var selected_position: Vector2i = Vector2i(-1, -1)
var board_positions = []
var player1_hand_cards = []
var player2_hand_cards = []
var is_waiting_for_direction = false
var initial_cards = []
var is_waiting_for_initial_choice = false
var selected_initial_card = null

# 预加载教程场景
var tutorial_scene = preload("res://Scenes/NiNard/tutorial.tscn")
var current_tutorial = null  # 当前教程实例
var current_page = 1  # 当前教程页码
var total_pages = 6  # 教程总页数

# 预加载毛玻璃着色器
var glass_shader = preload("res://Scripts/Shader/glass_effect.gdshader")

# 常量
const CARD_WIDTH = 100
const CARD_HEIGHT = 150
const HAND_ARC_RADIUS = 400
const BOARD_CELL_SIZE = 120

func _ready():
	# 初始化棋盘位置
	initialize_board_positions()
	
	# 连接游戏逻辑信号
	connect_game_signals()
	
	# 设置信息面板
	update_info_panel()
	
	# 隐藏初始选择面板和结束面板
	initial_choice_panel.visible = false
	#end_game_panel.visible = false
	
	# 隐藏并连接重新开始按钮
	restart_button.visible = false
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	# 连接教程按钮信号
	tutorial_button.pressed.connect(_on_tutorial_button_pressed)

func initialize_board_positions():
	# 获取所有棋盘位置节点
	for y in range(3):
		for x in range(3):
			var position_node = board_container.get_node("BoardPositions/Position_" + str(x) + "_" + str(y))
			position_node.input_event.connect(
				func(_viewport, event, _shape_idx): 
					if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
						_on_board_position_clicked(Vector2i(x, y))
			)

func connect_game_signals():
	game_logic.turn_changed.connect(_on_turn_changed)
	game_logic.card_placed.connect(_on_card_placed)
	game_logic.card_captured.connect(_on_card_captured)
	game_logic.initial_cards_drawn.connect(_on_initial_cards_drawn)
	game_logic.initial_card_placed.connect(_on_initial_card_placed)
	game_logic.player_turn.connect(_on_player_turn)
	game_logic.scores_updated.connect(_on_scores_updated)
	game_logic.game_ended.connect(_on_game_ended)

# 更新信息面板
func update_info_panel():
	info_panel.get_node("TurnCount").text = "当前回合数：" + str(game_logic.turn_count)

	info_panel.get_node("Player1EScore").text = "你的当前得分：" + str(game_logic.player1_estimated_score)
	info_panel.get_node("Player2EScore").text = "对手当前得分：" + str(game_logic.player2_estimated_score)
	#info_panel.get_node("Player1Info/CardsLeftLabel").text = "你的剩余牌：" + str(game_logic.player1_hand.size())
	#info_panel.get_node("Player2Info/CardsLeftLabel").text = "对手的剩余牌：" + str(game_logic.player2_hand.size())


# 显示玩家手牌
func display_player_hand(player: String):
	# 清空当前手牌显示
	for child in hand_container.get_children():
		# 只将子节点从容器中移除，不销毁卡片实例本身
		hand_container.remove_child(child) # <--- 修改后的代码
	
	# 获取玩家手牌
	var hand = []
	if player == "player1":
		hand = game_logic.player1_hand
	else:
		hand = game_logic.player2_hand
	
	# 设置容器属性 - 翻倍间距以匹配卡片大小的增加
	hand_container.add_theme_constant_override("separation", 160)  # 从80调整为160
	
	# 显示手牌
	for card in hand:
		# 创建一个容器来包装卡片，以便控制大小和间距
		var card_wrapper = Control.new()
		card_wrapper.custom_minimum_size = Vector2(200, 300)  # 设置最小尺寸，从100,150翻倍为200,300
		hand_container.add_child(card_wrapper)
		
		# 获取卡片实例
		if card.get_parent():
			card.get_parent().remove_child(card)
		card_wrapper.add_child(card)
		
		# 设置卡片属性
		card.card_owner = player
		card.set_selectable(true)
		card.is_on_board = false  # 确保手牌状态正确
		card.scale = Vector2(0.3, 0.3)  # 从0.15改为0.3
		
		# 将卡片居中显示在包装器中
		card.position = Vector2(100, 150)  # 居中位置从50,75调整为100,150
		
		# 连接信号
		if !card.is_connected("card_clicked", _on_hand_card_clicked):
			card.card_clicked.connect(_on_hand_card_clicked)
		if !card.is_connected("direction_selected", _on_card_direction_selected):
			card.direction_selected.connect(_on_card_direction_selected)
		if !card.is_connected("cancel_selected", _on_card_selection_cancelled):
			card.cancel_selected.connect(_on_card_selection_cancelled)
		
		# 更新视觉效果
		card.update_visuals()
		
		# 重要：在update_visuals之后设置所有者精灵不可见，因为update_visuals会设置它为可见
		card.card_owner_sprite.visible = false


# 显示初始卡牌选择
func display_initial_card_choice(player1_card: NiNardCard, player2_card: NiNardCard): 
	initial_choice_panel.visible = true
	is_waiting_for_initial_choice = true
	initial_cards = [player1_card, player2_card]
	selected_initial_card = null
	
	# 显示初始选择面板
	initial_choice_panel.visible = true
	
	# 获取卡牌容器和确认按钮
	var card1_container = initial_choice_panel.get_node("Panel/Card1Container")
	var card2_container = initial_choice_panel.get_node("Panel/Card2Container")
	var confirm_button = initial_choice_panel.get_node("Panel/Button")
	
	# 确保容器和按钮存在
	if !card1_container or !card2_container or !confirm_button:
		push_error("初始卡牌容器或确认按钮未找到")
		return
	
	# 清空容器中的现有卡片
	for child in card1_container.get_children():
		child.queue_free()
	for child in card2_container.get_children():
		child.queue_free()
	
	# 确保卡片从原来的父节点移除
	if player1_card.get_parent():
		player1_card.get_parent().remove_child(player1_card)
	if player2_card.get_parent():
		player2_card.get_parent().remove_child(player2_card)
	
	# 添加卡片到容器
	card1_container.add_child(player1_card)
	card2_container.add_child(player2_card)
	
	# 设置卡片属性
	player1_card.card_owner = "player1"
	player1_card.card_owner_sprite.visible = false
	player1_card.set_selectable(true)
	player1_card.scale = Vector2(0.4, 0.4)  # 从0.2改为0.4
	player1_card.position = Vector2(card1_container.size.x/2, card1_container.size.y/2)  # 居中显示
	player1_card.update_visuals()
	
	player2_card.card_owner = "player2"
	player2_card.card_owner_sprite.visible = false
	player2_card.set_selectable(true)
	player2_card.scale = Vector2(0.4, 0.4)  # 从0.2改为0.4
	player2_card.position = Vector2(card2_container.size.x/2, card2_container.size.y/2)  # 居中显示
	player2_card.update_visuals()
	
	# 断开之前的连接以避免重复连接
	if player1_card.is_connected("card_clicked", _on_initial_card_selected):
		player1_card.disconnect("card_clicked", _on_initial_card_selected)
	if player2_card.is_connected("card_clicked", _on_initial_card_selected):
		player2_card.disconnect("card_clicked", _on_initial_card_selected)
	
	# 重新连接信号
	player1_card.card_clicked.connect(_on_initial_card_selected)
	player2_card.card_clicked.connect(_on_initial_card_selected)
	
	# 添加调试输出
	#print("初始卡片设置完成，player1_card可选择状态:", player1_card.is_selectable)
	#print("初始卡片设置完成，player2_card可选择状态:", player2_card.is_selectable)
	
	# 连接确认按钮信号
	if confirm_button.is_connected("pressed", _on_initial_choice_confirmed):
		confirm_button.disconnect("pressed", _on_initial_choice_confirmed)
	confirm_button.pressed.connect(_on_initial_choice_confirmed)
	
	# 初始状态下禁用确认按钮
	confirm_button.disabled = true


# 处理棋盘格子点击
func _on_board_position_clicked(position: Vector2i):
	if selected_card != null and !is_waiting_for_direction:
		# 检查位置是否有效
		if game_logic.board[position.y][position.x] == null:
			selected_position = position
			is_waiting_for_direction = true
			
			# 将卡牌移动到选中位置
			var board_pos = get_board_position(position)
			selected_card.global_position = board_pos
			selected_card.scale = Vector2(0.2, 0.2)  # 从0.1改为0.2
			
			# 显示方向选择
			selected_card.show_direction_selection()
			
			# 连接方向选择和取消信号
			if !selected_card.is_connected("direction_selected", _on_card_direction_selected):
				selected_card.direction_selected.connect(_on_card_direction_selected)
			if !selected_card.is_connected("cancel_selected", _on_card_selection_cancelled):
				selected_card.cancel_selected.connect(_on_card_selection_cancelled)

# 获取棋盘位置的全局坐标
func get_board_position(grid_pos: Vector2i) -> Vector2:
	# 获取对应位置节点
	var position_node_path = "Position_" + str(grid_pos.x) + "_" + str(grid_pos.y)
	var position_node = board_container.get_node("BoardPositions").get_node_or_null(position_node_path)
	
	if position_node:
		# 如果找到了节点，返回其碰撞形状的全局位置
		var collision_shape = position_node.get_node_or_null("CollisionShape2D")
		if collision_shape:
			return collision_shape.global_position
		else:
			return position_node.global_position
	else:
		# 如果没有找到节点，使用计算的位置（作为备用）
		push_warning("找不到位置节点: " + position_node_path + "，使用计算位置")
		var base_pos = board_container.global_position
		var x = base_pos.x + grid_pos.x * BOARD_CELL_SIZE + BOARD_CELL_SIZE/2
		var y = base_pos.y + grid_pos.y * BOARD_CELL_SIZE + BOARD_CELL_SIZE/2
		return Vector2(x, y)

# 处理手牌点击
func _on_hand_card_clicked(card: NiNardCard, is_on_board: bool):
	# 如果卡牌在场上，则交给场上卡牌处理函数处理
	if is_on_board:
		_on_board_card_clicked(card)
		return
		
	if is_waiting_for_direction:
		return
		
	if selected_card != null:
		selected_card.modulate = Color(1, 1, 1, 1)  # 恢复之前选择的牌
	
	selected_card = card
	card.modulate = Color(1.2, 1.2, 1.2, 1.0)  # 高亮选中的牌，增加亮度而不是透明度
	
	# 高亮可放置的棋盘位置
	highlight_valid_positions()

# 新增：处理场上卡牌点击
func _on_board_card_clicked(card: NiNardCard):
	# 这里可以添加场上卡牌点击时的效果
	print("场上卡牌被点击: " + card.card_id + ", 花色: " + str(card.suit) + ", 数值: " + str(card.value))
	
	# 示例：显示卡牌信息
	info_panel.get_node("GameMessage").text = "卡牌: " + card.card_name + " - " + card.card_description
	
	# 可以在此处添加更多交互功能
	# 例如显示卡牌详情面板等

# 高亮可放置的棋盘位置
func highlight_valid_positions():
	for y in range(3):
		for x in range(3):
			pass


# 处理方向选择
func _on_card_direction_selected(card: NiNardCard, direction: int):
	is_waiting_for_direction = false
	
	print("UI收到方向选择信号: " + str(direction))
	
	# 尝试放置卡牌
	var success = game_logic.place_card(game_logic.current_player, card, selected_position, direction)
	
	if success:
		# 放置成功，清除选择状态
		selected_card = null
		selected_position = Vector2i(-1, -1)
		
		# 清除高亮
		for y in range(3):
			for x in range(3):
				#var highlight = board_container.get_node("HighlightLayer/Highlight_" + str(x) + "_" + str(y))
				#highlight.visible = false
				pass
	else:
		selected_card = null

# 处理取消选择
func _on_card_selection_cancelled(card: NiNardCard):
	is_waiting_for_direction = false
	
	# 隐藏方向选择UI
	card.hide_direction_selection()
	
	# 重置卡牌外观和状态
	card.modulate = Color(1, 1, 1, 1)
	card.is_on_board = false
	
	# 将卡牌从临时位置移除
	if card.get_parent():
		card.get_parent().remove_child(card)
	
	# 重新显示当前玩家的手牌，这将包含取消选择的卡牌
	display_player_hand(game_logic.current_player)
	
	# 清除选择状态
	selected_card = null
	selected_position = Vector2i(-1, -1)




# 处理初始卡牌选择
func _on_initial_card_selected(card: NiNardCard, is_on_board: bool):
	if !is_waiting_for_initial_choice:
		return
	
	# 获取卡牌容器和确认按钮
	var card1_container = initial_choice_panel.get_node("Panel/Card1Container")
	var card2_container = initial_choice_panel.get_node("Panel/Card2Container")
	var confirm_button = initial_choice_panel.get_node("Panel/Button")
	
	# 重置所有卡牌外观
	for container in [card1_container, card2_container]:
		if container and container.get_child_count() > 0:
			container.get_child(0).modulate = Color(1, 1, 1, 1)
	
	# 设置选中的卡牌
	selected_initial_card = card
	card.modulate = Color(1.2, 1.2, 1.2, 1.0)  # 高亮选中的牌，增加亮度而不是透明度
	
	# 启用确认按钮
	confirm_button.disabled = false
	
	# 更新选择提示
	if card.card_owner == "player1":
		info_panel.get_node("GameMessage").text = "已选择玩家1的卡牌，点击确认按钮继续"
	else:
		info_panel.get_node("GameMessage").text = "已选择玩家2的卡牌，点击确认按钮继续"

# 处理确认按钮点击
func _on_initial_choice_confirmed():
	if !is_waiting_for_initial_choice or selected_initial_card == null:
		return
	
	is_waiting_for_initial_choice = false
	
	# 重置所有卡牌的高亮状态
	for card in initial_cards:
		card.modulate = Color(1, 1, 1, 1)
	
	# 确定哪张是顶部卡牌，哪张是底部卡牌
	var top_card
	var bottom_card
	
	if selected_initial_card.card_owner == "player1":
		top_card = initial_cards[0]
		bottom_card = initial_cards[1]
	else:
		top_card = initial_cards[1]
		bottom_card = initial_cards[0]
	
	# 通知游戏逻辑
	game_logic.place_initial_card(top_card, bottom_card)
	
	# 隐藏初始选择面板
	initial_choice_panel.visible = false
	

	# 重置选中状态
	selected_initial_card = null

# 游戏逻辑信号处理
func _on_turn_changed(player: String):
	update_info_panel()
	display_player_hand(player)
	
	if player == "player1":
		info_panel.get_node("GameMessage").text = "轮到玩家1"
	else:
		info_panel.get_node("GameMessage").text = "轮到玩家2"

func _on_card_placed(player: String, card: NiNardCard, position: Vector2i, orientation: int):
	# 使用原始卡片实例而不是创建新实例
	if card.get_parent():
		card.get_parent().remove_child(card)
	board_container.get_node("CardsLayer").add_child(card)
	
	# 设置位置
	card.global_position = get_board_position(position)
	card.scale = Vector2(0.2, 0.2)  # 从0.1改为0.2
	
	# 确保卡牌可点击但标记为场上卡牌
	card.set_selectable(true)
	card.is_on_board = true
	
	#根据朝向旋转
	if orientation == 0:
		card.rotation = 0
	elif orientation == 1:
		card.rotation = PI/2
	elif orientation == 2:
		card.rotation = PI
	elif orientation == 3:
		card.rotation = 3*PI/2

	# 确保得分标签可见且更新
	card.update_visuals()

	# 更新信息面板
	update_info_panel()

func _on_card_captured(player: String, card: NiNardCard):
	# 直接使用传入的卡片实例
	card.card_owner_sprite.visible = true
	card.update_visuals()

func _on_initial_cards_drawn(player1_card: NiNardCard, player2_card: NiNardCard, first_player: String):
	info_panel.get_node("GameMessage").text = "游戏开始！" + first_player + " 先手"
	
	# 检查先手玩家是否为人类玩家
	if first_player == "player1":
		# 人类玩家，显示选择界面
		display_initial_card_choice(player1_card, player2_card)
	else:
		# AI玩家，直接让AI选择
		info_panel.get_node("GameMessage").text = "游戏开始！AI先手并选择了初始卡牌"
		
		# 延迟一小段时间，让玩家看到消息
		await get_tree().create_timer(1.0).timeout
		
		# 调用游戏逻辑中的AI选择函数
		game_logic.ai_select_initial_card(player1_card, player2_card)

func _on_initial_card_placed(top_card: NiNardCard, bottom_card: NiNardCard):
	# 直接使用传入的卡片实例
	if top_card.get_parent():
		top_card.get_parent().remove_child(top_card)
	board_container.get_node("CardsLayer").add_child(top_card)
	
	# 设置位置
	top_card.scale = Vector2(0.2, 0.2)  # 从0.1改为0.2
	top_card.global_position = get_board_position(Vector2i(1, 1))
	top_card.update_visuals()
	top_card.z_index = 1
	
	# 确保卡牌可点击但标记为场上卡牌
	top_card.set_selectable(true)
	top_card.is_on_board = true
	# 重置高亮状态
	top_card.modulate = Color(1, 1, 1, 1)

	if bottom_card.get_parent():
		bottom_card.get_parent().remove_child(bottom_card)
	board_container.get_node("CardsLayer").add_child(bottom_card)
	
	# 设置位置
	bottom_card.scale = Vector2(0.2, 0.2)  # 从0.1改为0.2
	bottom_card.rotation = PI/2
	bottom_card.global_position = get_board_position(Vector2i(1, 1))
	
	# 确保卡牌可点击但标记为场上卡牌
	bottom_card.set_selectable(true)
	bottom_card.is_on_board = true
	bottom_card.update_visuals()
	# 重置高亮状态
	bottom_card.modulate = Color(1, 1, 1, 1)

	display_player_hand(game_logic.current_player)

func _on_player_turn():
	pass

# 新增：处理分数更新
func _on_scores_updated(player1_score: int, player2_score: int):
	# 更新信息面板中的预估分数
	info_panel.get_node("Player1EScore").text = "你的当前得分：" + str(player1_score)
	info_panel.get_node("Player2EScore").text = "对手当前得分：" + str(player2_score)
	
	# 更新所有场上卡牌的得分显示
	for y in range(3):
		for x in range(3):
			var card = game_logic.board[y][x]
			if card != null:
				card.update_visuals()  # 确保卡牌显示更新后的得分

func _on_game_ended(winner: String, player1_score: int, player2_score: int):
	# 构造结束信息
	var end_message = "游戏结束！\n"
	if winner == "draw":
		end_message += "平局！"
	elif winner == "player1":
		end_message += "你赢了！"
	else:
		end_message += "对手赢了！"
	
	end_message += "\n最终得分:\n你的得分: %d\n对手得分: %d" % [player1_score, player2_score]
	
	# 更新信息面板
	info_panel.get_node("GameMessage").text = end_message
	info_panel.get_node("Player1EScore").text = "你的最终得分: " + str(player1_score)
	info_panel.get_node("Player2EScore").text = "对手最终得分: " + str(player2_score)
	
	# 显示重新开始按钮
	restart_button.visible = true
	
	# 可以在这里禁用其他交互，例如手牌点击
	for child in hand_container.get_children():
		if child is Control and child.get_child_count() > 0:
			var card = child.get_child(0)
			if card is NiNardCard:
				card.set_selectable(false)
	pass

# 教程相关函数
func _on_tutorial_button_pressed():
	# 打开教程
	open_tutorial()

func open_tutorial():
	# 如果教程已经打开，则不再重复打开
	if current_tutorial:
		return
	
	# 实例化教程场景
	current_tutorial = tutorial_scene.instantiate()
	get_tree().root.add_child(current_tutorial)
	
	# 设置鼠标过滤模式为STOP，确保阻挡鼠标事件
	current_tutorial.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# 设置z_index为100，确保教程显示在所有游戏元素之上
	current_tutorial.z_index = 100
	
	# 添加毛玻璃效果
	apply_glass_effect(current_tutorial)
	
	# 重置当前页为第一页
	current_page = 1
	total_pages = current_tutorial.get_node("Page").get_child_count()
	
	# 更新页面显示
	update_tutorial_page()
	
	# 连接按钮信号
	current_tutorial.get_node("NextButton").pressed.connect(_on_tutorial_next_button_pressed)
	current_tutorial.get_node("PreviousButton").pressed.connect(_on_tutorial_previous_button_pressed)
	current_tutorial.get_node("CloseButton").pressed.connect(_on_tutorial_close_button_pressed)

func update_tutorial_page():
	if not current_tutorial:
		return
	
	# 隐藏所有页面
	for i in range(total_pages):
		var page_node = current_tutorial.get_node("Page").get_child(i)
		page_node.visible = false
	
	# 显示当前页面
	var current_page_node = current_tutorial.get_node("Page").get_child(current_page - 1)
	if current_page_node:
		current_page_node.visible = true
	
	# 更新页码显示
	current_tutorial.get_node("PageCount").text = "第 %d / %d 页" % [current_page, total_pages]
	
	# 根据页码启用/禁用按钮
	current_tutorial.get_node("PreviousButton").disabled = (current_page == 1)
	current_tutorial.get_node("NextButton").disabled = (current_page == total_pages)

func _on_tutorial_next_button_pressed():
	if current_page < total_pages:
		current_page += 1
		update_tutorial_page()

func _on_tutorial_previous_button_pressed():
	if current_page > 1:
		current_page -= 1
		update_tutorial_page()

func _on_tutorial_close_button_pressed():
	if current_tutorial:
		current_tutorial.queue_free()
		current_tutorial = null

# 处理重新开始按钮点击
func _on_restart_button_pressed():
	get_tree().reload_current_scene()

# 应用毛玻璃效果到面板
func apply_glass_effect(panel):
	# 创建着色器材质
	var shader_material = ShaderMaterial.new()
	
	# 使用预加载的外部着色器
	shader_material.shader = glass_shader
	
	# 创建一个背景层
	var background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)  # 填满整个父节点
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 忽略鼠标事件，让它们传递给面板
	background.material = shader_material
	
	# 将背景层添加到面板的最底层
	panel.add_child(background)
	panel.move_child(background, 0)  # 确保它在所有其他控件的底层
	
	# 调整面板的背景色为半透明
	panel.self_modulate = Color(1, 1, 1, 0.9)  # 轻微半透明效果
