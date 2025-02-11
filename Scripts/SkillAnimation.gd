# res://Scripts/SkillAnimation.gd
# AutoLoad

extends Node

var battle_scene: Node3D
var battle: Battle

signal skill_animation_completed 

func setup_scene(scene: Node3D):
	battle_scene = scene
	battle = scene.battle  # 获取 Battle 实例的引用
	print("动画系统初始化完成，battle实例：", battle)  # 添加调试信息

func play_skill_animation(skill: BaseSkill, user: Character, effects_results: Dictionary) -> void:
	print("开始播放技能动画: ", skill.skill_name)
	
	if battle_scene:
		battle_scene.is_animation_playing = true  # 设置动画播放标志
	
	# 获取精灵节点
	var user_sprite: Sprite3D = battle_scene.find_character_sprite(user)
	if not user_sprite:
		print("未找到用户精灵节点")
		_finish_animation()
		return
		
	print("获取到精灵节点: ", user_sprite)
	
	# 更新技能信息UI
	var skill_info_name = battle_scene.get_node("CanvasLayer/SkillInfo/Name")
	var skill_info_desc = battle_scene.get_node("CanvasLayer/SkillInfo/RichTextLabel")
	
	if skill_info_name and skill_info_desc:
		skill_info_name.text = skill.skill_name
		skill_info_desc.text = skill.description
	else:
		push_error("未找到技能信息UI节点")
		_finish_animation()
		return

	#if skill.skill_type == "passive":
	if get_team(user) == "blue":
		play_passive_label_animation(skill.skill_name,true)
	else:
		play_passive_label_animation(skill.skill_name,false)

	
	# 根据技能类型播放对应动画
	match skill.animation:
		"slash":
			var slash = preload("res://Scripts/SkillAnimations/Slash.gd")
			await slash.play(battle_scene, user, effects_results) 
		"cover":
			var cover = preload("res://Scripts/SkillAnimations/Cover.gd")
			await cover.play(battle_scene, user, effects_results)
		"fireball":
			pass
		_:
			pass
	

	_finish_animation()

# 添加动画完成处理函数
func _finish_animation() -> void:
	print("动画完成 animation_completed")
	if battle:
		battle.emit_signal("animation_completed")
		emit_signal("skill_animation_completed")
	else:
		push_error("Battle实例为空")
	if battle_scene:
		battle_scene.is_animation_playing = false

func play_passive_label_animation(skill_name: String, is_blue_team: bool = true) -> void:
	# 加载并实例化技能名称背景场景
	var scene_path = "res://Scenes/UI/blue_skill_background.tscn" if is_blue_team else "res://Scenes/UI/red_skill_background.tscn"
	var skill_name_scene = load(scene_path).instantiate()
	battle_scene.get_node("CanvasLayer").add_child(skill_name_scene)
	
	# 设置初始位置（蓝队从左边进入，红队从右边进入）
	var start_x = -208 if is_blue_team else 1488  # 1280 + 208
	var target_x = 0 if is_blue_team else 1280
	skill_name_scene.position = Vector2(start_x, 64)
	
	# 设置技能名称
	var name_label = skill_name_scene.get_node("NameLabel")
	if name_label:
		name_label.text = skill_name
	
	# 创建向中间移动的动画
	var move_tween = create_tween()
	move_tween.tween_property(skill_name_scene, "position:x", target_x, 0.2)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_OUT)
	
	# 等待1秒
	await get_tree().create_timer(1.0).timeout
	
	# 创建向上移动并淡出的动画（红队向上右，蓝队向上左）
	var fade_tween = create_tween()
	var end_x = target_x - 40 if is_blue_team else target_x + 40
	fade_tween.parallel().tween_property(skill_name_scene, "position:x", end_x, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	fade_tween.parallel().tween_property(skill_name_scene, "position:y", 44, 0.4)\
		.set_trans(Tween.TRANS_CUBIC)\
		.set_ease(Tween.EASE_IN)
	fade_tween.parallel().tween_property(skill_name_scene, "modulate:a", 0, 0.3)
	
	# 等待动画完成后删除节点
	await fade_tween.finished
	skill_name_scene.queue_free()

func get_team(character: Character) -> String:
	# 遍历蓝队所有位置
	for pos in battle.blue_team.values():
		if pos == character:  # 直接比较位置上的角色是否是目标角色
			return "blue"
	
	# 遍历红队所有位置
	for pos in battle.red_team.values():
		if pos == character:
			return "red"
	
	push_error("未找到队伍")
	return ""
