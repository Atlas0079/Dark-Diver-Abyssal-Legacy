class_name NiNardAIPlayer
extends Node

# AI难度等级
enum Difficulty { EASY, MEDIUM, HARD }

# 当前难度
@export var difficulty: Difficulty = Difficulty.HARD

# 游戏引用，用于访问游戏状态
var game

# 初始化AI
func initialize(game_instance):
	game = game_instance

# 选择初始卡牌
func select_initial_card(player1_card: NiNardCard, player2_card: NiNardCard) -> Dictionary:
	# 根据难度选择不同策略
	match difficulty:
		Difficulty.EASY:
			return select_initial_card_easy(player1_card, player2_card)
		Difficulty.MEDIUM:
			return select_initial_card_medium(player1_card, player2_card)
		Difficulty.HARD:
			return select_initial_card_hard(player1_card, player2_card)
	
	# 默认简单策略
	return select_initial_card_easy(player1_card, player2_card)

# 简单策略：总是选择自己的卡片作为顶部卡片
func select_initial_card_easy(player1_card: NiNardCard, player2_card: NiNardCard) -> Dictionary:
	return {
		"top_card": player2_card,
		"bottom_card": player1_card
	}

# 中等策略：选择数值较大的卡片作为顶部卡片
func select_initial_card_medium(player1_card: NiNardCard, player2_card: NiNardCard) -> Dictionary:
	if player2_card.value > player1_card.value:
		return {
			"top_card": player2_card,
			"bottom_card": player1_card
		}
	else:
		return {
			"top_card": player1_card,
			"bottom_card": player2_card
		}

# 困难策略：考虑数值和花色
func select_initial_card_hard(player1_card: NiNardCard, player2_card: NiNardCard) -> Dictionary:
	# 如果玩家卡片是高数值，尽量压制
	if player1_card.value >= 4:
		return {
			"top_card": player2_card,
			"bottom_card": player1_card
		}
	# 如果AI卡片是高数值，尽量发挥
	elif player2_card.value >= 4:
		return {
			"top_card": player2_card,
			"bottom_card": player1_card
		}
	# 否则根据花色决定
	elif player1_card.suit == player2_card.suit:
		# 同花色时，数值大的在上
		if player2_card.value > player1_card.value:
			return {
				"top_card": player2_card,
				"bottom_card": player1_card
			}
		else:
			return {
				"top_card": player1_card,
				"bottom_card": player2_card
			}
	else:
		# 不同花色时，AI的卡片在上
		return {
			"top_card": player2_card,
			"bottom_card": player1_card
		}

# 执行AI回合决策
func execute_turn():
	# 获取可用的位置和卡片
	var available_moves = get_available_moves()
	
	# 选择最佳移动
	var best_move = select_best_move(available_moves)
	
	# 执行移动
	if best_move:
		play_card(best_move.card, best_move.position, best_move.orientation)

# 获取所有可能的移动
func get_available_moves() -> Array:
	var moves = []
	var hand = game.player2_hand
	
	# 检查每张卡片
	for card in hand:
		# 检查每个位置
		for y in range(3):
			for x in range(3):
				# 跳过已有卡片的位置
				if game.board[y][x] != null:
					continue
				
				# 添加各个方向的移动
				for orientation in range(4):
					moves.append({
						"card": card,
						"position": Vector2i(x, y),
						"orientation": orientation,
						"score": evaluate_move(card, Vector2i(x, y), orientation)
					})
	
	return moves

