class_name DungeonDoor
extends Node

var door_id: String = ""
var door_name: String = ""
var description: String = ""
var tags: Array = []
var sturdy_value
var lockable: bool = false

# 门的状态
var is_locked: bool = false
var is_open: bool = false

# 所属的通道引用
var passage: DungeonPassage

func _init(template_data: Dictionary, parent_passage: DungeonPassage):
	passage = parent_passage
	
	# 从模板数据初始化属性
	door_id = template_data.get("id", "")
	door_name = template_data.get("name", "")
	sturdy_value = template_data.get("sturdy_value", "")
	description = template_data.get("description", "")
	tags = template_data.get("tag", [])
	lockable = template_data.get("lockable", false)
	
	# 初始状态：关闭，默认不上锁
	is_open = false
	is_locked = false

# 开门
func open() -> bool:
	if is_locked:
		return false
	is_open = true
	return true

# 关门
func close() -> void:
	is_open = false

# 上锁
func lock() -> bool:
	if not lockable:
		return false
	is_locked = true
	return true

# 解锁
func unlock() -> bool:
	if not lockable:
		return false
	is_locked = false
	return true

# 检查是否可以通过
func can_pass() -> bool:
	return is_open and not is_locked
