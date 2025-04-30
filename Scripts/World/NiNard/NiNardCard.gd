class_name NiNardCard
extends Node2D

enum Orientation {UP, RIGHT, DOWN, LEFT}
enum Suit {SPADE, HEART, DIAMOND, CLUB}

signal card_clicked(card, is_on_board)

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
@onready var card_owner_sprite = $CardOwnerSprite
@onready var click_button = $ClickButton  # 引用新添加的按钮
@onready var glow_sprite = $GlowSprite    # 引用辉光精灵

var is_selectable = false
var is_on_board = false  # 新增属性，标记卡牌是否在场上
var original_position = Vector2.ZERO # 这个变量似乎未使用，可以考虑移除或另作他用
var original_hand_position: Vector2 = Vector2.ZERO # 新增：存储在手牌中的原始相对位置
var is_in_straight: bool = false # 卡片是否处于顺子中
var is_in_flush: bool = false    # 卡片是否处于同花中

func _ready(): 
	card_owner_sprite.visible = false
	
	# 初始化辉光精灵
	if glow_sprite:
		glow_sprite.visible = false    # 默认隐藏辉光

		
		# 由于辉光贴图尺寸比卡片大（每边多45像素），确保它位于卡片的正中心
		# 辉光和卡片已经在场景中居中对齐，无需额外偏移
		# 如果需要调整，可以在这里设置 glow_sprite.position
	
	# 更新卡牌视觉效果
	update_visuals()
	
	# 连接按钮信号而不是Area2D
	click_button.pressed.connect(_on_button_pressed)

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
	
	# 更新辉光效果
	if glow_sprite:
		# 根据顺子/同花状态设置辉光颜色
		if is_in_straight and is_in_flush:
			glow_sprite.modulate = Color(0.7, 0, 0.7, 1.0) # 紫色辉光
			glow_sprite.visible = true
		elif is_in_straight:
			glow_sprite.modulate = Color(0, 0.7, 0, 1.0)   # 绿色辉光
			glow_sprite.visible = true
		elif is_in_flush:
			glow_sprite.modulate = Color(0, 0, 0.7, 1.0)   # 蓝色辉光
			glow_sprite.visible = true
		else:
			glow_sprite.visible = false  # 如果不在顺子也不在同花中，隐藏辉光

func set_selectable(selectable: bool):
	is_selectable = selectable
	# 同时设置按钮的禁用状态
	if click_button:
		click_button.disabled = !selectable

func _on_button_pressed():
	if is_selectable:
		emit_signal("card_clicked", self, is_on_board)