# 重新设计的评估函数，更加全面地评估移动价值
func evaluate_move(card: NiNardCard, position: Vector2i, orientation: int) -> float:
	var score = 0.0
	var score_details = {
		"card_value": 0.0,
		"position_value": 0.0,
		"capture_score": 0.0,
		"defense_score": 0.0,
		"sequence_score": 0.0
	}
	score_details["card_value"] = card.value * 0.5
	score += score_details["card_value"]
	# 2. 位置战略价值
	var position_value = 0.0
	if position.x == 1 and position.y == 1:  # 中心
		position_value = 2.0  # 提高中心位置价值
	elif (position.x == 0 or position.x == 2) and (position.y == 0 or position.y == 2):  # 角落
		position_value = 1.5
	else:  # 边缘
		position_value = 1.0
	score += position_value
	score_details["position_value"] = position_value
	
	# 3. 检查全方向的占领可能性
	var directions = [
		Vector2i(-1, 0),  # 上
		Vector2i(0, 1),   # 右
		Vector2i(1, 0),   # 下
		Vector2i(0, -1)   # 左
	]
	
	var capture_score = 0.0
	var capture_details = []
	var original_orientation = card.orientation
	card.orientation = orientation
	
	# 获取当前方向的偏移
	var facing_offset = get_offset_for_orientation(orientation)
	var target_pos = Vector2i(position.x + facing_offset.x, position.y + facing_offset.y)
	
	# 检查目标位置是否在棋盘内
	if target_pos.x >= 0 and target_pos.x < 3 and target_pos.y >= 0 and target_pos.y < 3:
		var target_card = game.board[target_pos.y][target_pos.x]
		
		if target_card != null:
			# 如果是对手卡牌且可以占领，高优先级
			if target_card.card_owner == "player1" and game.can_capture(card, target_card):
				# 根据被占领卡牌的价值加权
				var this_capture_score = target_card.value * 2.0
				capture_score += this_capture_score
				capture_details.append("占领位置[%d,%d]价值%d的卡牌: +%f" % [target_pos.x, target_pos.y, target_card.value, this_capture_score])
				
				# 如果这个卡牌对形成连牌很重要，额外加分
				if is_card_part_of_sequence(target_pos):
					capture_score += 5.0
					capture_details.append("占领的卡牌是连牌关键部分: +5.0")
	
	# 恢复原始方向
	card.orientation = original_orientation
	score += capture_score
	score_details["capture_score"] = capture_score
	
	# 4. 防御评分 - 防止被对手占领
	var defense_score = evaluate_defensive_value(card, position, orientation)
	score += defense_score
	score_details["defense_score"] = defense_score
	
	# 5. 连牌潜力 - 评估放置后形成连牌的可能性
	var sequence_score = evaluate_sequence_potential(card, position)
	score += sequence_score
	score_details["sequence_score"] = sequence_score
	
	# 保存评分细节到卡牌的临时属性
	if !card.has_meta("score_details"):
		card.set_meta("score_details", {})
	card.get_meta("score_details")[str(position) + "_" + str(orientation)] = score_details
	
	if !card.has_meta("capture_details"):
		card.set_meta("capture_details", {})
	card.get_meta("capture_details")[str(position) + "_" + str(orientation)] = capture_details
	
	return score

# 检查位置是否是现有或潜在连牌的一部分
func is_card_part_of_sequence(position: Vector2i) -> bool:
	# 检查所有可能的行、列、对角线
	var lines = []
	
	# 添加水平线
	var row = []
	for x in range(3):
		row.append(Vector2i(x, position.y))
	lines.append(row)
	
	# 添加垂直线
	var col = []
	for y in range(3):
		col.append(Vector2i(position.x, y))
	lines.append(col)
	
	# 如果在对角线上，添加对角线
	if position.x == position.y:  # 主对角线
		var diag1 = []
		for i in range(3):
			diag1.append(Vector2i(i, i))
		lines.append(diag1)
	
	if position.x + position.y == 2:  # 副对角线
		var diag2 = []
		for i in range(3):
			diag2.append(Vector2i(i, 2-i))
		lines.append(diag2)
	
	# 检查每条线是否有连牌潜力
	for line in lines:
		var cards_in_line = []
		var player1_cards = 0
		var player2_cards = 0
		
		for pos in line:
			var card = game.board[pos.y][pos.x]
			if card != null:
				cards_in_line.append(card)
				if card.card_owner == "player1":
					player1_cards += 1
				elif card.card_owner == "player2":
					player2_cards += 1
		
		# 如果这条线已经有两张同一玩家的卡片，说明有连牌潜力
		if player1_cards >= 2 or player2_cards >= 2:
			return true
	
	return false

