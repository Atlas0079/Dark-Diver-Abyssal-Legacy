class_name Item
extends Resource

# 基础属性
var item_id: String
var custom_name: String = ""
var durability: int = 100
var stack_count: int = 1
var size: int = 1

# 自定义属性
var custom_attributes: Dictionary = {}

func _init(p_item_id: String) -> void:
	item_id = p_item_id
	
# 从模板数据初始化
func init_from_template() -> void:
	var template = DataManager.get_item_data(item_id)
	if template.is_empty():
		push_error("Invalid item id: " + item_id)
		return
		
	# 初始化基础属性
	if not custom_name:
		custom_name = template.get("name", "未知物品")

# 获取物品名称
func get_item_name() -> String:
	return custom_name if custom_name else DataManager.get_item_data(item_id).get("name", "未知物品")

# 获取物品描述
func get_item_description() -> String:
	var base_desc = DataManager.get_item_data(item_id).get("description", "")
	var custom_desc = ""
	
	# 添加自定义属性描述
	if not custom_attributes.is_empty():
		custom_desc = "\n属性："
		for attr in custom_attributes:
			custom_desc += "\n- " + attr + ": " + str(custom_attributes[attr])
	
	return base_desc + custom_desc

# 获取物品类型
func get_type() -> String:
	return DataManager.get_item_data(item_id).get("item_type", "")

# 获取物品价值
func get_value() -> int:
	return DataManager.get_item_data(item_id).get("item_value", 0)

# 获取属性加成
func get_attribute_boosts() -> Dictionary:
	return custom_attributes

# 获取物品大小
func get_size() -> int:
	return size

# 是否可堆叠
func is_stackable() -> bool:
	return DataManager.get_item_data(item_id).get("stackable", false)

# 获取最大堆叠数
func get_max_stack() -> int:
	return DataManager.get_item_data(item_id).get("max_stack", 1)

# 尝试堆叠物品
func try_stack_with(other_item: Item) -> bool:
	if not is_stackable() or item_id != other_item.item_id:
		return false
	
	var max_stack = get_max_stack()
	if stack_count >= max_stack:
		return false
		
	var space_left = max_stack - stack_count
	var amount_to_stack = min(space_left, other_item.stack_count)
	
	stack_count += amount_to_stack
	other_item.stack_count -= amount_to_stack
	
	return true

# 序列化物品数据
func serialize() -> Dictionary:
	return {
		"item_id": item_id,
		"custom_name": custom_name,
		"durability": durability,
		"stack_count": stack_count,
		"size": size,
		"custom_attributes": custom_attributes
	}

# 从序列化数据恢复
func deserialize(data: Dictionary) -> void:
	item_id = data.get("item_id", item_id)
	custom_name = data.get("custom_name", custom_name)
	durability = data.get("durability", durability)
	stack_count = data.get("stack_count", stack_count)
	size = data.get("size", size)
	custom_attributes = data.get("custom_attributes", {})
