class_name DungeonArea
extends Node

# 区域基础属性
var area_id: String
var area_name: String
var floor_level: int
var tags: Array = []
var area_type: String
var description: String

# 房间管理
var rooms: Dictionary = {}  # 键：房间ID，值：Room实例
var room_grid: Array = []  # 二维数组存储房间位置
var grid_size: Vector2i = Vector2i(10, 10)  # 网格大小

# 生成配置
var monster_groups: Array = []
var item_spawn_rates: Dictionary = {}
var event_spawn_rates: Dictionary = {}
var room_spawn_rates: Dictionary = {}
var total_item_value_at_init: float = 0.0

# 区域特征
var area_loot_multiplier: float = 1.0
var size_factor: float = 1.0  # 区域大小因子，影响房间数量
