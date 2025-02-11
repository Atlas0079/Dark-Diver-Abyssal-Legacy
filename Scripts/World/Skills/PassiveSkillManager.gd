#res://Scripts/World/Skills/PassiveSkillManager.gd
#AutoLoad
extends Node
var battle: Battle
var current_targets: Array[Character] = []

signal passive_skill_triggered(skill, targets, caster)

# 监听 Battle 脚本的信号
func battle_start(current_battle: Battle):
	if current_battle:
		battle = current_battle
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

	
func _check_and_trigger_passive_skills(current_character: Character, trigger_type: String):
	# 1. 收集所有角色到一个数组中
	var all_characters: Array[Character] = []
	var teams = [Battle.blue_team, Battle.red_team]
	for team in teams:
		for position in team:
			var character = team[position]
			if character:
				all_characters.append(character)
	
	# 2. 对角色进行排序
	all_characters.sort_custom(func(a: Character, b: Character):
		var threshold_a = a.battle_stats.action_threshold
		var threshold_b = b.battle_stats.action_threshold
		if threshold_a != threshold_b:
			return threshold_a < threshold_b
		# 如果阈值相同，使用角色ID或其他固定属性来排序
		return a.get_instance_id() < b.get_instance_id()
	)
	
	# 3. 按排序后的顺序处理每个角色的被动技能，直到有一个成功触发
	for character in all_characters:
		var effects_results = _process_character_skills(character, trigger_type)
		if effects_results != {}:
			return effects_results
	return {}




func _process_character_skills(character: Character, trigger_type: String):
	if not character.is_alive():
		return {}
	var skill_id = character.get_available_passive_skill(battle,trigger_type) 
	if skill_id == "":
		return {}
	var skill = character.get_skill(skill_id)
	var targets = skill.get_targets(character, battle)
	if targets != null:
		print("PassiveSkillManager._process_character_skills 触发被动技能: ", skill.skill_name, "user: ", character.character_name, " targets: ", targets)
		var effects_results = skill.apply_effects(character,targets, battle)
		SkillAnimation.play_skill_animation(skill, character, effects_results)
		emit_signal("passive_skill_triggered", skill, targets, character)
		return effects_results  # 成功触发一个技能后立即返回
	return {}

func _on_skill_and_targets_selected(skill: BaseSkill, targets: Array) -> Array:
	current_targets = targets  # 保存当前技能目标
	var modified_targets = targets.duplicate()
	var effects = _check_and_trigger_passive_skills(skill.owner,"skill_and_targets_selected")
	current_targets = []  # 清除当前技能目标
	if effects and effects.has("modified_targets"):
		modified_targets = effects.modified_targets
	return modified_targets
