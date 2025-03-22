class_name DungeonRoom
extends Node

enum RoomGenerateType {
	EMPTY = 0,
	ZONE = 1,
	SETTLEMENT = 2,
	ROOM = 3,
	PATH = 4
}

# 房间基础属性
var room_id: String
var room_name: String
var tags: Array = []
var level_descriptions: Dictionary = {
	0: "",  
	1: "",  
	2: "",  
	3: ""   
}
var room_position: Vector2i
var room_generate_type: RoomGenerateType  

# 房间特殊属性
var is_unique: bool = false
var min_passages: int = 1
var max_passages: int = 4
var required_passage_type: String = ""
var min_distance: Dictionary = {}
var room_loot_multiplier: float = 1.0
var exploration_level	
# 房间内容
var included_teams: Array = []
var included_items: Array = []
var interactive_objects: Array = []

# 存储四个方向的通道
var passages: Dictionary = {
	Vector2i(0, -1): null,  # 上
	Vector2i(0, 1): null,   # 下
	Vector2i(-1, 0): null,  # 左
	Vector2i(1, 0): null    # 右
}

# 初始化房间
func init_from_template(template: Dictionary, position: Vector2i) -> void:
	# 基础属性初始化
	room_id = template.get("id", "")
	room_name = template.get("name", "未命名房间")
	tags = template.get("tags", [])
	room_position = position
	
	# 特殊属性初始化
	is_unique = template.get("unique", false)
	min_passages = template.get("min_passages", 1)
	max_passages = template.get("max_passages", 4)
	required_passage_type = template.get("required_passage_type", "")
	min_distance = template.get("min_distance", {})
	room_loot_multiplier = template.get("room_loot_multiplier", 1.0)
	

	
	# 初始化描述
	_init_descriptions(template)

# 初始化房间描述
func _init_descriptions(template: Dictionary) -> void:
	var base_description = template.get("description", "一个普通的房间")
	level_descriptions = {
		0: "未探索的房间",
		1: base_description,
		2: base_description + "\n这个房间似乎还有更多秘密...",
		3: base_description + "\n你已经完全了解了这个房间的构造。"
	}

# 获取指定方向的通道
func get_passage(direction: Vector2i) -> DungeonPassage:
	return passages.get(direction)

# 设置通道
func set_passage(direction: Vector2i, passage: DungeonPassage) -> void:
	passages[direction] = passage

# 获取房间的所有有效通道
func get_valid_passages() -> Array:
	var valid_passages = []
	for direction in passages.keys():
		if passages[direction] != null:
			valid_passages.append(passages[direction])
	return valid_passages

# 获取房间的相邻位置
func get_adjacent_positions() -> Array[Vector2i]:
	var positions: Array[Vector2i] = []
	for direction in passages.keys():
		positions.append(room_position + direction)
	return positions
