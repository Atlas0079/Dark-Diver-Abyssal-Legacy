class_name NiNardGame
extends Node

signal turn_changed(player)
signal card_placed(player, card, position, orientation)
signal card_captured(player, card, position)
signal game_ended(winner, player1_score, player2_score)
signal initial_cards_drawn(player1_card, player2_card, first_player)
signal initial_card_placed(top_card, bottom_card)
signal player_turn
signal scores_updated(player1_score, player2_score)
signal ai_move_requested(card, position, direction)

var player1_hand = []
var player2_hand = []
var board = []

var current_player: String
var first_player: String
var turn_count: int

var player1_score: int
var player2_score: int

var player1_estimated_score: int
var player2_estimated_score: int

var center_card_down: NiNardCard
var game_phase = "setup" # setup, playing, ended
var game_started = false # 跟踪游戏是否已经开始

# 卡牌数据缓存
var card_data_cache = {}

# 添加卡片场景引用
@export var card_scene = preload("res://Scenes/NiNard/card.tscn")

# 添加卡片实例字典，用于存储所有卡片实例
var card_instances = {}

# 添加AI玩家引用
@onready var ai_player = $AIPlayer
# 添加游戏控制按钮引用
@onready var game_control_button = $GameControlButton 

func _init():
	for i in range(3):
		board.append([null, null, null])

func start_game(deck_info: Dictionary = {}):
	# 仅在游戏首次开始时执行完整的启动逻辑
	if !game_started:
		current_player = "player1"
		turn_count = 0
		player1_score = 0
		player2_score = 0
		player1_estimated_score = 0
		player2_estimated_score = 0
		game_phase = "setup"
		
		# 清理棋盘（如果之前有卡牌）
		clear_board_visuals()
		for i in range(3):
			board[i] = [null, null, null]
		
		# 重新初始化卡组和手牌
		init_deck(deck_info)
		
		# 随机确定先手玩家
		randomize()
		first_player = "player1" if randi() % 2 == 0 else "player2"
		current_player = first_player
		
		# 从双方手牌中随机抽取一张牌
		var player1_card = player1_hand.pick_random()
		var player2_card = player2_hand.pick_random()
		
		# 移除已抽取的牌
		player1_hand.erase(player1_card)
		player2_hand.erase(player2_card)
		
		# 发出信号通知UI
		emit_signal("initial_cards_drawn", player1_card, player2_card, first_player)
		
		# 修改按钮行为
		game_control_button.text = "重新开始"
		if game_control_button.is_connected("pressed", start_game):
			game_control_button.disconnect("pressed", start_game)
		if !game_control_button.is_connected("pressed", _restart_game):
			game_control_button.pressed.connect(_restart_game)
		
		game_started = true

func init_deck(deck_info: Dictionary = {}):
	if deck_info.is_empty():
		# 默认牌组
		var default_player1_cards = ["S0001", "H0002", "D0003", "C0004", "C0005"]
		var default_player2_cards = ["H0001", "D0002", "C0003", "S0004", "S0005"]
		
		player1_hand = []
		player2_hand = []
		
		for card_id in default_player1_cards:
			var card = get_card_instance(card_id)
			if card:
				player1_hand.append(card)
		
		for card_id in default_player2_cards:
			var card = get_card_instance(card_id)
			if card:
				player2_hand.append(card) 
	else:
		# 使用提供的牌组信息
		player1_hand = []
		player2_hand = []
		
		if deck_info.has("player1_cards"):
			for card_id in deck_info.player1_cards:
				var card = get_card_instance(card_id)
				if card:
					player1_hand.append(card)
		
		if deck_info.has("player2_cards"):
			for card_id in deck_info.player2_cards:
				var card = get_card_instance(card_id)
				if card:
					player2_hand.append(card)

