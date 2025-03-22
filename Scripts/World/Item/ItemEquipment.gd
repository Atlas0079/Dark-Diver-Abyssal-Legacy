class_name Equipment
extends Item

# 装备特有属性
var equipment_type: String  # weapon/armor/accessory
var tags: Array = []  # 改为数组，可以包含多个标签如 ["melee", "magic"]
var special_skills: Array = []
var attribute_ranges: Dictionary = {}  # 存储属性的范围值

func _init(p_item_id: String) -> void:
	super(p_item_id)

# 重写初始化方法，添加装备特有的初始化逻辑
func init_from_template() -> void:
	super.init_from_template()
	var template = DataManager.get_item_data(item_id)
	
	equipment_type = template.get("equipment_type", "")
	tags = template.get("tags", [])  # 获取tags数组
	special_skills = template.get("special_skill", [])
	
	# 初始化属性范围
	var boosts = template.get("attribute_boosts", {})
	for attr in boosts:
		if boosts[attr] is Dictionary:  # 如果是范围值
			attribute_ranges[attr] = {
				"min": boosts[attr].get("min", 0),
				"max": boosts[attr].get("max", 0)
			}
		else:  # 如果是固定值
			custom_attributes[attr] = boosts[attr]

# 获取特殊技能列表
func get_special_skills() -> Array[String]:
	return special_skills

# 获取装备类型
func get_equipment_type() -> String:
	return equipment_type

# 获取装备标签列表
func get_equipment_tags() -> Array[String]:
	return tags

# 检查是否包含特定标签
func has_tag(tag: String) -> bool:
	return tag in tags

# 获取属性加成范围
func get_attribute_ranges() -> Dictionary:
	return attribute_ranges

# 计算当前回合的属性加成
func calculate_current_attributes() -> Dictionary:
	var current_boosts = {}
	
	# 遍历所有属性范围
	for attr in attribute_ranges:
		var range_data = attribute_ranges[attr]
		var random_value = randf_range(range_data.min, range_data.max)
		current_boosts[attr] = random_value
	
	# 合并固定属性加成
	for attr in custom_attributes:
		current_boosts[attr] = custom_attributes[attr]
		
	return current_boosts



# 序列化装备数据（重写父类方法）
func serialize() -> Dictionary:
	var data = super.serialize()
	data["equipment_type"] = equipment_type
	data["tags"] = tags  # 更新序列化
	data["special_skills"] = special_skills
	data["attribute_ranges"] = attribute_ranges
	return data

# 从序列化数据恢复（重写父类方法）
func deserialize(data: Dictionary) -> void:
	super.deserialize(data)
	equipment_type = data.get("equipment_type", equipment_type)
	tags = data.get("tags", tags)  # 更新反序列化
	special_skills = data.get("special_skills", special_skills)
	attribute_ranges = data.get("attribute_ranges", attribute_ranges)