# 改进的防御评估函数
func evaluate_defensive_value(card: NiNardCard, position: Vector2i, orientation: int) -> float:
	var defense_score = 0.0
	var defense_details = []
	
	# 1. 检查卡牌朝向是否指向空格子（这是好事）
	var facing_offset = get_offset_for_orientation(orientation)
	var facing_pos = Vector2i(position.x + facing_offset.x, position.y + facing_offset.y)
	
	# 如果朝向在棋盘内且是空格子，加分
	if facing_pos.x >= 0 and facing_pos.x < 3 and facing_pos.y >= 0 and facing_pos.y < 3:
		if game.board[facing_pos.y][facing_pos.x] == null:
			defense_score += 2.0  # 朝向空格子，增加得分
			defense_details.append("朝向空格子: +2.0")
		elif game.board[facing_pos.y][facing_pos.x].card_owner == "player1":
			# 检查是否可以占领这个对手卡牌
			var can_capture = game.can_capture(card, game.board[facing_pos.y][facing_pos.x])
			if can_capture:
				defense_score += 3.0  # 降低"朝向可占领的对手卡牌"的权重
				defense_details.append("朝向可占领的对手卡牌: +3.0")
			else:
				defense_score -= 2.0  # 朝向对手卡牌但不能占领，这是风险
				defense_details.append("朝向不能占领的对手卡牌(风险): -2.0")
		else:
			# 朝向自己的卡牌，通常不是好事
			defense_score -= 1.0
			defense_details.append("朝向自己的卡牌: -1.0")
	
	# 2. 检查是否将自己暴露给对手可能的占领
	for dir in [Vector2i(-1, 0), Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1)]:
		var adj_pos = Vector2i(position.x + dir.x, position.y + dir.y)
		
		# 检查相邻位置是否在棋盘内
		if adj_pos.x >= 0 and adj_pos.x < 3 and adj_pos.y >= 0 and adj_pos.y < 3:
			var adj_card = game.board[adj_pos.y][adj_pos.x]
			
			if adj_card != null and adj_card.card_owner == "player1":
				# 检查对手卡牌的朝向是否指向我们的位置
				var opponent_facing = get_offset_for_orientation(adj_card.orientation)
				var opponent_facing_pos = Vector2i(adj_pos.x + opponent_facing.x, adj_pos.y + opponent_facing.y)
				
				if opponent_facing_pos == position:
					# 对手卡牌朝向这个位置，检查是否可以占领我们
					var temp_card = card.duplicate()  # 创建临时副本用于计算
					temp_card.card_owner = "player2"
					temp_card.orientation = orientation
					
					if game.can_capture(adj_card, temp_card):
						# 对手可以占领这个位置，高风险！
						var penalty = card.value * 2.5
						defense_score -= penalty
						defense_details.append("可能被对手卡牌占领(高风险): -%f" % penalty)
	
	# 保存防御评分细节到卡牌的临时属性
	if !card.has_meta("defense_details"):
		card.set_meta("defense_details", {})
	card.get_meta("defense_details")[str(position) + "_" + str(orientation)] = defense_details
	
	return defense_score

# 评估形成连牌(顺子或同花)的潜力
func evaluate_sequence_potential(card: NiNardCard, position: Vector2i) -> float:
	var sequence_score = 0.0
	var sequence_details = []
	
	# 获取该位置所在的所有线(行、列、对角线)
	var lines = []
	
	# 添加该位置所在的行
	var row = []
	for x in range(3):
		row.append(Vector2i(x, position.y))
	lines.append(row)
	
	# 添加该位置所在的列
	var col = []
	for y in range(3):
		col.append(Vector2i(position.x, y))
	lines.append(col)
	
	# 检查是否在对角线上
	if position.x == position.y:  # 主对角线
		var diag1 = []
		for i in range(3):
			diag1.append(Vector2i(i, i))
		lines.append(diag1)
	
	if position.x + position.y == 2:  # 副对角线
		var diag2 = []
		for i in range(3):
			diag2.append(Vector2i(i, 2-i))
		lines.append(diag2)
	
	# 检查每条线的顺子和同花潜力
	for line in lines:
		var cards_on_line = []
		
		# 收集线上的卡牌(包括将要放置的卡牌)
		for pos in line:
			if pos == position:
				cards_on_line.append(card)  # 将要放置的卡牌
			else:
				var existing_card = game.board[pos.y][pos.x]
				if existing_card != null and existing_card.card_owner == "player2":
					cards_on_line.append(existing_card)
		
		# 如果线上有至少2张我方卡牌，计算连牌潜力
		if cards_on_line.size() >= 2:
			# 检查顺子潜力
			var straight_potential = check_straight_potential(cards_on_line)
			if straight_potential > 0:
				sequence_score += straight_potential * 2.0
				sequence_details.append("顺子潜力 %.1f (×2.0): +%.1f" % [straight_potential, straight_potential * 2.0])
			
			# 检查同花潜力
			var flush_potential = check_flush_potential(cards_on_line)
			if flush_potential > 0:
				sequence_score += flush_potential * 2.0
				sequence_details.append("同花潜力 %.1f (×2.0): +%.1f" % [flush_potential, flush_potential * 2.0])
	
	# 保存连牌评分细节到卡牌的临时属性
	if !card.has_meta("sequence_details"):
		card.set_meta("sequence_details", {})
	card.get_meta("sequence_details")[str(position) + "_" + str(card.orientation)] = sequence_details
	
	return sequence_score

