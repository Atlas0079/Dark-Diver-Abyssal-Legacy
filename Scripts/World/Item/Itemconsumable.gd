class_name Consumable
extends Item

# 消耗品特有属性
var category: String  # food/potion
var use_type: String  # all_time/battle/non_battle
var effects: Dictionary = {}

func _init(p_item_id: String) -> void:
	super(p_item_id)
	
# 重写初始化方法，添加消耗品特有的初始化逻辑
func init_from_template() -> void:
	super.init_from_template()
	var template = DataManager.get_item_data(item_id)
	
	category = template.get("category", "")
	use_type = template.get("use_type", "")
	effects = template.get("effects", {})

# 使用物品
func use(target: Character) -> bool:
	if effects.is_empty():
		return false
		
	match effects.get("type"):
		"heal":
			target.heal(effects.get("value", 0))
		"gain_energy":
			target.gain_energy(effects.get("value", 0))
		_:
			return false
	
	return true

# 获取使用类型
func get_use_type() -> String:
	return use_type

# 获取物品类别
func get_category() -> String:
	return category
