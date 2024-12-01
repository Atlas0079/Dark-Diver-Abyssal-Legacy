class_name Event
extends Resource

# 事件类型枚举
enum EventType {
	ENTER,      # 进入区域时触发
	EXIT,       # 离开区域时触发
	STAY,       # 停留时触发
	INTERACT,   # 与特定物品/NPC互动时触发
	BATTLE,     # 战斗相关事件
	QUEST,      # 任务相关事件
	DIALOG,     # 对话事件
	CUSTOM      # 自定义事件
}

# 基本信息
var id: String
var name: String
var description: String
var event_type: EventType
var priority: int = 0  # 事件优先级，数字越大优先级越高

# 触发控制
var one_time: bool = false      # 是否只触发一次
var triggered: bool = false     # 是否已触发过
var auto_trigger: bool = true   # 是否自动触发
var cooldown: float = 0.0       # 冷却时间（秒）
var last_trigger_time: float = 0.0  # 上次触发时间

# 触发条件
var conditions = {
	"time_range": null,     # 时间范围
	"item_ids": [],           # 需要的物品
	"quest_ids": [],         # 需要的任务状态
	"states": [],         # 需要的状态
	"variables": {},      # 需要的变量条件
	"chance": 100         # 触���概率(0-100)
}

# 事件行为
var actions: Array = []

# 初始化事件
func init_from_data(event_data: Dictionary) -> void:
	id = event_data.get("id", "")
	name = event_data.get("name", "")
	description = event_data.get("description", "")
	event_type = EventType[event_data.get("type", "CUSTOM")]
	priority = event_data.get("priority", 0)
	
	# 触发控制
	one_time = event_data.get("one_time", false)
	auto_trigger = event_data.get("auto_trigger", true)
	cooldown = event_data.get("cooldown", 0.0)
	
	# 条件和行为
	if event_data.has("conditions"):
		conditions = event_data.conditions
	if event_data.has("actions"):
		actions = event_data.actions

# 检查事件是否可以触发
func can_trigger(character: Character, context: Dictionary = {}) -> bool:
	if one_time and triggered:
		return false
		
	# 检查冷却时间
	var current_time = Time.get_unix_time_from_system()
	if current_time - last_trigger_time < cooldown:
		return false
	
	# 检查触发概率
	if randf() * 100 > conditions.chance:
		return false
	
	# 检查各种条件
	if not _check_conditions(character, context):
		return false
	
	return true

# 触发事件
func trigger(character: Character, context: Dictionary = {}) -> void:
	if not can_trigger(character, context):
		return
	
	print("触发事件: ", name)
	
	# 执行所有行为
	for action in actions:
		execute_action(action, character, context)
	
	# 更新触发状态
	if one_time:
		triggered = true
	last_trigger_time = Time.get_unix_time_from_system()

# 检查所有条件
func _check_conditions(character: Character, context: Dictionary) -> bool:
	# 检查时间范围
	if conditions.time_range != null:
		if not _check_time_condition(conditions.time_range):
			return false
	
	# 检查物品需求
	for required_item_id in conditions.item_ids:
		var found = false
		for item in character.inventory.items:
			if item.item_id == required_item_id:
				found = true
				break
		if not found:
			return false
	
	# 检查任务状态
	for quest in conditions.quests:
		# 假设Character有completed_quests属性
		if not character.completed_quests.has(quest):
			return false
	
	# 检查角色状态
	for state in conditions.states:
		if not character.states.has(state):
			return false
	
	# 检查变量条件
	for var_name in conditions.variables:
		var required_value = conditions.variables[var_name]
		# 假设有个全局的GameState类来管理游戏变量
		#if GameState.get_variable(var_name) != required_value:
		#	return false
	
	return true

# 执行具体行为
func execute_action(action: Dictionary, character: Character, context: Dictionary) -> void:#
	match action.type:
		"dialog":
			pass
		"give_item":
			var item = DataManager.create_item(action.item_id)
			if item:
				character.inventory.add_item(item)
		"remove_item":
			var item = character.inventory.find_item_by_id(action.item_id)
			if item:
				character.inventory.remove_item(item)
		"modify_state":
			if action.operation == "add":
				character.states.append(action.state)
			elif action.operation == "remove":
				character.states.erase(action.state)
		"start_quest":
			pass
		"complete_quest":
			pass
		"modify_variable":
			pass
		"start_battle":
			pass
		"teleport":
			character.location = action.target_location
		"spawn_npc":
			# 在指定位置生成NPC
			var npc = DataManager.get_character_instance(action.npc_id)
			npc.location = action.location
		"custom":
			# 执行自定义行为
			if action.has("script"):
				execute_custom_script(action.script, character, context)

# 检查时间条件
func _check_time_condition(time_range: Dictionary):
	# 假设有个全局的时间系统
	pass

# 执行自定义脚本
func execute_custom_script(script: String, character: Character, context: Dictionary) -> void:
	# 这里可以实现自定义脚本的执行逻辑
	# 可以是简单的内置脚本语言，或者调用GDScript的表达式解析器
	pass
