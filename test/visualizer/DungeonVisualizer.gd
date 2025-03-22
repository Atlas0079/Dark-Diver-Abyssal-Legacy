extends Node2D

var dungeon_generator: DungeonBasicLayoutGenerator
var passage_generator: DungeonPassageGenerator
var cell_size: int = 20  # 每个格子的基础像素大小
var zoom_level: float = 1.0  # 缩放级别
var connections: Array[DungeonPassageGenerator.ConnectionInfo] = []

# 颜色映射
const DEBUG_COLORS = {
	DungeonBasicLayoutGenerator.RoomType.EMPTY: Color.DARK_GRAY,
	DungeonBasicLayoutGenerator.RoomType.ZONE: Color(0, 0, 1, 0.2),
	DungeonBasicLayoutGenerator.RoomType.SETTLEMENT: Color.RED,
	DungeonBasicLayoutGenerator.RoomType.ROOM: Color.GREEN,
	DungeonBasicLayoutGenerator.RoomType.PATH: Color.YELLOW
}

# 通道颜色映射
const PASSAGE_COLORS = {
	"normal": Color.WHITE,  # 普通双向通道
	"one_way": Color.ORANGE,  # 单向通道
	"main": Color(0, 1, 0, 0.8),  # 主要通道
	"branch": Color(1, 1, 0, 0.8)  # 分支通道
}

func _ready():
	dungeon_generator = DungeonBasicLayoutGenerator.new()
	passage_generator = DungeonPassageGenerator.new(RandomUtils.new())
	dungeon_generator.initialize_with_seed(randi())
	
	# 创建UI控件
	_setup_ui()
	
	_generate_and_visualize()

func _setup_ui():
	# 创建缩放滑块
	var zoom_slider = HSlider.new()
	zoom_slider.min_value = 0.5
	zoom_slider.max_value = 3.0
	zoom_slider.step = 0.1
	zoom_slider.value = 1.0
	zoom_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	zoom_slider.custom_minimum_size = Vector2(200, 20)
	
	# 创建标签
	var label = Label.new()
	label.text = "Zoom"
	
	# 创建水平容器
	var hbox = HBoxContainer.new()
	hbox.add_child(label)
	hbox.add_child(zoom_slider)
	
	# 创建控制面板容器
	var control_panel = PanelContainer.new()
	control_panel.add_child(hbox)
	control_panel.position = Vector2(10, 10)
	
	add_child(control_panel)
	
	# 连接信号
	zoom_slider.value_changed.connect(_on_zoom_changed)

func _on_zoom_changed(value: float):
	zoom_level = value
	queue_redraw()

func _generate_and_visualize():
	# 生成基础地牢布局
	dungeon_generator.dungeon_grid = dungeon_generator.generate_dungeon(randi())
	
	# 生成通道连接
	var params = {
		"bend_factor": 0.3,
		"multi_path_factor": 0.7,
		"direction_factor": 0.2
	}
	connections = passage_generator.generate_dungeon_passages(
		dungeon_generator.dungeon_grid,
		randi(),
		params
	)
	
	queue_redraw()

func _draw():
	# 计算实际单元格大小
	var actual_cell_size = cell_size * zoom_level
	
	# 计算总大小
	var width = dungeon_generator.config.width * actual_cell_size
	var height = dungeon_generator.config.height * actual_cell_size
	
	# 绘制背景网格
	_draw_grid(width, height, actual_cell_size)
	
	# 绘制区域边界
	_draw_zone_boundaries(width, height, actual_cell_size)
	
	# 绘制地牢内容
	_draw_dungeon_content(actual_cell_size)
	
	# 绘制通道连接
	_draw_passages(actual_cell_size)

func _draw_grid(width: float, height: float, actual_cell_size: float) -> void:
	for x in range(dungeon_generator.config.width + 1):
		var start = Vector2(x * actual_cell_size, 0)
		var end = Vector2(x * actual_cell_size, height)
		draw_line(start, end, Color.DARK_GRAY, 1.0)
	
	for y in range(dungeon_generator.config.height + 1):
		var start = Vector2(0, y * actual_cell_size)
		var end = Vector2(width, y * actual_cell_size)
		draw_line(start, end, Color.DARK_GRAY, 1.0)

func _draw_zone_boundaries(width: float, height: float, actual_cell_size: float) -> void:
	var zone_size = dungeon_generator.config.zone_size * actual_cell_size
	for x in range(0, width + 1, zone_size):
		draw_line(Vector2(x, 0), Vector2(x, height), Color.BLUE, 2.0)
	for y in range(0, height + 1, zone_size):
		draw_line(Vector2(0, y), Vector2(width, y), Color.BLUE, 2.0)

func _draw_dungeon_content(actual_cell_size: float) -> void:
	if dungeon_generator.dungeon_grid.size() > 0:
		for x in range(dungeon_generator.config.width):
			for y in range(dungeon_generator.config.height):
				var room_type = dungeon_generator.dungeon_grid[x][y]
				if room_type != DungeonBasicLayoutGenerator.RoomType.EMPTY:
					var rect = Rect2(x * actual_cell_size, y * actual_cell_size, 
								   actual_cell_size, actual_cell_size)
					draw_rect(rect, DEBUG_COLORS[room_type], true)

func _draw_passages(actual_cell_size: float) -> void:
	for conn in connections:
		var start = Vector2(conn.from_pos.x * actual_cell_size + actual_cell_size/2, 
						   conn.from_pos.y * actual_cell_size + actual_cell_size/2)
		var end = Vector2(conn.to_pos.x * actual_cell_size + actual_cell_size/2, 
						 conn.to_pos.y * actual_cell_size + actual_cell_size/2)
		
		# 选择通道颜色
		var line_color = PASSAGE_COLORS.normal
		if conn.is_one_way:
			line_color = PASSAGE_COLORS.one_way
		
		# 绘制通道线条
		draw_line(start, end, line_color, 2.0 * zoom_level)  # 线宽也随缩放调整
		
		# 如果是单向通道，绘制箭头
		if conn.is_one_way:
			_draw_arrow(end, conn.direction, line_color, actual_cell_size)

func _draw_arrow(pos: Vector2, direction: Vector2i, color: Color, actual_cell_size: float) -> void:
	var arrow_size = actual_cell_size * 0.3
	var dir = Vector2(direction.x, direction.y).normalized()
	var right = dir.rotated(PI * 0.75) * arrow_size
	var left = dir.rotated(-PI * 0.75) * arrow_size
	var points = PackedVector2Array([pos, pos + right, pos + left])
	draw_colored_polygon(points, color)

func _on_regenerate_button_pressed():
	dungeon_generator.initialize_with_seed(randi())
	_generate_and_visualize()

func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):  # 空格键
		_on_regenerate_button_pressed()
