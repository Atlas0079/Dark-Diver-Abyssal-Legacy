# res://Scripts/SkillAnimation.gd
# AutoLoad

extends Node

var battle_scene: Node
var battle: Battle  # 添加对 Battle 实例的引用

func setup_scene(scene: Node):
	battle_scene = scene
	battle = scene.battle  # 获取 Battle 实例的引用
	print("动画系统初始化完成")

func play_skill_animation(skill: Skill, user: Character, targets: Array[Character], effects_results: Array) -> void:
	print("开始播放技能动画: ", skill.name)
	
	# 获取精灵节点
	var user_sprite = battle_scene.find_character_sprite(user)
	if not user_sprite:
		print("未找到用户精灵节点")
		_finish_animation()
		return
		
	print("获取到精灵节点: ", user_sprite)
	
	# 根据技能类型播放对应动画
	match skill.animation:
		"slash":
			await play_slash_animation(user_sprite, targets, effects_results) 
		"fireball":
			await play_fireball_animation(user_sprite, targets)
		_:
			await play_slash_animation(user_sprite, targets, effects_results) # 默认使用slash动画
	
	_finish_animation()

# 添加动画完成处理函数
func _finish_animation() -> void:
	print("动画完成 animation_completed")
	battle.emit_signal("animation_completed")
	battle_scene.is_animation_playing = false  # 添加这行来重置动画状态

# 斩击动画
func play_slash_animation(user_sprite: Node, targets: Array[Character], effects_results: Array) -> void:
	print("播放斩击动画")
	if targets.size() != 1:
		push_error("斩击动画不支持多目标，或者没有目标，targets: ", targets)
		return
		
	# 获取移动信息
	var original_position = user_sprite.position
	var is_blue_team = user_sprite.get_parent().name == "Blue"
	var move_direction = Vector2(50, 0) if is_blue_team else Vector2(-50, 0)
	var target_position = original_position + move_direction
	
	# 获取目标精灵
	var target_sprite = battle_scene.find_character_sprite(targets[0])
	if not target_sprite:
		print("未找到目标精灵节点")
		return
	
	# 1. 攻击者向前跳跃
	var attacker_tween = create_tween()
	attacker_tween.parallel().tween_property(user_sprite, "position:x", target_position.x, 0.2)
	attacker_tween.parallel().tween_property(user_sprite, "position:y", original_position.y - 30, 0.1)
	attacker_tween.parallel().tween_property(user_sprite, "position:y", original_position.y, 0.1).set_delay(0.1)
	
	await get_tree().create_timer(0.3).timeout
	
	# 2. 加载并播放斩击特效
	var slash_effect = preload("res://Scenes/Animation/Slash.tscn").instantiate()
	battle_scene.add_child(slash_effect)
	slash_effect.position = target_sprite.position
	slash_effect.sprite_frames.set_animation_loop("Slash", false)  # 设置不循环播放
	slash_effect.play()  # 开始播放动画
	#播放结束后删除节点
	# 3. 目标闪红光和显示伤害数字
	var hit_tween = create_tween()
	hit_tween.tween_property(target_sprite, "modulate", Color(1, 0, 0), 0.1)
	hit_tween.tween_property(target_sprite, "modulate", Color(1, 1, 1), 0.1)
	
	# 显示伤害数字
	if effects_results[0].type == "physical_damage":
		var damage_label = create_damage_label(effects_results[0].value)
		battle_scene.add_child(damage_label)
		damage_label.position = target_sprite.position + Vector2(0, -50)
		
		var label_tween = create_tween()
		label_tween.parallel().tween_property(damage_label, "position:y", 
			damage_label.position.y - 30, 0.5)
		label_tween.parallel().tween_property(damage_label, "modulate:a", 0, 0.5)
		
		await get_tree().create_timer(0.5).timeout
		damage_label.queue_free()
	
	# 4. 等待斩击动画播放完成
	await get_tree().create_timer(0.25).timeout
	slash_effect.queue_free()
	
	# 5. 攻击者返回原位
	var return_tween = create_tween()
	return_tween.tween_property(user_sprite, "position", original_position, 0.2)
	await return_tween.finished
	
	print("斩击动画完成")

# 创建像素风格的伤害标签
func create_damage_label(damage: int) -> Label:
	var label = Label.new()
	label.text = str(damage)
	label.add_theme_font_size_override("font_size", 24)
	# 这里可以设置像素字体
	label.modulate = Color(1, 0, 0)  # 红色
	return label

# 火球动画
func play_fireball_animation(user_sprite: Node, targets: Array) -> void:
	print("播放火球动画")
	# 这里可以之后再实现火球动画
	await get_tree().create_timer(0.5).timeout
