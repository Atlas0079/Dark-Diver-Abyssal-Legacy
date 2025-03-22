class_name DungeonPassage
extends Node

var passage_id: String = ""
var passage_name: String = ""
var description: String = ""
var tags: Array = []
var keys: Array = []
var lockable: bool = false

# 位置相关
var from_pos: Vector2i
var to_pos: Vector2i
var direction: Vector2i
var is_one_way: bool = false

# 门的实例（如果有的话）
var door: DungeonDoor = null

func _init(template_data: Dictionary, connection_data: Dictionary):
	# 从模板数据初始化基本属性
	passage_id = template_data.get("id", "")
	passage_name = template_data.get("name", "")
	description = template_data.get("description", "")
	tags = template_data.get("tag", [])
	keys = template_data.get("key", [])
	lockable = template_data.get("lockable", false)
	
	# 从连接数据初始化位置属性
	from_pos = connection_data.get("from_pos", Vector2i())
	to_pos = connection_data.get("to_pos", Vector2i())
	direction = connection_data.get("direction", Vector2i())
	is_one_way = connection_data.get("is_one_way", false)

# 添加门
func add_door(door_template: Dictionary) -> void:
	door = DungeonDoor.new(door_template, self)

# 检查是否有门
func has_door() -> bool:
	return door != null

# 获取门实例
func get_door() -> DungeonDoor:
	return door
