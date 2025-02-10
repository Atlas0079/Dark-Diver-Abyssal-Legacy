extends BaseSkill
signal targets_modified(new_targets: Array)

func _setup() -> void:
	skill_name = "Cover"
	skill_type = "passive"
	description = "代替队友成为技能目标"
	priority = 0
	tags = ["ally_only","single_target","physical"]
	animation = "cover"
	use_conditions = []
	passive_trigger = "skill_and_targets_selected"

func apply_effects(user: Character, targets: Array[Character], battle: Battle):
	targets = [user]
	emit_signal("targets_modified", targets)
	
