extends Node

# 技能类映射表
var _skill_classes = {
	#"0001": preload("res://Scripts/World/Skills/Slash.gd"),
	#"0002": preload("res://Scripts/World/Skills/Fireball.gd"),
	#"0003": preload("res://Scripts/World/Skills/FrostNova.gd"),
	"S2004": preload("res://Scripts/World/Skills/Cover.gd"),
	"S1005": preload("res://Scripts/World/Skills/Slash.gd"),
}

# 获取技能实例
func create_skill(skill_id: String) -> BaseSkill:
	if not _skill_classes.has(skill_id):
		push_error("未知的技能ID: %s" % skill_id)
		return null
		
	return _skill_classes[skill_id].new()
