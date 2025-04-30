# TutorialPanel.gd
extends Control

# 内部节点引用 (请确保你的教程场景中的节点名称匹配)
@onready var page_container = $Page  # 假设包含所有页面的容器节点叫 "Page"
@onready var next_button = $NextButton
@onready var previous_button = $PreviousButton
@onready var close_button = $CloseButton
@onready var page_count_label = $PageCount # 假设显示页码的 Label 叫 "PageCount"

# 状态变量
var current_page = 1
var total_pages = 1 # 默认值，将在 _ready 中计算

# 预加载资源
var glass_shader = preload("res://Scripts/Shader/glass_effect.gdshader")

func _ready():
	# --- 基本设置 ---
	# 确保阻挡鼠标事件传递到下方游戏UI
	mouse_filter = Control.MOUSE_FILTER_STOP
	# 确保教程在最上层 (也可以在 NiNardUI 中设置)
	z_index = 100

	# --- 页面计算 ---
	if page_container:
		total_pages = page_container.get_child_count()
	else:
		push_error("教程场景中未找到页面容器节点 'Page'")
		total_pages = 1 # 避免除零错误

	current_page = 1 # 确保从第一页开始

	# --- 连接内部按钮信号 ---
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
	else:
		push_error("教程场景中未找到 'NextButton'")

	if previous_button:
		previous_button.pressed.connect(_on_previous_pressed)
	else:
		push_error("教程场景中未找到 'PreviousButton'")

	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	else:
		push_error("教程场景中未找到 'CloseButton'")

	# --- 初始化视觉 ---
	apply_glass_effect(self) # 应用毛玻璃效果
	update_page_display() # 显示第一页和页码

func apply_glass_effect(panel):
	# 创建着色器材质
	var shader_material = ShaderMaterial.new()
	shader_material.shader = glass_shader

	# 创建一个背景层
	var background = ColorRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE # 允许点击穿透到面板本身(如果需要)
	background.material = shader_material

	# 将背景层添加到面板的最底层
	panel.add_child(background)
	panel.move_child(background, 0)

	# 轻微调整面板背景透明度 (可选)
	# panel.self_modulate = Color(1, 1, 1, 0.95)

func update_page_display():
	if not page_container or not page_count_label:
		return

	# 隐藏所有页面
	for i in range(total_pages):
		var page_node = page_container.get_child(i)
		if page_node: # 添加检查确保节点有效
			page_node.visible = false

	# 显示当前页面
	if current_page > 0 and current_page <= total_pages:
		var current_page_node = page_container.get_child(current_page - 1)
		if current_page_node:
			current_page_node.visible = true
	else:
		push_warning("无效的教程页码: " + str(current_page))
		# 可以选择显示第一页作为后备
		if total_pages > 0:
			page_container.get_child(0).visible = true

	# 更新页码显示
	page_count_label.text = "第 %d / %d 页" % [current_page, total_pages]

	# 更新按钮状态 (可选，如果不需要循环翻页)
	# previous_button.disabled = (current_page == 1)
	# next_button.disabled = (current_page == total_pages)

func _on_next_pressed():
	if current_page < total_pages:
		current_page += 1
	else:
		current_page = 1 # 循环到第一页
	update_page_display()

func _on_previous_pressed():
	if current_page > 1:
		current_page -= 1
	else:
		current_page = total_pages # 循环到最后一页
	update_page_display()

func _on_close_pressed():
	# 关闭教程面板 (自身)
	queue_free()
