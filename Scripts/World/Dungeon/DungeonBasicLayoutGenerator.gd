class_name DungeonBasicLayoutGenerator
extends Node

const DIRECTIONS = {
	"UP": Vector2i(0, -1),
	"DOWN": Vector2i(0, 1),
	"LEFT": Vector2i(-1, 0),
	"RIGHT": Vector2i(1, 0)
}

var room_grid: Array = []
var grid_size: Vector2i = Vector2i(20, 20)
var rng = RandomNumberGenerator.new()

# 配置参数
var config = {
	"width": 16,
	"height": 16,
	"zone_size": 4,
	"zone_amount": 5,
	"min_cluster_distance": 3,
	"max_cluster_room_amount": 9,
	"min_cluster_room_amount": 5,
	"growth_bias": 2.0
}

# 添加成员变量存储生成结果
var selected_zones: Array = []
var settlements: Array = []

# 房间类型枚举
enum RoomType {
	EMPTY = 0,
	ZONE = 1,
	SETTLEMENT = 2,
	ROOM = 3,
	PATH = 4
}

var dungeon_grid: Array = []  # 存储实际的地牢格子类型

# 添加新的成员变量
var settlement_zones: Dictionary = {}  # 存储聚落中心及其所属区域
var settlement_rooms: Dictionary = {}  # 存储每个聚落的所有房间

# 新增简化的房间类型枚举
enum BasicRoomType {
	EMPTY = 0,
	ROOM = 1  # 这里只区分有房间和没房间
}

class Cluster:
	var center: Vector2i
	var rooms: Array[Vector2i]
	var type: String
	
	func _init(pos: Vector2i, cluster_type: String):
		center = pos
		rooms = []
		type = cluster_type

# 使用种子初始化随机数生成器
func initialize_with_seed(seed_value: int):
	rng.seed = seed_value

# 初始化网格
func _initialize_grid():
	room_grid.clear()
	for x in range(grid_size.x):
		var column = []
		column.resize(grid_size.y)
		for y in range(grid_size.y):
			column[y] = " "  # 空位置用空格表示
		room_grid.append(column)

# 自定义数组随机打乱函数
func _shuffle_array(array: Array) -> Array:
	var shuffled = array.duplicate()
	var n = shuffled.size()
	for i in range(n - 1, 0, -1):
		var j = rng.randi() % (i + 1)
		var temp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = temp
	return shuffled

# 获取邻居数量
func _get_neighbor_count(pos: Vector2i, selected_zones: Array) -> int:
	var count = 0
	var neighbors = [
		Vector2i(0, 1), Vector2i(0, -1), 
		Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(1, 1), Vector2i(1, -1),
		Vector2i(-1, 1), Vector2i(-1, -1)
	]
	
	for offset in neighbors:
		var new_pos = pos + offset
		if selected_zones.has(new_pos):
			count += 1
	return count

# 生成区域和聚落
func generate_zones_and_settlements() -> Array:
	var zones_x = config.width / config.zone_size
	var zones_y = config.height / config.zone_size
	
	# 从中心开始
	var center = Vector2i(zones_x / 2, zones_y / 2)
	selected_zones = [center]  # 使用成员变量
	
	# 区域生长
	for i in range(config.zone_amount - 1):
		var new_zones = []
		var neighbors = [Vector2i(0, 1), Vector2i(0, -1), 
						Vector2i(1, 0), Vector2i(-1, 0)]
		
		for zone in selected_zones:
			for offset in neighbors:
				var new_pos = zone + offset
				if (new_pos.x >= 0 and new_pos.x < zones_x and 
					new_pos.y >= 0 and new_pos.y < zones_y and 
					not selected_zones.has(new_pos)):
					var neighbor_count = _get_neighbor_count(new_pos, selected_zones)
					var weight = pow(neighbor_count + 1, config.growth_bias)
					new_zones.append({"pos": new_pos, "weight": weight})
		
		if new_zones.size() > 0:
			# 根据权重随机选择
			var total_weight = 0
			for zone in new_zones:
				total_weight += zone.weight
			
			var random_value = rng.randf() * total_weight
			var current_weight = 0
			
			for zone in new_zones:
				current_weight += zone.weight
				if current_weight >= random_value:
					selected_zones.append(zone.pos)
					break
	
	# 在选中的区域中放置聚落
	settlements = []
	settlement_zones.clear()
	for zone in selected_zones:
		var attempts = 0
		var max_attempts = 100
		
		while attempts < max_attempts:
			var settlement_x = rng.randi_range(
				zone.x * config.zone_size, 
				(zone.x + 1) * config.zone_size - 1
			)
			var settlement_y = rng.randi_range(
				zone.y * config.zone_size, 
				(zone.y + 1) * config.zone_size - 1
			)
			var settlement_pos = Vector2i(settlement_x, settlement_y)
			
			var valid_position = true
			for existing_settlement in settlements:
				var distance = abs(settlement_pos.x - existing_settlement.x) + \
							  abs(settlement_pos.y - existing_settlement.y)
				if distance < config.min_cluster_distance:
					valid_position = false
					break
			
			if valid_position:
				settlements.append(settlement_pos)
				settlement_zones[settlement_pos] = zone  # 记录聚落所属的区域
				settlement_rooms[settlement_pos] = []    # 初始化聚落的房间列表
				break
			
			attempts += 1
	
	return [selected_zones, settlements]

