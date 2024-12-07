extends Node2D

var dungeon_generator: DungeonBasicLayoutGenerator
var cell_size: int = 20  # 每个格子的像素大小

# 颜色映射
const DEBUG_COLORS = {
	DungeonBasicLayoutGenerator.RoomType.EMPTY: Color.DARK_GRAY,
	DungeonBasicLayoutGenerator.RoomType.ZONE: Color(0, 0, 1, 0.2),
	DungeonBasicLayoutGenerator.RoomType.SETTLEMENT: Color.RED,
	DungeonBasicLayoutGenerator.RoomType.ROOM: Color.GREEN,
	DungeonBasicLayoutGenerator.RoomType.PATH: Color.YELLOW
}

func _ready():
	dungeon_generator = DungeonBasicLayoutGenerator.new()
	dungeon_generator.initialize_with_seed(randi())
	_generate_and_visualize()

func _generate_and_visualize():
	dungeon_generator.dungeon_grid = dungeon_generator.generate_dungeon(randi())
	queue_redraw()

func _draw():
	# 计算总大小
	var width = dungeon_generator.config.width * cell_size
	var height = dungeon_generator.config.height * cell_size
	
	# 绘制背景网格
	for x in range(dungeon_generator.config.width + 1):
		var start = Vector2(x * cell_size, 0)
		var end = Vector2(x * cell_size, height)
		draw_line(start, end, Color.DARK_GRAY, 1.0)
	
	for y in range(dungeon_generator.config.height + 1):
		var start = Vector2(0, y * cell_size)
		var end = Vector2(width, y * cell_size)
		draw_line(start, end, Color.DARK_GRAY, 1.0)
	
	# 绘制区域边界
	var zone_size = dungeon_generator.config.zone_size * cell_size
	for x in range(0, width + 1, zone_size):
		draw_line(Vector2(x, 0), Vector2(x, height), Color.BLUE, 2.0)
	for y in range(0, height + 1, zone_size):
		draw_line(Vector2(0, y), Vector2(width, y), Color.BLUE, 2.0)
	
	# 绘制地牢内容
	if dungeon_generator.dungeon_grid.size() > 0:
		for x in range(dungeon_generator.config.width):
			for y in range(dungeon_generator.config.height):
				var room_type = dungeon_generator.dungeon_grid[x][y]
				if room_type != DungeonBasicLayoutGenerator.RoomType.EMPTY:
					var rect = Rect2(x * cell_size, y * cell_size, cell_size, cell_size)
					draw_rect(rect, DEBUG_COLORS[room_type], true)

# 重新生成按钮回调
func _on_regenerate_button_pressed():
	dungeon_generator.initialize_with_seed(randi())
	_generate_and_visualize()

# 处理输入
func _unhandled_input(event):
	if event.is_action_pressed("ui_accept"):  # 空格键
		_on_regenerate_button_pressed()
