extends RefCounted

static func play(battle_scene: Node3D, user: Character, effects_results: Dictionary) -> void:

	print("播放斩击动画")
	
	var user_sprite: Sprite3D = battle_scene.find_character_sprite(user)

	if not user_sprite:
		print("未找到用户精灵节点")
		return
		
	# 获取移动信息
	var original_position = user_sprite.global_position
	var is_blue_team = user_sprite.get_parent().name == "left_team"
	var move_direction = Vector3(1, 0, 0) if is_blue_team else Vector3(-1, 0, 0)

	# 获取目标精灵
	var target_sprite = battle_scene.find_character_sprite(effects_results["target"])
	if not target_sprite:
		print("未找到目标精灵节点")
		return

	# 存储目标的原始位置
	var target_original_position = target_sprite.global_position


	# 1. 攻击者跳到目标位置
	var attacker_tween = battle_scene.create_tween()
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
	battle_scene.get_node("Effects").add_child(slash_effect)
	slash_effect.global_position = target_sprite.global_position + Vector3(0, 0, 0.1)
	slash_effect.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	slash_effect.pixel_size = 0.01
	slash_effect.play("Slash")

	# 记录斩击动画开始时间
	var slash_start_time = Time.get_ticks_msec()


	if effects_results.hit_type == "dodge":
		# 创建残影精灵
		var after_image = Sprite3D.new()
		battle_scene.get_node("Effects").add_child(after_image)
		after_image.texture = target_sprite.texture
		after_image.global_position = target_original_position
		after_image.modulate = Color(1, 1, 1, 0.5)

		# 目标向后闪避的动画 (使用缓动函数)
		var dodge_direction = Vector3(0.4, 0, 0) if is_blue_team else Vector3(-0.4, 0, 0) # 稍微增加闪避距离
		var dodge_tween = battle_scene.create_tween()
		dodge_tween.tween_property(target_sprite, "global_position",
			target_original_position + dodge_direction * 1.5, 0.3) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_OUT)  # 使用Cubic缓动函数，先快后慢

		# 稍微加长闪避动画的时间 0.2 -> 0.3

		# 残影淡出 (与闪避动画同时进行)
		var after_image_fade_tween = battle_scene.create_tween()
		after_image_fade_tween.tween_property(after_image, "modulate:a", 0, 0.4) #残影消失时间稍微拉长
		await after_image_fade_tween.finished
		after_image.queue_free()


	elif effects_results.hit_type == "normal":
		# 3. 目标闪红光和显示伤害数字
		var hit_tween = battle_scene.create_tween()
		hit_tween.tween_property(target_sprite, "modulate", Color(1, 0, 0), 0.1)
		hit_tween.tween_property(target_sprite, "modulate", Color(1, 1, 1), 0.1)

		# 显示伤害数字
		if effects_results.has("damage"):
			var damage_label = create_damage_label(effects_results["damage"])
			battle_scene.get_node("Effects").add_child(damage_label)
			damage_label.global_position = target_sprite.global_position + Vector3(0, 0.8, -0.2)

			var label_tween = battle_scene.create_tween()
			label_tween.tween_property(damage_label, "global_position:y",
				damage_label.global_position.y + 0.5, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
			label_tween.tween_property(damage_label, "global_position:y",
				damage_label.global_position.y + 0.3, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			await battle_scene.get_tree().create_timer(0.5).timeout
			var fade_tween = battle_scene.create_tween()
			fade_tween.tween_property(damage_label, "modulate:a", 0, 0.3)
			await fade_tween.finished
			damage_label.queue_free()

	elif effects_results.hit_type == "block":
		print("斩击动画完成，目标格挡")

	# 4. 等待斩击动画播放完成 + 被击者返回
	var elapsed_time = (Time.get_ticks_msec() - slash_start_time) / 1000.0  # 计算已经过的时间（秒）
	var remaining_time = 0.25 - elapsed_time  # 假设斩击动画时长为0.25秒
	if remaining_time > 0:
		await battle_scene.get_tree().create_timer(remaining_time).timeout

	slash_effect.queue_free()

	# 被击者返回 (只有闪避时才返回)
	if effects_results.hit_type == "dodge":
		var return_tween = battle_scene.create_tween()
		return_tween.tween_property(target_sprite, "global_position",
			target_original_position, 0.2) \
			.set_trans(Tween.TRANS_CUBIC) \
			.set_ease(Tween.EASE_IN)  # 返回也使用缓动, 先慢后快
		await return_tween.finished


	# 5. 攻击者跳回原位
	var return_jump_tween = battle_scene.create_tween()
	return_jump_tween.parallel().tween_property(user_sprite, "global_position:x", original_position.x, 0.2)
	return_jump_tween.parallel().tween_property(user_sprite, "global_position:z", original_position.z, 0.2)
	return_jump_tween.parallel().tween_property(user_sprite, "global_position:y", original_position.y + 1.5, 0.1)
	return_jump_tween.parallel().tween_property(user_sprite, "global_position:y", original_position.y, 0.1).set_delay(0.1)

	await return_jump_tween.finished

	print("斩击动画完成")
	
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
