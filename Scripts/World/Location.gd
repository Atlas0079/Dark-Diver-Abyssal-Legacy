class_name Location
extends Resource

# 基本信息
var id: String
var name: String
var description: String
var location_type: String  # indoor/outdoor
var area_size: Vector2  # 场景大小

# 场景特性
var features = {
	"interactables": [],  # 可交互物品
	"npcs": [],          # 场景中的NPC
	"shops": [],         # 商店
	"quest_givers": []   # 任务发放者
}

# 连接信息 - 改为更灵活的结构
var connections: Array[Dictionary] = []  # 存储所有连接

# 进入条件
var entry_requirements = {
	"items": [],    # 需要的物品（比如钥匙）
	"quests": [],   # 需要完成的任务
	"level": 0,     # 需要的等级
	"time": null    # 开放时间限制
}

# 场景状态
var current_state = {
	"weather": "normal",     # 天气状态
	"time_of_day": "day",    # 时间段
	"is_accessible": true,   # 是否可进入
	"active_events": []      # 当前激活的事件
}

# 初始化场景
func init_from_data(location_data: Dictionary) -> void:
	id = location_data.get("id", "")
	name = location_data.get("name", "")
	description = location_data.get("description", "")
	location_type = location_data.get("type", "indoor")
	area_size = location_data.get("size", Vector2(10, 10))
	
	# 初始化特性
	if location_data.has("features"):
		features = location_data.features
	
	# 初始化连接
	if location_data.has("connections"):
		connections = location_data.connections
		
	# 初始化进入条件
	if location_data.has("requirements"):
		entry_requirements = location_data.requirements

# 添加连接
func add_connection(target_id: String, path_type: String = "normal", distance: float = 1.0, 
		requirements: Dictionary = {}) -> void:
	var new_connection = {
		"target": target_id,
		"path_type": path_type,  # 路径类型：normal, hidden, locked等
		"distance": distance,     # 路径距离
		"requirements": requirements  # 通过这个路径的特殊要求
	}
	connections.append(new_connection)

# 移除连接
func remove_connection(target_id: String) -> void:
	for i in range(connections.size() - 1, -1, -1):
		if connections[i].target == target_id:
			connections.remove_at(i)

# 获取所有可用连接
func get_available_connections(character: Character = null) -> Array:
	var available = []
	for connection in connections:
		if character == null or can_use_connection(connection, character):
			available.append(connection)
	return available

# 检查是否可以使用特定连接
func can_use_connection(connection: Dictionary, character: Character) -> bool:
	# 检查路径要求
	var reqs = connection.get("requirements", {})
	
	# 检查物品需求
	if reqs.has("items"):
		for required_item_id in reqs.items:
			var found = false
			for item in character.inventory.items:
				if item.item_id == required_item_id:
					found = true
					break
			if not found:
				return false
	
	# 检查任务需求
	if reqs.has("quests"):
		for quest_id in reqs.quests:
			if not character.completed_quests.has(quest_id):
				return false
	
	# 检查等级需求
	if reqs.has("level") and character.level < reqs.level:
		return false
	
	# 检查时间要求
	#if reqs.has("time_range"):
		# 假设有个全局时间系统
		#var current_time = Time.get_current_time()
		#if not is_time_in_range(current_time, reqs.time_range):
		#	return false
	
	return true

# 获取到指定位置的路径信息
func get_connection_to(target_id: String) -> Dictionary:
	for connection in connections:
		if connection.target == target_id:
			return connection
	return {}

# 检查是否有直接连接到目标位置
func has_connection_to(target_id: String) -> bool:
	for connection in connections:
		if connection.target == target_id:
			return true
	return false
