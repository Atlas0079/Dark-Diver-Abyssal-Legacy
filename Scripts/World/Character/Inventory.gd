class_name Inventory
extends Node

# 背包基础属性
var capacity: int = 0
var items: Array[Item] = []


# 溢出区（临时背包）
var overflow_items: Array[Item] = []

# 初始化背包
func _init(initial_capacity: int = 0) -> void:
	capacity = initial_capacity

# 添加物品到背包
func add_item(item: Item) -> bool:
	# 先尝试堆叠
	if item.is_stackable():
		for existing_item in items:
			if existing_item.try_stack_with(item):
				if item.stack_count <= 0:
					return true
	
	# 如果还有剩余物品且有空间，添加为新物品
	if can_add_item(item):
		items.append(item)
		return true
	return false

# 添加物品到溢出区
func add_to_overflow(item: Item) -> bool:
	overflow_items.append(item)
	return true

# 检查是否可以添加物品
func can_add_item(item: Item) -> bool:
	var future_used_capacity = get_used_capacity() + item.get_size()
	return future_used_capacity <= capacity

# 移除物品
func remove_item(item: Item):
	items.erase(item)

# 从溢出区移除物品
func remove_from_overflow(item: Item):
	overflow_items.erase(item)

# 获取已使用容量
func get_used_capacity() -> int:
	var used = 0
	for item in items:
		used += item.get_size()
	return used

# 获取剩余容量
func get_remaining_capacity() -> int:
	return capacity - get_used_capacity()

# 检查背包是否已满
func is_full() -> bool:
	return get_remaining_capacity() <= 0

# 尝试将溢出区的物品移动到主背包
func try_move_from_overflow(item: Item) -> bool:
	if not overflow_items.has(item):
		return false
		
	if can_add_item(item):
		overflow_items.erase(item)
		items.append(item)
		return true
	return false

# 获取所有物品列表
func get_all_items() -> Array:
	return items.duplicate()

# 获取溢出区物品列表
func get_overflow_items() -> Array:
	return overflow_items.duplicate()

# 检查物品是否在背包中
func has_item(item: Item) -> bool:
	return items.has(item)

# 检查物品是否在溢出区
func has_item_in_overflow(item: Item) -> bool:
	return overflow_items.has(item)

# 通过ID查找物品
func find_item_by_id(item_id: String) -> Item:
	for item in items:
		if item.item_id == item_id:
			return item
	return null

# 通过ID和数量创建并添加物品
func add_item_by_id(item_id: String, amount: int = 1) -> bool:
	var item = DataManager.create_item(item_id)
	if item == null:
		return false
	
	item.stack_count = amount
	return add_item(item)