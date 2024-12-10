class_name RandomUtils
extends Node

var rng: RandomNumberGenerator

func _init():
	rng = RandomNumberGenerator.new()

# 使用种子初始化随机数生成器
func initialize_with_seed(seed_value: int) -> void:
	rng.seed = seed_value

# 在指定范围内获取随机整数
func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)

# 获取随机浮点数
func randf() -> float:
	return rng.randf()

# 数组随机打乱
func shuffle_array(array: Array) -> Array:
	var shuffled = array.duplicate()
	var n = shuffled.size()
	for i in range(n - 1, 0, -1):
		var j = randi_range(0, i)
		var temp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = temp
	return shuffled

# 根据权重随机选择
func weighted_choice(candidates: Array, weight_key: String = "weight") -> Dictionary:
	var total_weight = 0
	for candidate in candidates:
		total_weight += candidate[weight_key]
	
	var random_value = randf() * total_weight
	var current_weight = 0
	
	for candidate in candidates:
		current_weight += candidate[weight_key]
		if current_weight >= random_value:
			return candidate
	
	return candidates[0]  # 防止意外情况