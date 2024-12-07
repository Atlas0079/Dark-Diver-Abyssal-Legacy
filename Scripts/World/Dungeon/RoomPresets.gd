class_name RoomPresets
extends Node

# 房间生成规则预设
const ROOM_RULES = {
	# 基础属性规则
	"basic": {
		"required": false,              # 是否必须生成
		"unique": false,               # 是否唯一
		"max_count": 0,               # 最大生成数量
		"max_count_per_area": 0,      # 每个区域最大数量
		"min_count": 0,               # 最小生成数量
		"weight": 1.0,                # 生成权重
	},
	
	# 位置规则
	"position": {
		"min_distance_from_type": {    # 与特定类型房间的最小距离
			"room_type": "",
			"distance": 0
		},
		"max_distance_from_type": {    # 与特定类型房间的最大距离
			"room_type": "",
			"distance": 0
		},
		"require_area_type": "",      # 要求在特定区域类型中
		"forbidden_area_type": "",    # 禁止在特定区域类型中
		"require_zone_edge": false,   # 要求在区域边缘
		"require_zone_center": false # 要求在区域中心
	},
	
	# 连接规则
	"connection": {
		"min_passages": 1,           # 最少通道数
		"max_passages": 4,           # 最多通道数
		"required_passage_types": [], # 必需的通道类型
		"forbidden_passage_types": [],# 禁止的通道类型
		"passage_type_weights": {     # 不同通道类型的生成权重，会覆盖区域默认权重
			"OPEN": 1.0,
			"DOOR": 0.6
		}
	},
	
	# 邻居规则
	"neighbor": {
		"required_neighbors": [],     # 必需的邻居类型
		"forbidden_neighbors": [],    # 禁止的邻居类型
		"preferred_neighbors": {      # 偏好的邻居类型及其权重
			"room_type": "",
			"weight": 1.0
		},
		"min_neighbor_count": 0,     # 最少邻居数量
		"max_neighbor_count": 4,     # 最大邻居数量
	},
	
	# 内容规则
	"content": {
		"item_spawn_weights": {},    # 物品生成权重
		"event_spawn_weights": {},   # 事件生成权重
		"objects_spawn_weights": {}, # 物体生成权重
	}
}

# 通道类型权重默认值
const DEFAULT_PASSAGE_WEIGHTS = {
	"OPEN": 1.0,
	"DOOR": 0.6,
	"LOCKED_DOOR": 0.3,
	"ONE_WAY_DOOR": 0.2,
	"HIDDEN_DOOR": 0.1
}