# 初始化地牢网格
func _initialize_dungeon_grid():
	dungeon_grid.clear()
	for x in range(config.width):
		var column = []
		column.resize(config.height)
		for y in range(config.height):
			column[y] = RoomType.EMPTY
		dungeon_grid.append(column)

# 生成房间
func generate_rooms(settlements: Array) -> void:
	for settlement in settlements:
		# 标记聚落中心
		dungeon_grid[settlement.x][settlement.y] = RoomType.SETTLEMENT
		settlement_rooms[settlement] = [settlement]  # 将中心添加到房间列表
		
		var rooms = [settlement]  # 当前聚落的所有房间
		var room_amount = rng.randi_range(
			config.min_cluster_room_amount,
			config.max_cluster_room_amount
		)
		
		# 房间生长过程
		for i in range(room_amount):
			var candidates = []
			for room in rooms:
				for dir in DIRECTIONS.values():
					var new_pos = room + dir
					if _is_valid_room_position(new_pos) and \
					   dungeon_grid[new_pos.x][new_pos.y] == RoomType.EMPTY:
						var neighbor_count = _count_room_neighbors(new_pos)
						candidates.append({"pos": new_pos, "weight": neighbor_count + 1})
			
			if candidates.size() > 0:
				var chosen = _weighted_choice(candidates)
				rooms.append(chosen)
				dungeon_grid[chosen.x][chosen.y] = RoomType.ROOM
				settlement_rooms[settlement].append(chosen)  # 将新房间添加到聚落的房间列表

