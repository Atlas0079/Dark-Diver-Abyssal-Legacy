class_name DungeonPassageGenerator
extends Node

var rng: RandomUtils

func _init(random_utils: RandomUtils):
	rng = random_utils

# 存储第一阶段生成的连接信息
class ConnectionInfo:
	var from_pos: Vector2i
	var to_pos: Vector2i
	var direction: Vector2i
	var is_one_way: bool
	
	func _init(f: Vector2i, t: Vector2i, d: Vector2i):
		from_pos = f
		to_pos = t
		direction = d
		is_one_way = false
	
	func duplicate() -> ConnectionInfo:
		var new_conn = ConnectionInfo.new(from_pos, to_pos, direction)
		new_conn.is_one_way = is_one_way
		return new_conn

# 获取所有房间位置
func _get_room_positions(basic_layout: Array) -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for i in range(basic_layout.size()):
		for j in range(basic_layout[i].size()):
			if basic_layout[i][j]:
				positions.append(Vector2i(i, j))
	return positions

# 使用Floyd-Warshall算法检查强连通性
func _is_strongly_connected(connections: Array[ConnectionInfo], room_positions: Array[Vector2i]) -> bool:
	var n = room_positions.size()
	var pos_to_index = {}
	
	# 建立位置到索引的映射
	for i in range(n):
		pos_to_index[room_positions[i]] = i
	
	# 初始化可达性矩阵
	var reachable = []
	for i in range(n):
		reachable.append([])
		for j in range(n):
			reachable[i].append(false)
		# 自己到自己永远可达
		reachable[i][i] = true
	
	# 设置直接连接
	for conn in connections:
		var from_idx = pos_to_index[conn.from_pos]
		var to_idx = pos_to_index[conn.to_pos]
		reachable[from_idx][to_idx] = true
		if not conn.is_one_way:
			reachable[to_idx][from_idx] = true
	
	# Floyd-Warshall算法
	for k in range(n):
		for i in range(n):
			for j in range(n):
				if reachable[i][k] and reachable[k][j]:
					reachable[i][j] = true
	
	# 检查是否所有点对都互相可达
	for i in range(n):
		for j in range(n):
			if not reachable[i][j]:
				return false
	
	return true

# 创建最小生成树，确保基本连通性
func _create_minimum_spanning_tree(connections: Array[ConnectionInfo], room_positions: Array[Vector2i]) -> Array[ConnectionInfo]:
	var mst: Array[ConnectionInfo] = []
	var connected_rooms = {}
	
	# 初始化第一个房间
	if room_positions.size() > 0:
		connected_rooms[room_positions[0]] = true
	
	# Kruskal算法变体
	while connected_rooms.size() < room_positions.size():
		var best_connection: ConnectionInfo = null
		
		for conn in connections:
			var from_connected = connected_rooms.has(conn.from_pos)
			var to_connected = connected_rooms.has(conn.to_pos)
			
			# 如果这个连接能连接一个新房间
			if (from_connected and not to_connected) or (not from_connected and to_connected):
				best_connection = conn
				break
		
		if best_connection != null:
			mst.append(best_connection)
			connected_rooms[best_connection.from_pos] = true
			connected_rooms[best_connection.to_pos] = true
		else:
			break
	
	return mst

# 添加额外的连接以增加多样性
func _add_extra_connections(mst: Array[ConnectionInfo], all_connections: Array[ConnectionInfo], 
						   room_positions: Array[Vector2i], params: Dictionary) -> Array[ConnectionInfo]:
	var result = mst.duplicate()
	var multi_path_factor = params.get("multi_path_factor", 0.7)
	
	# 随机添加额外的连接
	for conn in all_connections:
		if conn not in result and rng.randf() < multi_path_factor:
			result.append(conn)
	
	return result

# 处理连接的方向性
func _process_directions(connections: Array[ConnectionInfo], room_positions: Array[Vector2i], params: Dictionary) -> Array[ConnectionInfo]:
	var direction_factor = params.get("direction_factor", 0.2)
	var result: Array[ConnectionInfo] = []
	
	# 确保MST部分的连接保持双向
	var essential_connections = connections.slice(0, room_positions.size() - 1)
	for conn in essential_connections:
		var new_conn = conn.duplicate()
		new_conn.is_one_way = false
		result.append(new_conn)
	
	# 处理其余连接的方向性
	for i in range(room_positions.size() - 1, connections.size()):
		var conn = connections[i]
		var new_conn = conn.duplicate()
		
		if rng.randf() < direction_factor:
			# 随机选择方向
			if rng.randf() < 0.5:
				new_conn.is_one_way = true
			else:
				# 反转方向
				var temp = new_conn.from_pos
				new_conn.from_pos = new_conn.to_pos
				new_conn.to_pos = temp
				new_conn.direction = -new_conn.direction
				new_conn.is_one_way = true
		
		result.append(new_conn)
	
	return result

# 随机化连接布局
func randomize_connections(connections: Array[ConnectionInfo], room_positions: Array[Vector2i], params: Dictionary) -> Array[ConnectionInfo]:
	# 1. 首先创建一个最小生成树，确保基本连通性
	var mst_connections = _create_minimum_spanning_tree(connections, room_positions)
	
	# 2. 添加额外的连接以增加多样性
	var extra_connections = _add_extra_connections(mst_connections, connections, room_positions, params)
	
	# 3. 处理方向性
	var final_connections = _process_directions(extra_connections, room_positions, params)
	
	assert(_is_strongly_connected(final_connections, room_positions), "Generated layout is not strongly connected!")
	return final_connections

# 为相邻房间生成连接
func generate_basic_connections(basic_layout: Array) -> Array[ConnectionInfo]:
	var connections: Array[ConnectionInfo] = []
	
	# 遍历所有房间位置
	for i in range(basic_layout.size()):
		for j in range(basic_layout[i].size()):
			if not basic_layout[i][j]:
				continue
			
			var current_pos = Vector2i(i, j)
			
			# 检查右侧相邻房间
			if j + 1 < basic_layout[i].size() and basic_layout[i][j + 1]:
				var connection = ConnectionInfo.new(
					current_pos,
					Vector2i(i, j + 1),
					Vector2i(0, 1)
				)
				connections.append(connection)
			
			# 检查下方相邻房间
			if i + 1 < basic_layout.size() and basic_layout[i + 1][j]:
				var connection = ConnectionInfo.new(
					current_pos,
					Vector2i(i + 1, j),
					Vector2i(1, 0)
				)
				connections.append(connection)
	
	return connections

# 生成随机化的地牢通道
func generate_dungeon_passages(basic_layout: Array, seed_value: int, config: Dictionary = {}) -> Array[ConnectionInfo]:
	# 初始化随机数生成器
	rng.initialize_with_seed(seed_value)
	
	# 获取所有房间位置
	var room_positions = _get_room_positions(basic_layout)
	
	# 生成基础连接
	var base_connections = generate_basic_connections(basic_layout)
	
	# 设置默认配置参数
	var final_config = {
		"bend_factor": 0.3,
		"multi_path_factor": 0.7,
		"direction_factor": 0.2
	}
	
	# 更新配置参数
	for key in config:
		final_config[key] = config[key]
	
	# 随机化连接
	var randomized_connections = randomize_connections(
		base_connections,
		room_positions,
		final_config
	)
	
	return randomized_connections
