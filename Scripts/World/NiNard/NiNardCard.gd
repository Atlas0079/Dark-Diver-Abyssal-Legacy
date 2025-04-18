class_name NiNardCard
extends Node2D

enum Orientation {UP, RIGHT, DOWN, LEFT}
enum Suit {SPADE, HEART, DIAMOND, CLUB}

signal card_clicked(card, is_on_board)
signal direction_selected(card, direction)
signal cancel_selected(card)

@export var value: int = 1
@export var suit: Suit = Suit.SPADE
@export var orientation = Orientation.UP

@export var card_owner: String = ""
@export var card_id: String = ""
@export var card_name: String = ""
@export var card_description: String = ""
@export var score: int = 1  # 保留得分属性，但不再显示

@onready var card_sprite = $CardSprite
@onready var value_label = $ValueLabel
@onready var suit_sprite = $SuitSprite
#@onready var owner_indicator = $OwnerIndicator
#@onready var direction_indicator = $DirectionIndicator
@onready var direction_arrow = $DirectionArrows
@onready var card_owner_sprite = $CardOwnerSprite
@onready var click_button = $ClickButton  # 引用新添加的按钮

var is_selectable = false
var is_on_board = false  # 新增属性，标记卡牌是否在场上
var original_position = Vector2.ZERO

func _ready(): 
	direction_arrow.visible = false
	card_owner_sprite.visible = false
	# 更新卡牌视觉效果
	update_visuals()
	
	# 连接按钮信号而不是Area2D
	click_button.pressed.connect(_on_button_pressed)
	
	# 连接方向按钮信号
	$DirectionArrows/UpButton.pressed.connect(_on_up_button_pressed)
	$DirectionArrows/RightButton.pressed.connect(_on_right_button_pressed)
	$DirectionArrows/DownButton.pressed.connect(_on_down_button_pressed)
	$DirectionArrows/LeftButton.pressed.connect(_on_left_button_pressed)
	$DirectionArrows/CancelButton.pressed.connect(_on_cancel_button_pressed)

func update_visuals():
	# 更新数值文本
	value_label.text = str(value)
	
	
	# 更新花色图标
	match suit:
		Suit.SPADE:
			suit_sprite.texture = preload("res://Assets/NiNard/Spade.png")
		Suit.HEART:
			suit_sprite.texture = preload("res://Assets/NiNard/Heart.png")
		Suit.DIAMOND:
			suit_sprite.texture = preload("res://Assets/NiNard/Diamond.png")
		Suit.CLUB:
			suit_sprite.texture = preload("res://Assets/NiNard/Club.png")
	
	# 更新所有者标识
	if card_owner == "player1":
		card_owner_sprite.texture = preload("res://Assets/NiNard/OwnerWhite.png") 
		card_owner_sprite.visible = true
	elif card_owner == "player2":
		card_owner_sprite.texture = preload("res://Assets/NiNard/OwnerBlack.png")
		card_owner_sprite.visible = true
	else:
		card_owner_sprite.visible = false
	
	# 更新方向指示器
	match orientation:
		Orientation.UP:
			direction_arrow.rotation = 0
		Orientation.RIGHT:
			direction_arrow.rotation = PI/2
		Orientation.DOWN:
			direction_arrow.rotation = PI
		Orientation.LEFT:
			direction_arrow.rotation = 3*PI/2

func set_selectable(selectable: bool):
	is_selectable = selectable
	# 同时设置按钮的禁用状态
	if click_button:
		click_button.disabled = !selectable

func show_direction_selection():
	direction_arrow.visible = true
	click_button.visible = false
	click_button.disabled = true
	
	# 确保所有方向按钮的z_index高于卡片
	for button in direction_arrow.get_children():
		if button is TextureButton:
			button.z_index = 10
			# 确保按钮是可交互的
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.disabled = false
	
	# 将整个方向箭头控件提到前面
	direction_arrow.z_index = 10
	
	# 打印调试信息
	#print("显示方向选择，按钮状态：")
	for button_name in ["UpButton", "RightButton", "DownButton", "LeftButton", "CancelButton"]:
		var button = direction_arrow.get_node(button_name)
		if button:
			#print(button_name + " 可见: " + str(button.visible) + ", 禁用: " + str(button.disabled))
			pass

func hide_direction_selection():
	direction_arrow.visible = false
	# 恢复卡片点击按钮
	if is_selectable:
		click_button.visible = true

# 新的按钮点击处理函数
func _on_button_pressed():
	if is_selectable:
		print("card clicked: " + card_owner + ", value: " + str(value) + ", selectable: " + str(is_selectable) + ", on board: " + str(is_on_board))
		emit_signal("card_clicked", self, is_on_board)

func _input(event):
	pass

func on_direction_selected(dir: int):
	print("direction selected: " + str(dir))
	orientation = Orientation.values()[dir]  # 显式转换整数为枚举
	update_visuals()
	emit_signal("direction_selected", self, dir)
	hide_direction_selection()

func on_cancel_selected():
	emit_signal("cancel_selected", self)
	hide_direction_selection()

func _on_up_button_pressed():
	print("上箭头按钮被点击")
	on_direction_selected(0)

func _on_right_button_pressed():
	print("右箭头按钮被点击")
	on_direction_selected(1)

func _on_down_button_pressed():
	print("下箭头按钮被点击")
	on_direction_selected(2)

func _on_left_button_pressed():
	print("左箭头按钮被点击")
	on_direction_selected(3)

func _on_cancel_button_pressed():
	print("取消按钮被点击")
	on_cancel_selected()
