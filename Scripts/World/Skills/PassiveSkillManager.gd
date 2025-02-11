extends Node

signal passive_skill_triggered(skill, targets, caster)

# 监听 Battle 脚本的信号
func _ready():
	var battle = get_node("../Battle") # 假设 Battle 节点是 PassiveSkillManager 的兄弟节点
	if battle:
		battle.connect("turn_start", _on_battle_signal)
		battle.connect("turn_end", _on_battle_signal)
		battle.connect("character_action_start", _on_character_action_start)
		battle.connect("character_action_end", _on_character_action_end)
		battle.connect("battle_start",_on_battle_signal)

		battle.connect("battle_end",_on_battle_signal)
		battle.connect("skill_and_targets_selected", _on_skill_and_targets_selected)
	else:
		push_error("PassiveSkillManager 找不到 Battle 节点!")

# 响应 Battle 信号

func _on_battle_signal() -> void:
	#print("_on_battle_signal: ", trigger_type)
	_check_and_trigger_passive_skills(null, "battle_start")

func _on_character_action_start(current_character: Character) -> void:
	#print("_on_character_action_start: ", character.character_name)
	_check_and_trigger_passive_skills(current_character, "character_action_start")


func _on_character_action_end(current_character: Character) -> void:
	#print("_on_character_action_end: ", character.character_name)
	_check_and_trigger_passive_skills(current_character, "character_action_end")

	
func _check_and_trigger_passive_skills(current_character: Character, trigger_type: String) -> void:
	# 1. 收集所有角色到一个数组中
	var all_characters: Array[Character] = []
	var teams = [Battle.blue_team, Battle.red_team]
	for team in teams:
		for position in team:
			var character = team[position]
			if character:
				all_characters.append(character)
	
	# 2. 对角色进行排序
	# 首先按照行动阙值排序，相同的随机打乱
	all_characters.sort_custom(func(a: Character, b: Character):
		var threshold_a = a.battle_stats.action_threshold
		var threshold_b = b.battle_stats.action_threshold
		if threshold_a != threshold_b:
			return threshold_a < threshold_b
		# 如果阙值相同，随机返回true或false
		return randf() > 0.5
	)
	
	# 3. 按排序后的顺序处理每个角色的被动技能
	for character in all_characters:
		_process_character_skills(character, trigger_type)


func _process_character_skills(character: Character, trigger_type: String) -> void:
	if not character.is_alive(): # 只处理存活角色
		return
	for skill_id in character.skills:
		var skill = character.get_skill(skill_id)
		if skill and skill.skill_type == "passive" and skill.passive_trigger == trigger_type:
			var targets = skill.get_targets(character, get_node("../Battle")) #需要把battle传进去
			if targets != null:
				print("PassiveSkillManager._process_character_skills 触发被动技能: ", skill.name)
				emit_signal("passive_skill_triggered", skill, targets, character)

func _on_skill_and_targets_selected(skill: BaseSkill, targets: Array) -> void:
	# 这里可以修改 targets
	_check_and_trigger_passive_skills(skill.owner, "skill_and_targets_selected")