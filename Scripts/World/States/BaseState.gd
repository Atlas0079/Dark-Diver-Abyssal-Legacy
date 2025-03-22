extends Resource
class_name BaseState

# 状态的基本属性
var state_name: String
var description: String
var animation: String

var counter_state: String
var effect_trigger: String = ""
var reduce_trigger: String = ""

func _init() -> void:
	_setup()

# 由子类重写的初始化方法
func _setup() -> void:
	push_error("BaseState._setup() 需要被子类重写")

# 应用状态效果 - 返回效果结果信息用于创建事件
func apply_effect(battle: Battle, character: Character, value: int) -> Dictionary:
	push_error("BaseState.apply_effect() 需要被子类重写")
	return {}

# 检查是否应该在指定时机触发
func should_trigger_at(timing: String) -> bool:
	return effect_trigger == timing

# 检查是否应该在指定时机减少
func should_reduce_at(timing: String) -> bool:
	return reduce_trigger == timing

func nature_decay(battle: Battle, character: Character) -> Dictionary:
	push_error("BaseState.nature_decay() 需要被子类重写")
	return {}
