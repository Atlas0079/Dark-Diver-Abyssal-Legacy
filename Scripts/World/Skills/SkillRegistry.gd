extends Node
class_name SkillRegistry

# 技能ID到技能类的映射
static var skill_classes = {
	"S1005": SlashSkill,
	"S2004": CoverSkill,
	# 可以添加更多技能映射
	"S1002": FireballSkill, 
	# "S1003": HealSkill,
	# 等等...
}

# 创建技能实例
static func create_skill(skill_id: String, custom_timings: Array = [], custom_priority: int = -1) -> BaseSkill:
	if not skill_classes.has(skill_id):
		push_error("未找到技能ID: " + skill_id)
		return null
		
	# 获取技能类并创建实例
	var skill_class = skill_classes[skill_id]
	var skill_instance = skill_class.new()
	
	# 初始化技能，直接传入自定义参数
	skill_instance._setup(custom_timings, custom_priority)
	
	return skill_instance 