extends Node

# 技能类映射表
var _skill_classes = {
	"0005": preload("res://Scripts/World/Skills/Slash.gd"),
}

# 获取技能实例
func create_skill(skill_id: String) -> BaseSkill:
	if not _skill_classes.has(skill_id):
		push_error("未知的技能ID: %s" % skill_id)
		return null
		
	return _skill_classes[skill_id].new()