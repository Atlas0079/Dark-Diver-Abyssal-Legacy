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
@onready var ai_hand_container = $"../AIHandContainer" # 新增: AI手牌容器引用

@onready var game_logic = $".."

# 预加载方向选择器场景
var direction_selector_scene = preload("res://Scenes/NiNard/direction_arrows.tscn")

# 预加载教程场景 (仍然需要在这里预加载以实例化)
var tutorial_scene = preload("res://Scenes/NiNard/tutorial.tscn")

# 状态变量
var selected_card: NiNardCard = null
var selected_position: Vector2i = Vector2i(-1, -1)
var board_positions = []
var player1_hand_cards = []
var player2_hand_cards = []
var is_waiting_for_direction = false
var current_direction_selector: Control = null # 当前活动的方向选择器实例

# 常量
const CARD_WIDTH = 100
const CARD_HEIGHT = 150
const HAND_ARC_RADIUS = 1000
const BOARD_CELL_SIZE = 120

# 新增：计算手牌弧形布局的辅助函数
# 返回一个字典数组，每个字典包含 { "position": Vector2, "rotation": float }
func _calculate_hand_layout(num_cards: int) -> Array:
	var layouts = []
	if num_cards == 0:
		return layouts
	
	var arc_angle_range = (PI / 12.0) * max(0, num_cards - 1) # 每张牌增加15度弧度
	var start_angle = -arc_angle_range / 2.0
	var angle_step = 0.0
	if num_cards > 1:
		angle_step = arc_angle_range / (num_cards - 1)
	
	for i in range(num_cards):
		var angle = 0.0
		var card_pos = Vector2.ZERO
		var card_rotation = 0.0
		
		if num_cards == 1:
			# 单张卡牌居中且不旋转
			angle = 0.0
			card_pos = Vector2.ZERO # 放在容器原点
			card_pos.y = -HAND_ARC_RADIUS # 稍微向上移动一点以保持一致性
			card_rotation = 0.0
		else:
			# 多张卡牌计算弧形位置和旋转
			angle = start_angle + i * angle_step
			card_pos.x = HAND_ARC_RADIUS * sin(angle)
			card_pos.y = -HAND_ARC_RADIUS * cos(angle) # Y轴向上为负，向上弯曲
			card_rotation = angle
		
		layouts.append({ "position": card_pos, "rotation": card_rotation })
		
	return layouts

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
	game_logic.ai_move_requested.connect(_on_ai_move_requested)

# 更新信息面板
func update_info_panel():
	info_panel.get_node("TurnCount").text = "当前回合数：" + str(game_logic.turn_count)

	info_panel.get_node("Player1EScore").text = "你的当前得分：" + str(game_logic.player1_estimated_score)
	info_panel.get_node("Player2EScore").text = "对手当前得分：" + str(game_logic.player2_estimated_score)
	#info_panel.get_node("Player1Info/CardsLeftLabel").text = "你的剩余牌：" + str(game_logic.player1_hand.size())
	#info_panel.get_node("Player2Info/CardsLeftLabel").text = "对手的剩余牌：" + str(game_logic.player2_hand.size())


# 显示玩家手牌 (修改：只负责初始布局)
func display_player_hand(player: String):
	# 1. 获取玩家逻辑手牌
	var hand_cards = []
	if player == "player1":
		hand_cards = game_logic.player1_hand
	else:
		# AI手牌不在此显示
		return

	# 2. 清理 hand_container 中不再属于当前手牌的卡牌实例
	var current_hand_nodes = {}
	for card_node in hand_container.get_children():
		if card_node is NiNardCard:
			current_hand_nodes[card_node.card_id] = card_node
	
	var hand_card_ids = {}
	for card_logic in hand_cards:
		hand_card_ids[card_logic.card_id] = true
	
	for card_id in current_hand_nodes:
		if not hand_card_ids.has(card_id):
			current_hand_nodes[card_id].queue_free() # 或者只是 remove_child 如果实例由 Game 管理

	# 3. 计算目标布局
	var num_cards = hand_cards.size()
	var layouts = _calculate_hand_layout(num_cards)

	# 4. 放置或更新手牌节点
	for i in range(num_cards):
		var card = hand_cards[i]
		var target_layout = layouts[i]
		var target_pos = target_layout["position"]
		var target_rot = target_layout["rotation"]

		# 确保卡牌在 hand_container 中
		if card.get_parent() != hand_container:
			if card.get_parent():
				card.get_parent().remove_child(card)
			hand_container.add_child(card)
		
		# 停止可能存在的旧动画
		if card.has_meta("position_tween"): 
			var existing_tween = card.get_meta("position_tween")
			if existing_tween and is_instance_valid(existing_tween):
				existing_tween.kill()
			card.remove_meta("position_tween")

		# 设置卡片属性 (瞬间完成)
		card.card_owner = player
		card.set_selectable(true)
		card.is_on_board = false
		card.scale = Vector2(0.3, 0.3)
		card.z_index = 3
		card.position = target_pos # 直接设置位置
		card.rotation = target_rot # 直接设置旋转
		card.original_hand_position = target_pos # 更新原始位置记录
		
		# 连接信号 (只连接点击信号)
		if !card.is_connected("card_clicked", _on_hand_card_clicked):
			card.card_clicked.connect(_on_hand_card_clicked)
		
		# 更新视觉效果
		card.update_visuals()
		card.card_owner_sprite.visible = false


