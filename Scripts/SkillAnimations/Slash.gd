#res://Scripts/SkillAnimations/Slash.gd
extends BaseSkillAnimation

func play() -> void:
	print("播放斩击动画")
	
	var user_sprite: Sprite3D = find_sprite(user)
	if not user_sprite:
		print("未找到用户精灵节点")
		return
		
	# 获取移动信息
	var original_position = user_sprite.global_position
	var is_blue_team = user_sprite.get_parent().name == "left_team"
	var move_direction = Vector3(1, 0, 0) if is_blue_team else Vector3(-1, 0, 0)

	# 获取目标精灵
	var target_sprite = find_sprite(effects_results["target"])
	if not target_sprite:
		print("未找到目标精灵节点")
		return

	# 存储目标的原始位置
	var target_original_position = target_sprite.global_position

	#播放起始动画
	var start_animation: AnimatedSprite3D = preload("res://Scenes/Animation/normal_start_white.tscn").instantiate()
	get_effects_node().add_child(start_animation)
	start_animation.global_position = user_sprite.global_position
	start_animation.global_position.z += 0.1
	start_animation.global_position.y -= 0.3
	start_animation.play("default")
	await start_animation.animation_finished

	# 1. 攻击者跳到目标位置
	var attacker_tween = create_tween()
	# 计算目标位置，在目标精灵前方稍近的位置
	var jump_target_position = target_sprite.global_position + (move_direction * -1.4)
	
	# 保持y坐标不变，但x和z坐标都要移动到目标位置
	attacker_tween.parallel().tween_property(user_sprite, "global_position:x", jump_target_position.x, 0.2)
	attacker_tween.parallel().tween_property(user_sprite, "global_position:z", target_sprite.global_position.z, 0.2)
	attacker_tween.parallel().tween_property(user_sprite, "global_position:y", original_position.y + 1.5, 0.1)  # 跳得更高一些
	attacker_tween.parallel().tween_property(user_sprite, "global_position:y", original_position.y, 0.1).set_delay(0.1)

	await attacker_tween.finished

	# 2. 加载斩击特效 (无论是否闪避都加载)
	var slash_effect: AnimatedSprite3D = preload("res://Scenes/Animation/Slash.tscn").instantiate()
	get_effects_node().add_child(slash_effect)
	slash_effect.global_position = target_sprite.global_position + Vector3(0, 0, 0.1)
	
	if not is_blue_team:
		slash_effect.flip_h = true
	slash_effect.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	slash_effect.pixel_size = 0.01
	slash_effect.play("default")

	# 记录斩击动画开始时间
	var slash_start_time = Time.get_ticks_msec()
	
	if effects_results.hit_type == "dodge":
		GeneralAnimation.play_dodge_animation(target_sprite, battle_scene)
	elif effects_results.hit_type == "block":
		GeneralAnimation.play_block_animation(target_sprite, effects_results["damage"], battle_scene)
	elif effects_results.hit_type == "normal":
		GeneralAnimation.play_hit_animation(target_sprite, effects_results["damage"], battle_scene)
	elif effects_results.hit_type == "critical":
		GeneralAnimation.play_critical_animation(target_sprite, effects_results["damage"], battle_scene)
	else:
		push_error("未知的斩击类型: " + effects_results.hit_type)
	# 4. 等待斩击动画播放完成 
	var elapsed_time = (Time.get_ticks_msec() - slash_start_time) / 1000.0  # 计算已经过的时间（秒）
	var remaining_time = 0.25 - elapsed_time  # 假设斩击动画时长为0.25秒
	if remaining_time > 0:
		await battle_scene.get_tree().create_timer(remaining_time).timeout

	slash_effect.queue_free()

	# 5. 攻击者跳回原位
	var return_jump_tween = create_tween()
	return_jump_tween.parallel().tween_property(user_sprite, "global_position:x", original_position.x, 0.2)
	return_jump_tween.parallel().tween_property(user_sprite, "global_position:z", original_position.z, 0.2)
	return_jump_tween.parallel().tween_property(user_sprite, "global_position:y", original_position.y + 1.5, 0.1)
	return_jump_tween.parallel().tween_property(user_sprite, "global_position:y", original_position.y, 0.1).set_delay(0.1)

	await return_jump_tween.finished

	print("斩击动画完成")
	emit_signal("animation_completed")

static func create_damage_label(damage: int) -> Label3D:
	var label = Label3D.new()
	var font = load("res://Assets/UI/Xim-Sans-Brahmic-3.ttf")
	if font:
		label.font = font
	label.text = str(damage)
	label.font_size = 96
	label.modulate = Color(1, 0, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 100
	label.double_sided = true
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	label.outline_render_priority = 99
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return label
