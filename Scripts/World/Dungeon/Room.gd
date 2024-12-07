class_name DungeonRoom
extends Node

enum RoomType {
	NORMAL,
	CORRIDOR,
	TELEPORT
}
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

var room_type: RoomType
var room_generate_type: RoomGenerateType  

var discover_level: int
var room_loot_multiplier: float = 1.0

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

# 获取指定方向的通道
func get_passage(direction: Vector2i) -> DungeonPassage:
	return passages.get(direction)

# 设置通道
func set_passage(direction: Vector2i, passage: DungeonPassage) -> void:
	passages[direction] = passage


