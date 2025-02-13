#res://Scripts/SkillAnimations/Cover.gd
extends BaseSkillAnimation

var main_skill_completed = false

func _init() -> void:
	# 连接到全局动画系统的信号
	SkillAnimation.skill_animation_completed.connect(_on_main_skill_completed)

func _on_main_skill_completed() -> void:
	main_skill_completed = true

func play() -> void:
	main_skill_completed = false
	
	var user_sprite: Sprite3D = find_sprite(user)
	if not user_sprite:
		print("未找到用户精灵节点")
		return
		
	var protected_target = effects_results.get("protected_target")
	if not protected_target:
		print("未找到保护目标")
		return
		
	var target_sprite: Sprite3D = find_sprite(protected_target)
	if not target_sprite:
		print("未找到目标精灵节点")
		return
	
	# 记录掩护者的原始位置
	var original_position = user_sprite.position
	
	# 创建动画播放器
	var tween = create_tween()
	
	var target_position = target_sprite.position
	target_position.z += 0.05
	target_position.x += 0.5
	
	# 设置跳跃高度
	var jump_height = 1.0
	var original_y = user_sprite.position.y
	
	# 1. 跳跃到目标位置
	tween.set_parallel(true)
	# 水平移动使用 ease_in_out
	tween.tween_property(user_sprite, "position:x", target_position.x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(user_sprite, "position:z", target_position.z, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	# 垂直跳跃使用抛物线效果
	tween.tween_property(user_sprite, "position:y", original_y + jump_height, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(user_sprite, "position:y", original_y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	
	# 发出准备完成信号
	emit_signal("animation_ready")
	
	# 2. 等待主技能动画完成
	while not main_skill_completed:
		await battle_scene.get_tree().process_frame
	
	# 3. 跳跃返回原位
	tween = create_tween()
	tween.set_parallel(true)
	# 水平移动使用 ease_in_out
	tween.tween_property(user_sprite, "position:x", original_position.x, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(user_sprite, "position:z", original_position.z, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	# 垂直跳跃使用抛物线效果
	tween.tween_property(user_sprite, "position:y", original_y + jump_height, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(user_sprite, "position:y", original_y, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	
	emit_signal("animation_completed")