# 高亮可放置的棋盘位置
func highlight_valid_positions():
	# 首先清除之前的高亮效果
	clear_board_highlights()
	
	# 遍历棋盘位置
	for y in range(3):
		for x in range(3):
			# 检查位置是否为空（可放置）
			if game_logic.board[y][x] == null:
				# 创建高亮效果
				create_highlight_at_position(x, y)

# 清除棋盘高亮效果
func clear_board_highlights():
	# 获取或创建高亮层
	var highlight_layer = get_or_create_highlight_layer()
	
	# 清除所有高亮精灵
	for child in highlight_layer.get_children():
		child.queue_free()

# 在指定位置创建高亮效果
func create_highlight_at_position(x: int, y: int):
	# 获取或创建高亮层
	var highlight_layer = get_or_create_highlight_layer()
	
	# 创建发光圆形精灵
	var highlight = Sprite2D.new()
	highlight.texture = load("res://Assets/NiNard/glow_circle.png")
	highlight.name = "Highlight_" + str(x) + "_" + str(y)
	
	# 设置比较低的透明度
	highlight.modulate = Color(1, 1, 1, 0.9)
	
	# 获取对应位置节点的全局坐标
	var position_node_path = "BoardPositions/Position_" + str(x) + "_" + str(y)
	var position_node = board_container.get_node(position_node_path)
	var collision_shape = position_node.get_node("CollisionShape2D")
	
	# 将高亮精灵添加到高亮层
	highlight_layer.add_child(highlight)
	
	# 设置精灵的全局位置
	highlight.global_position = collision_shape.global_position
	
	# 确保高亮显示在卡片下方
	highlight.z_index = 1

# 获取或创建高亮层
func get_or_create_highlight_layer():
	var highlight_layer = board_container.get_node_or_null("HighlightLayer")
	
	if not highlight_layer:
		highlight_layer = Node2D.new()
		highlight_layer.name = "HighlightLayer"
		board_container.add_child(highlight_layer)
		# 确保高亮层在卡片层的下方
		board_container.move_child(highlight_layer, 0)
	
	return highlight_layer

# 处理棋盘格子点击
func _on_board_position_clicked(position: Vector2i):
	if selected_card != null and !is_waiting_for_direction:
		# 检查位置是否有效
		if game_logic.board[position.y][position.x] == null:
			# 清理上一个可能存在的方向选择器
			cleanup_direction_selector()

			selected_position = position
			is_waiting_for_direction = true

			# 清除棋盘高亮
			clear_board_highlights()

			# 获取棋盘位置的全局坐标
			var board_pos = get_board_position(position)

			# 实例化方向选择器
			current_direction_selector = direction_selector_scene.instantiate()
			add_child(current_direction_selector) # 添加到UI层
			current_direction_selector.global_position = board_pos
			current_direction_selector.visible = true
			current_direction_selector.z_index = 5 # 确保在卡牌和高亮之上

			# 连接按钮信号 (使用 bind 传递方向)
			current_direction_selector.get_node("UpButton").pressed.connect(_handle_direction_selection.bind(NiNardCard.Orientation.UP))
			current_direction_selector.get_node("RightButton").pressed.connect(_handle_direction_selection.bind(NiNardCard.Orientation.RIGHT))
			current_direction_selector.get_node("DownButton").pressed.connect(_handle_direction_selection.bind(NiNardCard.Orientation.DOWN))
			current_direction_selector.get_node("LeftButton").pressed.connect(_handle_direction_selection.bind(NiNardCard.Orientation.LEFT))
			current_direction_selector.get_node("CancelButton").pressed.connect(_handle_direction_cancel)

			# 卡牌本身不做移动，等待方向选择

