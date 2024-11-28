class_name Inventory
extends Node

# 背包基础属性
var capacity: int = 0
var items: Array = []


# 溢出区（临时背包）
var overflow_items: Array = []

# 初始化背包
func _init(initial_capacity: int = 0) -> void:
	capacity = initial_capacity

# 添加物品到背包
func add_item(item_id: String) -> bool:
	if not DataManager.item_exists(item_id):
		print("Inventory add_item 物品不存在 , item_id: ", item_id)
		return false
		
	if can_add_item(item_id):
		items.append(item_id)
		return true
	return false

# 添加物品到溢出区
func add_to_overflow(item_id: String) -> bool:
	if not DataManager.item_exists(item_id):
		print("Inventory add_to_overflow 物品不存在 , item_id: ", item_id)
		return false
		
	overflow_items.append(item_id)
	return true

# 检查是否可以添加物品
func can_add_item(item_id: String) -> bool:
	var item_size = DataManager.get_item_size(item_id)
	return get_used_capacity() + item_size <= capacity

# 移除物品
func remove_item(item_id: String):
	items.erase(item_id)

# 从溢出区移除物品
func remove_from_overflow(item_id: String):
	overflow_items.erase(item_id)

# 获取已使用容量
func get_used_capacity() -> int:
	var used = 0
	for item_id in items:
		used += DataManager.get_item_size(item_id)
	return used

# 获取剩余容量
func get_remaining_capacity() -> int:
	return capacity - get_used_capacity()

# 检查背包是否已满
func is_full() -> bool:
	return get_remaining_capacity() <= 0

# 尝试将溢出区的物品移动到主背包
func try_move_from_overflow(item_id: String) -> bool:
	if not overflow_items.has(item_id):
		return false
		
	if can_add_item(item_id):
		overflow_items.erase(item_id)
		items.append(item_id)
		return true
	return false

# 获取所有物品列表
func get_all_items() -> Array:
	return items.duplicate()

# 获取溢出区物品列表
func get_overflow_items() -> Array:
	return overflow_items.duplicate()

# 检查物品是否在背包中
func has_item(item_id: String) -> bool:
	return items.has(item_id)

# 检查物品是否在溢出区
func has_item_in_overflow(item_id: String) -> bool:
	return overflow_items.has(item_id)