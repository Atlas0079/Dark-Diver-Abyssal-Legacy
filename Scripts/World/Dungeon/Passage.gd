class_name DungeonPassage
extends Node

enum PassageType {
	OPEN,           # 开放式通道
	DOOR,           # 普通门
	ONE_WAY_DOOR,   # 单向门
	LOCKED_DOOR,    # 上锁的门
	HIDDEN_DOOR,    # 隐藏门
	BLOCKED,        # 被阻塞的通道
}

var passage_id: String
var passage_type: PassageType
var description: String
var tags: Array = []

# 通道连接的两个房间
var room_from: DungeonRoom  # 起始房间
var room_to: DungeonRoom    # 目标房间
var direction: Vector2i     # 方向向量

# 通道特殊属性
var is_locked: bool = false
var key_id: String = ""     # 如果需要钥匙，存储钥匙ID
var is_hidden: bool = false
var is_one_way: bool = false

func can_pass_through(from_room: DungeonRoom) -> bool:
	if is_locked:
		return false
	if is_one_way:
		return from_room == room_from
	return true
