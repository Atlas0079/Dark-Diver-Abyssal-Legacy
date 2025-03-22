class_name Dungeon
extends Node

# 地下城基础属性
var dungeon_id: String
var current_month: int
var is_initialized: bool = false

# 区域管理
var areas: Dictionary = {}  # 键：区域ID，值：Area实例
var discovered_areas: Dictionary = {}  # 已发现的区域

# 资源状态追踪
var area_resource_states: Dictionary = {
	"loot_remaining": {},  # 区域剩余资源量
	"explored_by_others": {}  # 其他冒险者探索状态
}

# 初始化地下城
func initialize(month: int) -> void:
	if is_initialized and current_month == month:
		return
		
	current_month = month
	is_initialized = true
	
	# 清理旧数据
	areas.clear()
	discovered_areas.clear()
	area_resource_states.clear()
	
	# 从模板生成区域
	_generate_areas()
	
	# 初始化资源状态
	_initialize_resource_states()

# 从模板生成区域
func _generate_areas() -> void:
	var area_templates = DataManager.get_all_area_templates()
	
	for template_id in area_templates:
		var template = area_templates[template_id]
		var new_area = DungeonArea.new()
		new_area.initialize_from_template(template)
		areas[template.id] = new_area

# 初始化区域资源状态
func _initialize_resource_states() -> void:
	for area_id in areas:
		area_resource_states.loot_remaining[area_id] = 1.0
		area_resource_states.explored_by_others[area_id] = false

# 获取区域资源状态
func get_area_resource_state(area_id: String) -> float:
	return area_resource_states.loot_remaining.get(area_id, 0.0)

# 更新区域资源状态
func update_area_resource_state(area_id: String, amount: float) -> void:
	if area_resource_states.loot_remaining.has(area_id):
		area_resource_states.loot_remaining[area_id] = clamp(
			area_resource_states.loot_remaining[area_id] - amount, 
			0.0, 
			1.0
		)

# 标记区域被其他冒险者探索
func mark_area_explored_by_others(area_id: String) -> void:
	area_resource_states.explored_by_others[area_id] = true
	# 探索后资源减少
	update_area_resource_state(area_id, 0.3)  # 减少30%资源

# 保存地下城状态
func save_state() -> Dictionary:
	var save_data = {
		"dungeon_id": dungeon_id,
		"current_month": current_month,
		"areas": {},
		"resource_states": area_resource_states
	}
	
	# 保存每个区域的状态
	for area_id in areas:
		save_data.areas[area_id] = areas[area_id].save_state()
	
	return save_data

# 加载地下城状态
func load_state(data: Dictionary) -> void:
	dungeon_id = data.get("dungeon_id", "")
	current_month = data.get("current_month", 1)
	area_resource_states = data.get("resource_states", {})
	
	# 加载区域状态
	areas.clear()
	var areas_data = data.get("areas", {})
	for area_id in areas_data:
		var area = DungeonArea.new()
		area.load_state(areas_data[area_id])
		areas[area_id] = area


