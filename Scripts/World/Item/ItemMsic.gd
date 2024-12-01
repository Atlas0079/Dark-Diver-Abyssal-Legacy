class_name MiscItem
extends Item

# 杂项物品特有属性
var category: String  # 制作材料/情报物品/钥匙/收藏品
var tags: Array[String] = []

func _init(p_item_id: String) -> void:
	super(p_item_id)

# 重写初始化方法，添加杂项物品特有的初始化逻辑
func init_from_template() -> void:
	super.init_from_template()
	var template = DataManager.get_item_data(item_id)
	
	category = template.get("category", "")
	tags = template.get("tags", [])

# 获取物品类别
func get_category() -> String:
	return category

# 获取物品标签
func get_tags() -> Array[String]:
	return tags