# 辅助函数：检查位置是否有效
func _is_valid_room_position(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < config.width and \
		   pos.y >= 0 and pos.y < config.height

# 辅助函数：计算周围的房间数量
func _count_room_neighbors(pos: Vector2i) -> int:
	var count = 0
	for dir in DIRECTIONS.values():
		var check_pos = pos + dir
		if _is_valid_room_position(check_pos) and \
		   (dungeon_grid[check_pos.x][check_pos.y] == RoomType.ROOM or \
			dungeon_grid[check_pos.x][check_pos.y] == RoomType.SETTLEMENT):
			count += 1
	return count

# 辅助函数：根据权重随机选择
func _weighted_choice(candidates: Array) -> Vector2i:
	var total_weight = 0
	for candidate in candidates:
		total_weight += candidate.weight
	
	var random_value = rng.randf() * total_weight
	var current_weight = 0
	
	for candidate in candidates:
		current_weight += candidate.weight
		if current_weight >= random_value:
			return candidate.pos
	
	return candidates[0].pos  # 防止意外情况

# 连接相邻区域的房间
func connect_adjacent_zones(selected_zones: Array) -> void:
	# 检查每对聚落
	for i in range(settlements.size()):
		var settlement1 = settlements[i]
		var zone1 = settlement_zones[settlement1]
		
		for j in range(i + 1, settlements.size()):
			var settlement2 = settlements[j]
			var zone2 = settlement_zones[settlement2]
			
			# 检查聚落是否属于相邻区域
			if _are_zones_adjacent(zone1, zone2):
				# 获取两个聚落的所有房间
				var rooms1 = settlement_rooms[settlement1]
				var rooms2 = settlement_rooms[settlement2]
				
				# 如果房间群未连通，则建立连接
				if not _are_rooms_connected(rooms1, rooms2):
					_connect_zones(rooms1, rooms2)

# 获取每个区域包含的所有房间
func _get_zone_rooms() -> Dictionary:
	var zone_rooms = {}
	
	# 遍历所有格子
	for x in range(config.width):
		for y in range(config.height):
			if dungeon_grid[x][y] in [RoomType.ROOM, RoomType.SETTLEMENT]:
				var pos = Vector2i(x, y)
				var zone = Vector2i(x / config.zone_size, y / config.zone_size)
				if not zone_rooms.has(zone):
					zone_rooms[zone] = []
				zone_rooms[zone].append(pos)
	
	return zone_rooms

# 检查两个区域是否相邻
func _are_zones_adjacent(zone1: Vector2i, zone2: Vector2i) -> bool:
	return (abs(zone1.x - zone2.x) + abs(zone1.y - zone2.y)) == 1

# 检查两组房间是否已经连通
func _are_rooms_connected(rooms1: Array, rooms2: Array) -> bool:
	var visited = {}
	var queue = []
	
	# 标记第一组房间为已访问
	for room in rooms1:
		visited[room] = true
		queue.append(room)
	
	# BFS搜索
	while queue.size() > 0:
		var current = queue.pop_front()
		
		# 如果到达第二组中的任意房间，说明已连通
		if rooms2.has(current):
			return true
		
		# 检查四个方向的相邻格子
		for dir in DIRECTIONS.values():
			var next_pos = current + dir
			if _is_valid_room_position(next_pos) and \
			   not visited.has(next_pos) and \
			   dungeon_grid[next_pos.x][next_pos.y] in [RoomType.ROOM, RoomType.SETTLEMENT]:
				visited[next_pos] = true
				queue.append(next_pos)
	
	return false

# 连接两组房间
func _connect_zones(rooms1: Array, rooms2: Array) -> void:
	var best_pair = _find_closest_room_pair(rooms1, rooms2)
	var start = best_pair[0]
	var end = best_pair[1]
	
	# 在两个房间之间创建路径
	var path = _find_path(start, end)
	if path != null:
		for pos in path:
			if dungeon_grid[pos.x][pos.y] == RoomType.EMPTY:
				dungeon_grid[pos.x][pos.y] = RoomType.PATH

# 找到两组房间之间距离最短的一对
func _find_closest_room_pair(rooms1: Array, rooms2: Array) -> Array:
	var min_distance = INF
	var best_pair = [null, null]
	
	for room1 in rooms1:
		for room2 in rooms2:
			var distance = abs(room1.x - room2.x) + abs(room1.y - room2.y)
			if distance < min_distance:
				min_distance = distance
				best_pair = [room1, room2]
	
	return best_pair

# A*寻路算法
func _find_path(start: Vector2i, end: Vector2i) -> Array:
	var frontier = []
	frontier.append({"pos": start, "priority": 0})
	var came_from = {start: null}
	var cost_so_far = {start: 0}
	
	while frontier.size() > 0:
		frontier.sort_custom(func(a, b): return a.priority < b.priority)
		var current = frontier.pop_front().pos
		
		if current == end:
			break
		
		for dir in DIRECTIONS.values():
			var next_pos = current + dir
			if not _is_valid_room_position(next_pos):
				continue
				
			var new_cost = cost_so_far[current] + 1
			if not cost_so_far.has(next_pos) or new_cost < cost_so_far[next_pos]:
				cost_so_far[next_pos] = new_cost
				var priority = new_cost + abs(end.x - next_pos.x) + abs(end.y - next_pos.y)
				frontier.append({"pos": next_pos, "priority": priority})
				came_from[next_pos] = current
	
	# 重建路径
	if not came_from.has(end):
		return []
		
	var path = []
	var current = end
	while current != start:
		path.append(current)
		current = came_from[current]
	path.reverse()
	return path

# 保留原来的生成函数，但重命名为 generate_dungeon
func generate_dungeon(seed_value: int, custom_config: Dictionary = {}) -> Array:
	# 1. 配置初始化
	for key in custom_config:
		config[key] = custom_config[key]
	
	# 2. 初始化随机数生成器
	initialize_with_seed(seed_value)
	
	# 3. 初始化地牢网格
	_initialize_dungeon_grid()
	
	# 4. 生成区域和聚落
	var generation_result = generate_zones_and_settlements()
	var zones = generation_result[0]
	var settlements_list = generation_result[1]
	
	# 5. 生成房间
	generate_rooms(settlements_list)
	
	# 6. 连接区域
	connect_adjacent_zones(zones)
	
	# 7. 返回生成结果
	return dungeon_grid

# 修改 generate_basic_layout 函数，让它使用 dungeon_grid
func generate_basic_layout(seed_value: int, custom_config: Dictionary = {}) -> Array:
	# 先使用详细生成
	var detailed_layout = generate_dungeon(seed_value, custom_config)
	
	# 转换为简化的布局并存储到 dungeon_grid
	var basic_layout = []
	dungeon_grid.clear()  # 清空现有数据
	for x in range(config.width):
		var column = []
		var dungeon_column = []
		column.resize(config.height)
		dungeon_column.resize(config.height)
		for y in range(config.height):
			var is_room = detailed_layout[x][y] != RoomType.EMPTY
			column[y] = BasicRoomType.ROOM if is_room else BasicRoomType.EMPTY
			dungeon_column[y] = column[y]  # 保存相同的值到 dungeon_grid
		basic_layout.append(column)
		dungeon_grid.append(dungeon_column)
	
	return basic_layout