# 检查顺子潜力
func check_straight_potential(cards: Array) -> float:
	if cards.size() < 2:
		return 0.0
	
	# 获取卡牌数值
	var values = []
	for card in cards:
		values.append(card.value)
	values.sort()
	
	# 检查是否可能形成顺子
	var max_diff = values[-1] - values[0]
	if max_diff <= 2 and cards.size() == 2:
		return 1.0  # 两张牌，差值不超过2，有可能形成顺子
	elif max_diff == 0 and cards.size() == 2:
		return 0.5  # 两张相同数值的牌，可以与第三张形成顺子的可能性较低
	elif cards.size() == 3 and max_diff == 2 and values[1] - values[0] == 1 and values[2] - values[1] == 1:
		return 3.0  # 已经形成顺子，最高分
	
	return 0.0

# 检查同花潜力
func check_flush_potential(cards: Array) -> float:
	if cards.size() < 2:
		return 0.0
	
	# 检查是否都是同花色
	var first_suit = cards[0].suit
	var same_suit = true
	
	for i in range(1, cards.size()):
		if cards[i].suit != first_suit:
			same_suit = false
			break
	
	if same_suit:
		if cards.size() == 2:
			return 1.0  # 两张同花色，有潜力
		elif cards.size() == 3:
			return 3.0  # 已经形成同花，最高分
	
	return 0.0

# 选择最佳移动
func select_best_move(moves: Array):
	if moves.size() == 0:
		return null
	
	# 根据难度选择不同策略
	var selected_move
	match difficulty:
		Difficulty.EASY:
			# 简单难度：随机选择
			selected_move = moves[randi() % moves.size()]
			print("AI (简单难度): 随机选择移动")
		
		Difficulty.MEDIUM:
			# 中等难度：70%选择较好的移动，30%随机
			if randf() < 0.7:
				# 按分数排序
				moves.sort_custom(Callable(self, "_compare_moves"))
				# 选择前50%的移动
				var top_index = max(0, moves.size() / 2 - 1)
				selected_move = moves[randi() % (top_index + 1)]
				print("AI (中等难度): 从前50%的移动中随机选择")
			else:
				selected_move = moves[randi() % moves.size()]
				print("AI (中等难度): 完全随机选择")
		
		Difficulty.HARD:
			# 困难难度：选择最佳移动
			moves.sort_custom(Callable(self, "_compare_moves"))
			selected_move = moves[0]
			print("AI (困难难度): 选择最佳移动")
	
	# 输出选中移动的详细信息
	print_move_details(selected_move)
	
	return selected_move

# 打印移动的详细评分信息
func print_move_details(move):
	if move == null:
		print("没有可用的移动")
		return
	
	var card = move.card
	var position = move.position
	var orientation = move.orientation
	var score = move.score
	var key = str(position) + "_" + str(orientation)
	
	print("\n==== AI 移动评分详情 ====")
	print("卡牌: %s (数值: %d, 花色: %d)" % [card.card_id, card.value, card.suit])
	print("位置: [%d, %d], 方向: %d" % [position.x, position.y, orientation])
	print("总评分: %.2f" % score)
	
	# 输出评分组成部分
	if card.has_meta("score_details") and card.get_meta("score_details").has(key):
		var details = card.get_meta("score_details")[key]
		print("  卡牌价值: %.2f" % details.card_value)
		print("  位置战略价值: %.2f" % details.position_value)
		print("  占领得分: %.2f" % details.capture_score)
		print("  防御评分: %.2f" % details.defense_score)
		print("  连牌潜力: %.2f" % details.sequence_score)
	
	# 输出占领详情
	if card.has_meta("capture_details") and card.get_meta("capture_details").has(key):
		var capture_details = card.get_meta("capture_details")[key]
		if capture_details.size() > 0:
			print("占领详情:")
			for detail in capture_details:
				print("  * " + detail)
	
	# 输出防御详情
	if card.has_meta("defense_details") and card.get_meta("defense_details").has(key):
		var defense_details = card.get_meta("defense_details")[key]
		if defense_details.size() > 0:
			print("防御详情:")
			for detail in defense_details:
				print("  * " + detail)
	
	print("=======================\n")

# 获取方向对应的偏移
func get_offset_for_orientation(orientation: int) -> Vector2i:
	match orientation:
		0: # UP
			return Vector2i(-1, 0)
		1: # RIGHT
			return Vector2i(0, 1)
		2: # DOWN
			return Vector2i(1, 0)
		3: # LEFT
			return Vector2i(0, -1)
	return Vector2i(0, 0)

# 执行卡片放置
func play_card(card: NiNardCard, position: Vector2i, orientation: int):
	# 调用游戏逻辑中的放置卡片函数
	game.place_card("player2", card, position, orientation)

# 用于排序的比较函数
func _compare_moves(a, b) -> bool:
	return a.score > b.score
