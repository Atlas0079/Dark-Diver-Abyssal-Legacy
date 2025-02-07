# item_editor.gd
class_name ItemEditor
extends Control

# 预加载场景
const AttributeRangeScene = preload("res://Dataset/Editor/AttributeRange.tscn")
const AttributeNormalScene = preload("res://Dataset/Editor/AttributeNormal.tscn")

var item_data: Dictionary

var current_type: EditType

enum EditType {
	ITEMEQUIPMENT = 0,
	ITEMMISC = 1,
	ITEMCONSUMABLE = 2,
	SKILL = 3,
	TEAM = 4,
}

var current_item_id: String

@onready var item_list: ItemList = $ItemList
@onready var element_container: Panel

# 定义属性类型枚举
enum EquipmentAttributeType {
	NORMAL,  # 普通属性 (单个数值)
	RANGE,   # 范围属性 (最大最小值)
}

# 属性分类
const Equipment_RANGE_ATTRIBUTES = ["physical_attack", "magical_attack", "physical_defense", "magical_defense"]
const Equipment_NORMAL_ATTRIBUTES = ["strength", "dexterity", "intelligence", "max_health"]



func _ready():
	item_data = DataManager.get_item_data_all()
	# 不需要手动连接信号，可以直接使用编辑器中的信号连接
	# 或者使用这种方式连接：
	$EditType.item_selected.connect(_on_option_selected)

func _on_option_selected(index: String):
	# 删除 Panel 下的所有子节点
	for child in element_container.get_children():
		child.queue_free()

	if current_type == EditType.ITEMEQUIPMENT:  
		# 加载并实例化新场景
		var new_scene = load("res://Dataset/Editor/item_equpment.tscn").instantiate()
		element_container.add_child(new_scene)
	
	# 更新物品列表
	update_item_list()

func update_item_list():
	item_list.clear()
	# 遍历 item_data，根据 equipment_type 筛选
	for item_id in item_data:
		if item_id.begins_with("I1") and item_data[item_id].get("equipment_type") == current_type:
			item_list.add_item(item_data[item_id]["name"])
			# 存储 item_id 作为 metadata，方便之后获取详细信息
			item_list.set_item_metadata(item_list.get_item_count() - 1, item_id)