# 从JSON加载卡牌数据
func load_card_data():
	var file = FileAccess.open("res://Dataset/Template/NiNard/Cards.json", FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		if error == OK:
			card_data_cache = json.get_data()
		else:
			push_error("解析卡牌JSON数据失败: " + json.get_error_message() + " at line " + str(json.get_error_line()))
	else:
		push_error("无法打开卡牌数据文件")

# 预加载所有卡片实例
func preload_all_card_instances():
	# 确保卡片数据已加载
	if card_data_cache.is_empty():
		load_card_data()
	
	# 为每个卡片ID创建一个实例
	for card_id in card_data_cache.keys():
		var card_instance = card_scene.instantiate()
		var data = card_data_cache[card_id]
		
		# 设置卡牌属性
		card_instance.value = data.value
		
		# 设置花色
		match data.suit:
			"SPADE":
				card_instance.suit = NiNardCard.Suit.SPADE
			"HEART":
				card_instance.suit = NiNardCard.Suit.HEART
			"DIAMOND":
				card_instance.suit = NiNardCard.Suit.DIAMOND
			"CLUB":
				card_instance.suit = NiNardCard.Suit.CLUB
		
		# 设置卡牌名称和描述
		card_instance.card_name = data.card_name
		card_instance.card_description = data.card_description
		card_instance.card_id = card_id
		
		#如果sprite_path存在，则设置卡牌的sprite
		if data.has("sprite_path"):
			# 确保card_sprite已经初始化后再设置texture
			if card_instance.has_node("CardSprite"):
				card_instance.get_node("CardSprite").texture = load(data.sprite_path)
			else:
				push_error("无法找到CardSprite节点: " + card_id)
		else:
			print("sprite_path不存在，使用默认sprite: " + card_id)
		
		# 存储实例
		card_instances[card_id] = card_instance

# 修改获取卡片实例的方法，从预加载的实例中获取
func get_card_instance(card_id: String) -> NiNardCard:
	if card_instances.has(card_id):
		# 如果卡片已经在场景树中，先移除
		var card = card_instances[card_id]
		if card.get_parent():
			card.get_parent().remove_child(card)
		return card
	else:
		push_error("卡片ID不存在: " + card_id)
		return null

# 处理初始牌的放置
func place_initial_card(top_card: NiNardCard, bottom_card: NiNardCard):
	# 放置中央牌
	board[1][1] = top_card
	top_card.card_owner = current_player
	top_card.is_on_board = true  # 设置为场上卡牌
	
	# 设置中央下方的牌
	center_card_down = bottom_card
	bottom_card.is_on_board = true  # 设置为场上卡牌
	
	# 发出信号
	emit_signal("initial_card_placed", top_card, bottom_card)
	
	# 更新预估分数
	update_estimated_scores()
	
	game_phase = "playing"
	process_turn()

# 玩家放置卡牌
func place_card(player: String, card: NiNardCard, position: Vector2i, orientation: int) -> bool:
	if game_phase != "playing" or player != current_player:
		return false
		
	if position.x < 0 or position.x >= 3 or position.y < 0 or position.y >= 3:
		return false
		
	if board[position.y][position.x] != null:
		return false
	
	# 从玩家手牌中移除
	if player == "player1":
		player1_hand.erase(card)
	else:
		player2_hand.erase(card)
	
	# 设置卡牌属性
	card.card_owner = player
	card.orientation = orientation
	card.is_on_board = true  # 设置为场上卡牌
	
	# 放置卡牌
	board[position.y][position.x] = card
	
	# 发出信号
	emit_signal("card_placed", player, card, position, orientation)
	
	# 处理占领效果
	print("place_card card: " + card.card_id)
	apply_capture(card, position)
	
	# 更新预估分数
	update_estimated_scores()
	
	# 检查游戏是否结束
	if check_game_end():
		end_game()
	else:
		switch_player()
		#这里不需要process_turn()，它在switch_player里处理了
	
	return true

# 处理占领效果
func apply_capture(placed_card: NiNardCard, position: Vector2i):
	var check_offset = get_offset_for_orientation(placed_card.orientation)
	print("apply_capture position: " + str(position))
	var target_pos = Vector2i(position.x + check_offset.x, position.y + check_offset.y)
	
	# 检查目标位置是否在棋盘范围内
	if target_pos.x < 0 or target_pos.x >= 3 or target_pos.y < 0 or target_pos.y >= 3:
		print("apply_capture target_pos out of range")
		return # 超出边界，无法占领
	
	# 获取目标位置的牌
	var target_card = board[target_pos.y][target_pos.x]
	if target_card == null:
		print("apply_capture target_card is null")
		return # 目标位置没有牌，无法占领
	
	print("apply_capture target_card: " + target_card.card_id)
	
	# 使用新的检查函数判断是否可以占领
	if can_capture(placed_card, target_card):
		# 占领牌，将其标记为当前玩家的
		target_card.card_owner = current_player
		print("apply_capture target_card capture success: " + target_card.card_owner)
		target_card.update_visuals() # 更新卡牌的视觉显示，包括得分
		emit_signal("card_captured", current_player, target_card)

# 新增：判断是否可以占领目标卡牌
func can_capture(attacker_card: NiNardCard, target_card: NiNardCard) -> bool:
	# 检查1：数值条件 - 如果目标卡牌的数值大于攻击卡牌的数值
	var value_condition = target_card.value > attacker_card.value
	
	# 检查2：花色条件 - 如果两张卡牌花色相同
	var suit_condition = target_card.suit == attacker_card.suit
	
	# 检查3：方向条件 - 攻击卡牌与目标卡牌的方向不能相反
	var direction_condition = !are_directions_opposite(attacker_card.orientation, target_card.orientation)
	
	# 满足数值条件或花色条件，同时满足方向条件
	return (value_condition or suit_condition) and direction_condition

# 新增：判断两个方向是否相反
func are_directions_opposite(dir1: int, dir2: int) -> bool:
	# UP(0) 与 DOWN(2) 相反
	# RIGHT(1) 与 LEFT(3) 相反
	return (dir1 == NiNardCard.Orientation.UP and dir2 == NiNardCard.Orientation.DOWN) or \
		   (dir1 == NiNardCard.Orientation.DOWN and dir2 == NiNardCard.Orientation.UP) or \
		   (dir1 == NiNardCard.Orientation.RIGHT and dir2 == NiNardCard.Orientation.LEFT) or \
		   (dir1 == NiNardCard.Orientation.LEFT and dir2 == NiNardCard.Orientation.RIGHT)

# 辅助函数：获取方向对应的偏移量
func get_offset_for_orientation(orientation) -> Vector2i:
	match orientation:
		NiNardCard.Orientation.UP:    return Vector2i(-1, 0)
		NiNardCard.Orientation.RIGHT: return Vector2i(0, 1)
		NiNardCard.Orientation.DOWN:  return Vector2i(1, 0)
		NiNardCard.Orientation.LEFT:  return Vector2i(0, -1)
		_: 
			push_error("Invalid orientation")
			return Vector2i(0, 0)

# 切换当前玩家
func switch_player():
	if current_player == "player1":
		current_player = "player2"
	else:
		current_player = "player1"
	turn_count += 1
	emit_signal("turn_changed", current_player)
	process_turn()

# 检查游戏是否结束
func check_game_end() -> bool:
	# 检查棋盘是否已满
	for y in range(3):
		for x in range(3):
			if board[y][x] == null:
				return false
	return true

# 结束游戏并计算得分
func end_game():
	print("end_game")
	game_phase = "ended"
	calculate_scores()
	var winner = "player1" if player1_score > player2_score else "player2"
	if player1_score == player2_score:
		winner = "draw"

	emit_signal("game_ended", winner, player1_score, player2_score)

# 计算最终得分
func calculate_scores():
	# 0. 重置所有棋盘上卡牌的顺子/同花状态
	for y_reset in range(3):
		for x_reset in range(3):
			var card_to_reset = board[y_reset][x_reset]
			if card_to_reset != null:
				card_to_reset.is_in_straight = false
				card_to_reset.is_in_flush = false

	# 1. 初始化：重置所有卡牌的基础得分
	for y in range(3):
		for x in range(3):
			var card = board[y][x]
			if card != null:
				card.score = card.value

	# 2. 特殊处理中心牌 (1, 1) 的得分
	var center_card = board[1][1]
	if center_card != null and center_card_down != null:
		center_card.score = center_card.value * center_card_down.value
		# 中心牌也需要更新视觉
		center_card.update_visuals()

	# 3. 遍历所有非中心牌，检查其是否属于顺子或同花
	for y in range(3):
		for x in range(3):
			var current_card = board[y][x]
			if current_card == null:
				continue

			var is_part_of_straight = false
			var is_part_of_flush = false

			# 定义需要检查的线
			var lines_to_check = []

			# 添加行
			var row_cards = []
			for i in range(3):
				row_cards.append(board[y][i])
			lines_to_check.append(row_cards)

			# 添加列
			var col_cards = []
			for i in range(3):
				col_cards.append(board[i][x])
			lines_to_check.append(col_cards)

			# 添加主对角线 (如果卡牌在上面)
			if x == y:
				var diag1_cards = []
				for i in range(3):
					diag1_cards.append(board[i][i])
				lines_to_check.append(diag1_cards)

			# 添加副对角线 (如果卡牌在上面)
			if x + y == 2:
				var diag2_cards = []
				for i in range(3):
					diag2_cards.append(board[i][2-i])
				lines_to_check.append(diag2_cards)

			# 检查每一条相关的线
			for line_cards in lines_to_check:
				# 过滤掉包含空值的线
				var complete_line = true
				for card in line_cards:
					if card == null:
						complete_line = false
						break
				
				if complete_line:
					if check_straight(line_cards):
						is_part_of_straight = true
					if check_flush(line_cards):
						is_part_of_flush = true

			# 4. 根据检查结果更新当前卡牌的分数和状态
			current_card.is_in_straight = is_part_of_straight # 更新状态
			current_card.is_in_flush = is_part_of_flush      # 更新状态
			
			# 仅对非中心牌应用分数翻倍
			if x != 1 or y != 1: 
				if is_part_of_straight:
					current_card.score *= 2
				if is_part_of_flush:
					current_card.score *= 2

			# 5. 更新卡牌视觉 (这个函数稍后可以用来触发着色器)
			current_card.update_visuals()

	# 6. 最后计算总分
	player1_score = 0
	player2_score = 0

	for y_final in range(3):
		for x_final in range(3):
			var final_card = board[y_final][x_final]
			if final_card == null:
				continue

			if final_card.card_owner == "player1":
				player1_score += final_card.score
			elif final_card.card_owner == "player2":
				player2_score += final_card.score

# 检查是否为顺子 (考虑位置顺序)
func check_straight(cards: Array) -> bool:
	if cards.size() < 3:
		return false
		
	# 直接检查按位置顺序的数值
	var val0 = cards[0].value
	var val1 = cards[1].value
	var val2 = cards[2].value
	
	# 检查升序: val0 + 1 == val1 AND val1 + 1 == val2
	var ascending = (val0 + 1 == val1) and (val1 + 1 == val2)
	
	# 检查降序: val0 - 1 == val1 AND val1 - 1 == val2
	var descending = (val0 - 1 == val1) and (val1 - 1 == val2)
	
	return ascending or descending

# 检查是否为同花
func check_flush(cards: Array) -> bool:
	if cards.size() < 3:
		return false
		
	var first_suit = cards[0].suit
	for card in cards:
		if card.suit != first_suit:
			return false
	
	return true

func bot_action():
	# 使用AI玩家执行回合
	ai_player.execute_turn()

# 异步处理回合逻辑，以便加入AI思考延迟
func process_turn() -> void: # 添加 -> void 返回类型，如果需要async
	# 更新游戏状态
	update_estimated_scores()
	
	# 检查是否是AI玩家的回合
	if current_player == "player2":  # 假设player2是AI
		# === AI 思考延迟 ===
		# 创建一个2秒的计时器并等待它完成
		await get_tree().create_timer(2.0).timeout
		# 延迟结束后，执行AI行动
		if game_phase == "playing": # 再次检查游戏状态，防止计时期间游戏结束
			bot_action()
	else: # current_player == "player1"
		# 玩家回合，发出 turn_changed 信号，UI会据此显示手牌和提示
		emit_signal("turn_changed", "player1")
		# 玩家的操作通过UI事件触发place_card()
		pass

func update_estimated_scores():
	# 保存当前分数
	var temp_player1_score = player1_score
	var temp_player2_score = player2_score
	
	# 计算当前预估分数
	calculate_scores()
	
	# 更新预估分数
	player1_estimated_score = player1_score
	player2_estimated_score = player2_score
	
	# 恢复原始分数
	player1_score = temp_player1_score
	player2_score = temp_player2_score
	
	# 发出信号通知UI更新
	emit_signal("scores_updated", player1_estimated_score, player2_estimated_score)

# 在_init或_ready中加载卡牌数据
func _ready():
	load_card_data()
	# 在游戏开始时预先创建所有卡片实例
	preload_all_card_instances()
	
	# 初始化AI玩家
	if ai_player:
		ai_player.initialize(self)

# 修改AI选择初始卡牌的函数
func ai_select_initial_card(player1_card: NiNardCard, player2_card: NiNardCard):
	# 使用AI玩家的决策
	var decision = ai_player.select_initial_card(player1_card, player2_card)
	
	# 放置初始卡牌
	place_initial_card(decision.top_card, decision.bottom_card)

# 新增：清理棋盘视觉效果
func clear_board_visuals():
	var cards_layer = get_node_or_null("BoardContainer/CardsLayer")
	if cards_layer:
		for child in cards_layer.get_children():
			child.queue_free()
	# 你可能还需要在这里重置UI中的其他元素，例如消息标签等
	var info_panel = get_node_or_null("InfoPanel")
	if info_panel:
		info_panel.get_node("GameMessage").text = ""
		info_panel.get_node("Player1EScore").text = "你的当前得分: 0"
		info_panel.get_node("Player2EScore").text = "对手当前得分: 0"
		info_panel.get_node("TurnCount").text = "当前回合数: 0"

# 新增：重新开始游戏（通过重新加载场景）
func _restart_game():
	get_tree().reload_current_scene()
