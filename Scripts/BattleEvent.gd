extends Resource
class_name BattleEvent

enum EventType {
	ACTIVE_SKILL,    # 主动技能
	PASSIVE_SKILL,   # 被动技能
	STATE_RESOLVE,   # 状态结算
	TURN_SYNC,       # 回合同步事件
	MARK_EVENT       # 标记事件
}

var event_type: EventType
var turn_number: int
var source: Character      # 事件源（施法者/状态持有者）
var targets: Array  # 影响的目标，注意该变量现在已经弃用，应该从下面的Info获取具体的目标

var skill_info: Dictionary = {}  # 技能信息（如果是技能事件）
var state_info: Dictionary = {}  # 状态信息（如果是状态事件）
var sync_info: Dictionary = {}   # 同步信息（如果是同步事件）

# --- 数据结构规范 ---
# skill_info 字典的期望结构:
# {
#     "skill_name": String,      - 技能的名称
#     "skill_type": String,      - "active" 或 "passive"
#     "animation": String,       - 动画脚本的关键字，如 "slash", "fireball"
#     "effects": [
#         {
#             "target": Character,         - 实际受此效果影响的目标
#             "damage": int,               - (可选) 造成的伤害值
#             "heal": int,                 - (可选) 造成的治疗量
#             "hit_type": String,          - (可选) 命中的类型，"hit", "crit", "miss","block"
#             "applied_states": [          - (可选) 施加的状态列表
#                 {string:int}
#             ],
#             "removed_states": Array[String] - (可选) 移除的状态名称列表
#         },
#         # ... 其他效果包
#     ]
# }
#
# state_info 字典的期望结构:
# {
#     "state_name": String,     - 状态的名称，如 "burn"
#     "animation": String,      - (可选) 状态结算时播放的动画关键字
#     # ... 其他状态结算效果
# }
# --------------------


# 打印单个战斗事件的详细信息
func print_event_info() -> void:
	var event_type_str = ""
	
	match event_type:
		EventType.ACTIVE_SKILL:
			event_type_str = "主动技能"
		EventType.PASSIVE_SKILL:
			event_type_str = "被动技能"
		EventType.STATE_RESOLVE:
			event_type_str = "状态结算"
	
	# 基本信息
	print("事件 (回合 %d): %s" % [turn_number, event_type_str])
	print("  源: %s" % (source.character_name if source else "无"))
	
	# 目标信息
	if targets.is_empty():
		print("  目标: 无")
	else:
		print("  目标:")
		for target in targets:
			print("    - %s" % target.character_name)
	
	# 技能信息
	if event_type == EventType.ACTIVE_SKILL or event_type == EventType.PASSIVE_SKILL:
		print("  技能: %s" % skill_info.get("skill_name", "未知"))
		print("  类型: %s" % skill_info.get("skill_type", "未知"))
		
		# 打印效果
		var effects = skill_info.get("effects", {})
		if not effects.is_empty():
			print("  效果:")
			for effect in effects:
				print("    - %s" % effect)
		
		# 被动技能额外信息
		if event_type == EventType.PASSIVE_SKILL and skill_info.has("trigger"):
			print("  触发条件: %s" % skill_info.get("trigger", "未知"))
	
	# 状态信息
	elif event_type == EventType.STATE_RESOLVE:
		print("  状态信息:")
		for key in state_info.keys():
			print("    - %s: %s" % [key, state_info[key]])
