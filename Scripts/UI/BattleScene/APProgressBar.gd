extends Control

@onready var progress_bar = $TextureProgressBar

# 状态条的像素单位数
const PIXEL_UNITS = 8


func _ready():
	# 设置进度条的基本属性
	progress_bar.max_value = PIXEL_UNITS
	progress_bar.min_value = 0
	progress_bar.step = 1.0

# 更新AP状态条
func update_ap(current_ap: float, threshold: float):
	# 将当前AP值归一化到像素单位范围内
	var normalized_value = (current_ap / threshold) * PIXEL_UNITS
	# 四舍五入到最近的整数，确保对应到像素单位
	progress_bar.value = round(normalized_value)

# 清空状态条
func clear():
	progress_bar.value = 0