# 新增：处理来自实例化的方向箭头的选择
func _handle_direction_selection(direction: int):
	if not is_waiting_for_direction or selected_card == null or selected_position == Vector2i(-1, -1):
		cleanup_direction_selector() # 状态无效，清理
		return

	is_waiting_for_direction = false
	var card_to_place = selected_card
	var target_position = selected_position
	var target_rotation = 0.0
	match direction:
		NiNardCard.Orientation.UP: target_rotation = 0
		NiNardCard.Orientation.RIGHT: target_rotation = PI/2
		NiNardCard.Orientation.DOWN: target_rotation = PI
		NiNardCard.Orientation.LEFT: target_rotation = 3*PI/2

	# 清理方向选择器
	cleanup_direction_selector()

	# --- 执行卡牌飞行动画 --- 
	# 1. 立即回正角度 (不需要了，动画会处理)
	# card_to_place.rotation = 0 

	# 2. 计算目标位置和视觉起点
	var board_pos = get_board_position(target_position)
	# 卡牌的当前全局位置作为起点
	var start_pos = card_to_place.global_position 
	var start_scale = card_to_place.scale # 当前缩放作为起点
	var start_rotation = card_to_place.rotation # 当前旋转作为起点

	# 3. 将卡牌从手牌容器移到棋盘容器
	if card_to_place.get_parent() == hand_container:
		hand_container.remove_child(card_to_place)
		# --- 手牌重排动画 --- 
		_animate_hand_reorder() # 调用新的动画函数
		# --- 添加到棋盘 --- 
		board_container.get_node("CardsLayer").add_child(card_to_place)
		# 重新设置全局位置，因为父节点变了
		card_to_place.global_position = start_pos 
	else: # 如果因为某种原因卡牌不在手牌容器了 (理论上不应该发生)
		board_container.get_node("CardsLayer").add_child(card_to_place)
		card_to_place.global_position = start_pos

	# 4. 立即设置卡牌到视觉起点和初始状态 (起点现在是卡牌当前状态)
	# card_to_place.global_position = start_pos 

	# 5. 创建动画从起点飞向目标 (同时处理位置、缩放、旋转)
	var move_tween = create_tween()
	move_tween.set_parallel(true) # 确保动画并行执行
	move_tween.tween_property(card_to_place, "global_position", board_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(card_to_place, "scale", Vector2(0.2, 0.2), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(card_to_place, "rotation", target_rotation, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 6. 动画结束后调用游戏逻辑放置卡牌
	move_tween.tween_callback(func():
		if is_instance_valid(card_to_place): # 确保卡牌仍然有效
			# 确保最终状态正确 (位置和缩放由动画保证，旋转也由动画保证)
			# card_to_place.global_position = get_board_position(target_position) 
			# card_to_place.scale = Vector2(0.2, 0.2)
			# card_to_place.rotation = 0 # 移除这行，旋转由动画处理

			# 调用游戏逻辑
			var success = game_logic.place_card(game_logic.current_player, card_to_place, target_position, direction)
			if not success:
				# 如果放置失败 (理论上此时不应失败，因为格子是空的)
				push_error("放置卡牌失败，即使UI检查通过！") # 使用 push_error
				_revert_card_to_hand(card_to_place)
	)

	# 重置UI选择状态 (GameLogic的信号会进一步更新UI)
	selected_card = null
	selected_position = Vector2i(-1, -1)


# 新增：处理来自实例化的方向箭头的取消
func _handle_direction_cancel():
	if not is_waiting_for_direction:
		return

	is_waiting_for_direction = false

	# 清理方向选择器
	cleanup_direction_selector()

	# 取消卡牌选择
	if selected_card:
		# 让卡牌动画回到原始手牌位置
		var prev_tween = selected_card.get_meta("position_tween", null)
		if prev_tween and is_instance_valid(prev_tween):
			prev_tween.kill()

		var tween_down = create_tween()
		tween_down.tween_property(selected_card, "position", selected_card.original_hand_position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		selected_card.set_meta("position_tween", tween_down)

		# 恢复视觉
		selected_card.modulate = Color(1, 1, 1, 1)

	# 重置选择状态
	selected_card = null
	selected_position = Vector2i(-1, -1)
	clear_board_highlights() # 取消时清除高亮


# 新增：清理方向选择器的辅助函数
func cleanup_direction_selector():
	if current_direction_selector and is_instance_valid(current_direction_selector):
		current_direction_selector.queue_free()
	current_direction_selector = null


# 新增：放置失败时将卡牌放回手牌 (简化版)
func _revert_card_to_hand(card: NiNardCard):
	if card and is_instance_valid(card):
		# 从棋盘层移除
		if card.get_parent() == board_container.get_node("CardsLayer"):
			card.get_parent().remove_child(card)
		# 重置状态
		card.is_on_board = false
		card.modulate = Color(1, 1, 1, 1)
		# 重新显示手牌，它会被放回正确位置
		display_player_hand(game_logic.current_player)


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
		# 如果正在等待方向选择时点击了手牌，取消方向选择
		_handle_direction_cancel()
		# return # 决定是否在取消后立即返回，或者允许重新选择这张牌

	# 清理可能存在的方向选择器
	cleanup_direction_selector()

	# --- 处理上一个选中的卡牌 ---
	if selected_card != null and selected_card != card:
		# 停止上一个卡牌的现有动画
		if selected_card.has_meta("position_tween"): # 先检查是否存在
			var prev_tween = selected_card.get_meta("position_tween") # 存在才获取
			if prev_tween and is_instance_valid(prev_tween):
				prev_tween.kill()
			# 可以考虑在这里移除meta，虽然不是必须
			# selected_card.remove_meta("position_tween") 

		# 创建动画让上一个卡牌回到原位
		var tween_down = create_tween()
		tween_down.tween_property(selected_card, "position", selected_card.original_hand_position, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		selected_card.set_meta("position_tween", tween_down) # 设置新的tween meta

		# 恢复上一个卡牌的视觉效果
		selected_card.modulate = Color(1, 1, 1, 1)
		clear_board_highlights() # 清除高亮

	# --- 处理新选中的卡牌 ---
	if selected_card != card:
		selected_card = card

		# 停止当前卡牌的现有动画
		if card.has_meta("position_tween"): # 先检查是否存在
			var current_tween = card.get_meta("position_tween") # 存在才获取
			if current_tween and is_instance_valid(current_tween):
				current_tween.kill()
			# 可以考虑在这里移除meta
			# card.remove_meta("position_tween")

		# 创建动画让当前卡牌向上移动
		var target_pos = card.original_hand_position - Vector2(0, 30)
		var tween_up = create_tween()
		tween_up.tween_property(card, "position", target_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		card.set_meta("position_tween", tween_up) # 设置新的tween meta

		# 高亮选中的牌
		card.modulate = Color(1.2, 1.2, 1.2, 1.0)

		# 高亮可放置的棋盘位置
		highlight_valid_positions()

# 新增：处理场上卡牌点击
func _on_board_card_clicked(card: NiNardCard):
	# 这里可以添加场上卡牌点击时的效果
	print("场上卡牌被点击: " + card.card_id + ", 花色: " + str(card.suit) + ", 数值: " + str(card.value))
	
	# 示例：显示卡牌信息
	info_panel.get_node("GameMessage").text = "卡牌: " + card.card_name + " - " + card.card_description
	
	# 如果正在等待方向选择，点击场上牌应该取消
	if is_waiting_for_direction:
		_handle_direction_cancel()


# 移除 _on_card_direction_selected 和 _on_card_selection_cancelled


# 游戏逻辑信号处理 (修改：清理方向选择器)
func _on_turn_changed(player: String):
	update_info_panel()

	# 清理可能存在的方向选择器
	cleanup_direction_selector()

	# 取消选择 (如果当前有牌被选中)
	if selected_card:
		# 停止动画
		var existing_tween = selected_card.get_meta("position_tween", null)
		if existing_tween and is_instance_valid(existing_tween):
			existing_tween.kill()
		selected_card.remove_meta("position_tween")
		# 恢复视觉
		selected_card.modulate = Color(1, 1, 1, 1)
		selected_card = null # 清除选中状态

	# 清除棋盘高亮
	clear_board_highlights()

	# -- 修改手牌显示逻辑 --
	if player == "player1":
		# 轮到玩家，显示玩家手牌 (调用初始布局函数)
		display_player_hand("player1") # 这会重新启用卡牌选择
		info_panel.get_node("GameMessage").text = "轮到你了"
	else: # player == "player2"
		# 轮到AI，禁用玩家手牌交互
		for child in hand_container.get_children():
			if child is NiNardCard:
				child.set_selectable(false)
		
		# 只更新提示，不显示AI手牌
		info_panel.get_node("GameMessage").text = "对手思考中..."
		# 玩家的手牌（减去刚打出的牌）应该保持显示，由之前的 _animate_hand_reorder 动画处理


func _on_card_placed(player: String, card: NiNardCard, position: Vector2i, orientation: int):
	# 这个函数现在主要由 game_logic 触发，在卡牌动画结束并调用 place_card 后
	# 它的作用是确认最终状态和更新UI

	# 确保卡牌在正确的父节点下
	if card.get_parent() != board_container.get_node("CardsLayer"):
		if card.get_parent():
			card.get_parent().remove_child(card)
		board_container.get_node("CardsLayer").add_child(card)

	# 确保最终状态 (可能动画被跳过或异常)
	# 位置、旋转、缩放由动画结束时保证，这里不再强制设置
	# card.global_position = get_board_position(position)
	# card.scale = Vector2(0.2, 0.2)
	# match orientation:
	# 	NiNardCard.Orientation.UP: card.rotation = 0
	# 	NiNardCard.Orientation.RIGHT: card.rotation = PI/2
	# 	NiNardCard.Orientation.DOWN: card.rotation = PI
	# 	NiNardCard.Orientation.LEFT: card.rotation = 3*PI/2

	card.set_selectable(true)
	card.is_on_board = true
	card.modulate = Color(1, 1, 1, 1)

	card.update_visuals() # 更新拥有者标记等

	update_info_panel()

	# -- 移除手牌更新调用 --
	# 移除这行，因为_on_turn_changed会在正确的时间处理手牌显示
	# display_player_hand(game_logic.current_player) 


func _on_card_captured(player: String, card: NiNardCard, position: Vector2i = Vector2i(-1,-1)): # 添加 position 默认值
	# 直接使用传入的卡片实例
	card.card_owner_sprite.visible = true
	card.update_visuals()

func _on_initial_cards_drawn(player1_card: NiNardCard, player2_card: NiNardCard, first_player: String):
	info_panel.get_node("GameMessage").text = "游戏开始！" + first_player + " 先手"
	
	# 检查先手玩家是否为人类玩家
	if first_player == "player1":
		# 获取 InitialChoicePanel 脚本实例
		var choice_panel_script = initial_choice_panel.get_script()
		if choice_panel_script and initial_choice_panel.has_method("show_choice"):
			# 连接信号，以便在选择完成后得到通知
			if !initial_choice_panel.is_connected("initial_choice_made", _on_initial_choice_panel_made_choice):
				var err = initial_choice_panel.connect("initial_choice_made", _on_initial_choice_panel_made_choice)
				if err != OK:
					push_error("连接 initial_choice_made 信号失败: %s" % err)
			
			# 调用新脚本的方法来显示选择
			initial_choice_panel.show_choice(player1_card, player2_card)
		else:
			push_error("无法在 initial_choice_panel 上找到脚本或 show_choice 方法")
			# 提供后备方案或错误处理
			game_logic.ai_select_initial_card(player1_card, player2_card) # 例如让 AI 选择
	else:
		# AI玩家，直接让AI选择
		info_panel.get_node("GameMessage").text = "游戏开始！AI先手并选择了初始卡牌"
		
		# 延迟一小段时间
		# await get_tree().create_timer(1.0).timeout
		
		# 调用游戏逻辑中的AI选择函数
		game_logic.ai_select_initial_card(player1_card, player2_card)

# 新增: 处理来自 InitialChoicePanel 的信号
func _on_initial_choice_panel_made_choice(top_card: NiNardCard, bottom_card: NiNardCard):
	# 断开信号避免重复处理 (可选，取决于面板是否会被重用)
	if initial_choice_panel.is_connected("initial_choice_made", _on_initial_choice_panel_made_choice):
		initial_choice_panel.disconnect("initial_choice_made", _on_initial_choice_panel_made_choice)
	
	# 通知游戏逻辑放置初始卡牌
	game_logic.place_initial_card(top_card, bottom_card)


func _on_initial_card_placed(top_card: NiNardCard, bottom_card: NiNardCard):
	# 直接使用传入的卡片实例
	if top_card.get_parent():
		top_card.get_parent().remove_child(top_card)
	board_container.get_node("CardsLayer").add_child(top_card)
	
	# 设置位置
	top_card.scale = Vector2(0.2, 0.2)
	top_card.global_position = get_board_position(Vector2i(1, 1))
	
	# 重置旋转角度
	top_card.rotation = 0
	
	top_card.update_visuals()
	top_card.z_index = 1
	
	# 确保卡牌可点击但标记为场上卡牌
	top_card.set_selectable(true)
	top_card.is_on_board = true
	top_card.modulate = Color(1, 1, 1, 1)

	if bottom_card.get_parent():
		bottom_card.get_parent().remove_child(bottom_card)
	board_container.get_node("CardsLayer").add_child(bottom_card)
	
	# 设置位置
	bottom_card.scale = Vector2(0.2, 0.2)
	
	# 重置旋转角度并设置正确方向
	bottom_card.rotation = PI/2
	
	bottom_card.global_position = get_board_position(Vector2i(1, 1))
	
	# 确保卡牌可点击但标记为场上卡牌
	bottom_card.set_selectable(true)
	bottom_card.is_on_board = true
	bottom_card.update_visuals()
	bottom_card.modulate = Color(1, 1, 1, 1)

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
				card.update_visuals()

# 游戏结束 (修改：清理方向选择器)
func _on_game_ended(winner: String, player1_score: int, player2_score: int):
	# 清理可能存在的方向选择器
	cleanup_direction_selector()

	# 构造结束信息
	var end_message = "游戏结束！\n"
	if winner == "draw":
		end_message += "平局！"
	elif winner == "player1":
		end_message += "你赢了！"
	else:
		end_message += "对手赢了！"
	
	end_message += "\n最终得分:\n你的得分: %d\n对手得分: %d" % [player1_score, player2_score]
	
	# 取消选择 (如果当前有牌被选中)
	if selected_card:
		# 停止动画
		var existing_tween = selected_card.get_meta("position_tween", null)
		if existing_tween and is_instance_valid(existing_tween):
			existing_tween.kill()
		selected_card.remove_meta("position_tween")
		# 恢复视觉
		selected_card.modulate = Color(1, 1, 1, 1)
		selected_card = null # 清除选中状态

	# 更新信息面板
	info_panel.get_node("GameMessage").text = end_message
	info_panel.get_node("Player1EScore").text = "你的最终得分: " + str(player1_score)
	info_panel.get_node("Player2EScore").text = "对手最终得分: " + str(player2_score)
	
	# 显示重新开始按钮
	restart_button.visible = true
	
	# 禁用手牌交互
	for child in hand_container.get_children():
		if child is NiNardCard:
			child.set_selectable(false)

# 教程相关函数
func _on_tutorial_button_pressed():
	# 检查是否已有教程窗口打开 (通过节点名称查找)
	if get_tree().root.has_node("TutorialPanelInstance"): # 或者使用 find_child
		print("教程已打开")
		return
	
	# 实例化教程场景
	var tutorial_instance = tutorial_scene.instantiate()
	# 给实例一个唯一的名字，方便查找
	tutorial_instance.name = "TutorialPanelInstance"
	# 添加到场景树的根节点，确保在所有游戏UI之上
	get_tree().root.add_child(tutorial_instance)
	# 教程实例的 _ready() 函数会处理内部设置
	print("教程已实例化并添加到场景")

# 处理重新开始按钮点击
func _on_restart_button_pressed():
	# 清理可能存在的教程窗口
	var existing_tutorial = get_tree().root.get_node_or_null("TutorialPanelInstance")
	if existing_tutorial:
		existing_tutorial.queue_free()
	get_tree().reload_current_scene()

# 新增：处理AI请求的移动动画
func _on_ai_move_requested(card: NiNardCard, position: Vector2i, direction: int):
	# --- 执行卡牌飞行动画 ---
	# 1. 确保角度回正 (不需要了，动画会处理)
	# card.rotation = 0
	var target_rotation = 0.0
	match direction:
		NiNardCard.Orientation.UP: target_rotation = 0
		NiNardCard.Orientation.RIGHT: target_rotation = PI/2
		NiNardCard.Orientation.DOWN: target_rotation = PI
		NiNardCard.Orientation.LEFT: target_rotation = 3*PI/2

	# 2. 计算目标位置和视觉起点 (AI手牌容器中心)
	var board_pos = get_board_position(position)
	var start_pos = ai_hand_container.global_position + ai_hand_container.size / 2.0 # AI手牌容器中心作为起点
	var start_scale = Vector2(0.3, 0.3) # AI卡牌动画开始时用手牌大小
	var start_rotation = 0 # AI卡牌动画开始时默认朝上

	# 3. 将卡牌添加到棋盘容器
	if card.get_parent(): # 从可能存在的父节点移除
		card.get_parent().remove_child(card)
	board_container.get_node("CardsLayer").add_child(card)

	# 4. 立即设置卡牌到视觉起点和初始状态
	card.global_position = start_pos
	card.scale = start_scale 
	card.rotation = start_rotation
	card.z_index = 2 # 比棋盘高亮高，比方向选择器低

	# 5. 创建动画从起点飞向目标 (同时处理位置、缩放、旋转)
	var move_tween = create_tween()
	move_tween.set_parallel(true) # 确保动画并行执行
	move_tween.tween_property(card, "global_position", board_pos, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(card, "scale", Vector2(0.2, 0.2), 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	move_tween.tween_property(card, "rotation", target_rotation, 0.3).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# 6. 动画结束后调用游戏逻辑放置卡牌
	move_tween.tween_callback(func():
		if is_instance_valid(card): # 确保卡牌仍然有效
			# 确保最终状态正确 (位置、缩放、旋转都由动画处理)
			# card.global_position = get_board_position(position)
			# card.scale = Vector2(0.2, 0.2)
			# card.rotation = 0 # 移除这行

			# 调用游戏逻辑
			var success = game_logic.place_card("player2", card, position, direction)
			if not success:
				# 如果放置失败 (理论上此时不应失败，除非AI逻辑有误)
				push_error("AI放置卡牌失败！卡牌: %s, 位置: %s" % [card.card_id, position])
				# 这里可能需要错误处理，例如简单地隐藏卡牌或尝试回退
				card.queue_free() # 简单处理：移除失败的卡牌
	)

func _on_player_turn():
	pass

# 新增：动画化手牌重新排序
func _animate_hand_reorder():
	# 1. 获取 hand_container 中剩余的卡牌节点
	var remaining_cards = []
	for child in hand_container.get_children():
		if child is NiNardCard:
			remaining_cards.append(child)
	
	# 2. 计算新的布局
	var num_remaining = remaining_cards.size()
	var new_layouts = _calculate_hand_layout(num_remaining)
	
	# 3. 为每个剩余卡牌创建动画
	for i in range(num_remaining):
		var card_node = remaining_cards[i]
		var target_layout = new_layouts[i]
		var target_pos = target_layout["position"]
		var target_rot = target_layout["rotation"]
		
		# 停止可能存在的旧动画
		if card_node.has_meta("position_tween"): 
			var existing_tween = card_node.get_meta("position_tween")
			if existing_tween and is_instance_valid(existing_tween):
				existing_tween.kill()
			# 不要移除 meta，让新的 tween 覆盖
		
		# 创建新的动画
		var reorder_tween = create_tween()
		reorder_tween.set_parallel(true)
		reorder_tween.tween_property(card_node, "position", target_pos, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT) # 使用稍快的动画
		reorder_tween.tween_property(card_node, "rotation", target_rot, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
		# 存储动画引用 (可选，但推荐)
		card_node.set_meta("position_tween", reorder_tween)
		
		# 更新卡牌记录的原始位置 (重要！)
		card_node.original_hand_position = target_pos
