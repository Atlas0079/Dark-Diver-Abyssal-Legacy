class_name GameTime
extends Node

# 游戏内时间单位定义
const MINUTES_PER_HOUR = 60
const HOURS_PER_DAY = 24
const DAYS_PER_WEEK = 7
const WEEKS_PER_MONTH = 4  # 4周 = 28天
const DAYS_PER_MONTH = DAYS_PER_WEEK * WEEKS_PER_MONTH  # 28天
const MONTHS_PER_YEAR = 12

# 时间流逝速度(1现实秒=多少游戏分钟)
var time_scale: float = 1.0

# 当前游戏时间
var current_time = {
	"minute": 0,
	"hour": 6,    # 游戏从早上6点开始
	"day": 1,
	"week": 1,    # 添加周
	"month": 1,
	"year": 1
}

# 时间段定义
enum TimeOfDay {
	DAWN,    # 黎明 (5:00-7:00)
	MORNING, # 上午 (7:00-11:00)
	NOON,    # 中午 (11:00-13:00)
	AFTERNOON,# 下午 (13:00-17:00)
	EVENING, # 傍晚 (17:00-19:00)
	NIGHT,   # 夜晚 (19:00-23:00)
	MIDNIGHT # 深夜 (23:00-5:00)
}

# 添加周几的枚举
enum WeekDay {
	MONDAY = 1,
	TUESDAY = 2,
	WEDNESDAY = 3,
	THURSDAY = 4,
	FRIDAY = 5,
	SATURDAY = 6,
	SUNDAY = 7
}

# 信号
signal time_changed(time_data)
signal day_changed(day)
signal week_changed(week)  # 新增周变化信号
signal month_changed(month)
signal year_changed(year)
signal time_of_day_changed(time_of_day)

func _ready():
	# 启动时间系统
	_start_time()

func _start_time():
	# 创建计时器
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1.0  # 每秒更新一次
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	advance_time(time_scale)

# 推进时间
func advance_time(minutes: float) -> void:
	# 更新分钟
	current_time.minute += minutes
	
	# 处理进位
	while current_time.minute >= MINUTES_PER_HOUR:
		current_time.minute -= MINUTES_PER_HOUR
		current_time.hour += 1
		
		if current_time.hour >= HOURS_PER_DAY:
			current_time.hour = 0
			current_time.day += 1
			
			# 处理周的变化
			var new_week = ((current_time.day - 1) / DAYS_PER_WEEK) + 1
			if new_week != current_time.week:
				current_time.week = new_week
				emit_signal("week_changed", current_time.week)
			
			emit_signal("day_changed", current_time.day)
			
			if current_time.day > DAYS_PER_MONTH:
				current_time.day = 1
				current_time.week = 1  # 重置周
				current_time.month += 1
				emit_signal("month_changed", current_time.month)
				
				if current_time.month > MONTHS_PER_YEAR:
					current_time.month = 1
					current_time.year += 1
					emit_signal("year_changed", current_time.year)
	
	# 发出时间改变信号
	emit_signal("time_changed", current_time)
	
	# 检查并发出时间段改变信号
	var new_time_of_day = get_time_of_day()
	if new_time_of_day != _last_time_of_day:
		_last_time_of_day = new_time_of_day
		emit_signal("time_of_day_changed", new_time_of_day)

# 获取当前时间段
var _last_time_of_day = null
func get_time_of_day() -> TimeOfDay:
	var hour = current_time.hour
	if hour >= 5 and hour < 7:
		return TimeOfDay.DAWN
	elif hour >= 7 and hour < 11:
		return TimeOfDay.MORNING
	elif hour >= 11 and hour < 13:
		return TimeOfDay.NOON
	elif hour >= 13 and hour < 17:
		return TimeOfDay.AFTERNOON
	elif hour >= 17 and hour < 19:
		return TimeOfDay.EVENING
	elif hour >= 19 and hour < 23:
		return TimeOfDay.NIGHT
	else:
		return TimeOfDay.MIDNIGHT

# 设置时间流逝速度
func set_time_scale(scale: float) -> void:
	time_scale = scale

# 暂停/继续时间流逝
func pause() -> void:
	set_time_scale(0)

func resume() -> void:
	set_time_scale(1.0)

# 格式化时间字符串
func format_time() -> String:
	return "%02d:%02d" % [current_time.hour, current_time.minute]

func format_date() -> String:
	return "Year %d, Month %d, Day %d" % [
		current_time.year,
		current_time.month,
		current_time.day
	]

# 检查时间是否在指定范围内
func is_time_in_range(start_time: Dictionary, end_time: Dictionary) -> bool:
	var current_minutes = current_time.hour * 60 + current_time.minute
	var start_minutes = start_time.hour * 60 + start_time.minute
	var end_minutes = end_time.hour * 60 + end_time.minute
	
	if end_minutes < start_minutes:  # 跨天的情况
		return current_minutes >= start_minutes or current_minutes <= end_minutes
	else:
		return current_minutes >= start_minutes and current_minutes <= end_minutes

# 获取两个时间点之间的分钟差
func get_minutes_between(time1: Dictionary, time2: Dictionary) -> int:
	var total_minutes1 = (time1.year * MONTHS_PER_YEAR * DAYS_PER_MONTH * HOURS_PER_DAY * MINUTES_PER_HOUR) + \
						(time1.month * DAYS_PER_MONTH * HOURS_PER_DAY * MINUTES_PER_HOUR) + \
						(time1.day * HOURS_PER_DAY * MINUTES_PER_HOUR) + \
						(time1.hour * MINUTES_PER_HOUR) + \
						time1.minute
						
	var total_minutes2 = (time2.year * MONTHS_PER_YEAR * DAYS_PER_MONTH * HOURS_PER_DAY * MINUTES_PER_HOUR) + \
						(time2.month * DAYS_PER_MONTH * HOURS_PER_DAY * MINUTES_PER_HOUR) + \
						(time2.day * HOURS_PER_DAY * MINUTES_PER_HOUR) + \
						(time2.hour * MINUTES_PER_HOUR) + \
						time2.minute
	
	return abs(total_minutes2 - total_minutes1)

# 获取当前是周几
func get_weekday() -> WeekDay:
	var total_days = (current_time.year - 1) * MONTHS_PER_YEAR * DAYS_PER_MONTH + \
					(current_time.month - 1) * DAYS_PER_MONTH + \
					current_time.day
	
	var weekday = total_days % DAYS_PER_WEEK
	if weekday == 0:
		weekday = DAYS_PER_WEEK
	
	return WeekDay.values()[weekday - 1]

# 获取周几的名称
func get_weekday_name() -> String:
	var weekday = get_weekday()
	match weekday:
		WeekDay.MONDAY: return "Monday"
		WeekDay.TUESDAY: return "Tuesday"
		WeekDay.WEDNESDAY: return "Wednesday"
		WeekDay.THURSDAY: return "Thursday"
		WeekDay.FRIDAY: return "Friday"
		WeekDay.SATURDAY: return "Saturday"
		WeekDay.SUNDAY: return "Sunday"
		_:
			push_error("Unknown weekday: " + str(weekday))
			return "Unknown"
	
