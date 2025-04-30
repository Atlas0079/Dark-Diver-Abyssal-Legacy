# InitialChoicePanel.gd
extends Control

# 当玩家做出选择后发出信号
# 参数: top_card (NiNardCard) - 玩家选择放在上面的牌
# 参数: bottom_card (NiNardCard) - 另一张牌
signal initial_choice_made(top_card, bottom_card)

# 内部节点引用 (请确保你的场景中的节点名称匹配)
@onready var card1_container = $Panel/Card1Container # 第一个卡牌容器
@onready var card2_container = $Panel/Card2Container # 第二个卡牌容器
@onready var confirm_button = $Panel/Button         # 确认按钮
@onready var info_label = $Panel/InfoLabel        # (可选) 显示提示信息的标签

# 状态变量
var initial_cards: Array[NiNardCard] = []
var selected_initial_card: NiNardCard = null

func _ready():
	# 初始状态下隐藏面板
	visible = false
	# 初始禁用确认按钮
	if confirm_button:
		confirm_button.disabled = true
		confirm_button.pressed.connect(_on_confirm_pressed)
	else:
		push_error("未找到确认按钮 'Panel/Button'")

	if not card1_container or not card2_container:
		push_error("未找到卡牌容器 'Panel/Card1Container' 或 'Panel/Card2Container'")

	if info_label:
		info_label.text = "请选择一张卡牌作为顶牌" # 初始提示

# 公开方法：显示选择面板并设置卡牌
func show_choice(player1_card: NiNardCard, player2_card: NiNardCard):
	if not card1_container or not card2_container:
		push_error("卡牌容器无效，无法显示选择")
		return

	# 存储卡牌
	initial_cards = [player1_card, player2_card]
	selected_initial_card = null

	# 清理旧卡牌和连接
	_clear_container(card1_container)
	_clear_container(card2_container)

	# 添加新卡牌
	_setup_card(player1_card, card1_container, "player1")
	_setup_card(player2_card, card2_container, "player2")

	# 重置按钮和状态
	if confirm_button:
		confirm_button.disabled = true
	if info_label:
		info_label.text = "请选择一张卡牌作为顶牌"

	# 显示面板
	visible = true

# 清理卡牌容器
func _clear_container(container: Node):
	for child in container.get_children():
		if child is NiNardCard:
			# 断开可能存在的旧连接
			if child.is_connected("card_clicked", _on_card_clicked):
				child.disconnect("card_clicked", _on_card_clicked)
		child.queue_free()

# 设置单个卡牌
func _setup_card(card: NiNardCard, container: Node, owner: String):
	if card.get_parent():
		card.get_parent().remove_child(card)

	container.add_child(card)

	card.card_owner = owner
	card.card_owner_sprite.visible = false # 初始选择时不显示归属
	card.set_selectable(true)
	card.scale = Vector2(0.4, 0.4) # 保持一致的缩放
	# 确保卡牌在容器内居中 (假设容器是 Control 类型)
	if container is Control:
		card.position = container.size / 2.0
	card.modulate = Color(1, 1, 1, 1) # 重置高亮
	card.update_visuals()

	# 连接点击信号
	card.card_clicked.connect(_on_card_clicked)


# 处理卡牌点击事件
func _on_card_clicked(card: NiNardCard, _is_on_board: bool):
	# 重置所有卡牌的高亮
	for c in initial_cards:
		if c is NiNardCard:
			c.modulate = Color(1, 1, 1, 1)

	# 设置选中的卡牌并高亮
	selected_initial_card = card
	card.modulate = Color(1.2, 1.2, 1.2, 1.0)

	# 启用确认按钮
	if confirm_button:
		confirm_button.disabled = false

	# 更新提示信息 (可选)
	if info_label:
		if card.card_owner == "player1":
			info_label.text = "已选择玩家1的卡牌，点击确认"
		else:
			info_label.text = "已选择玩家2的卡牌，点击确认"


# 处理确认按钮点击事件
func _on_confirm_pressed():
	if selected_initial_card == null:
		push_warning("确认按钮被点击，但没有选中的初始卡牌")
		return

	# 确定顶牌和底牌
	var top_card: NiNardCard
	var bottom_card: NiNardCard

	if selected_initial_card == initial_cards[0]: # 假设 player1 的牌总是在 index 0
		top_card = initial_cards[0]
		bottom_card = initial_cards[1]
	else:
		top_card = initial_cards[1]
		bottom_card = initial_cards[0]

	# 重置所有卡牌的高亮
	for c in initial_cards:
		if c is NiNardCard:
			c.modulate = Color(1, 1, 1, 1)

	# 发出信号通知主UI
	emit_signal("initial_choice_made", top_card, bottom_card)

	# 隐藏面板
	visible = false
	# 可以在这里考虑 queue_free() 如果这个面板只使用一次
	# queue_free()
