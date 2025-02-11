#res://Scripts/SkillAnimations/Cover.gd
extends RefCounted

static func play(battle_scene: Node3D, user: Character, effects_results: Dictionary) -> void:
	var user_sprite: Sprite3D = battle_scene.find_character_sprite(user)
	if not user_sprite:
		print("未找到用户精灵节点")
		return
		
	var protected_target = effects_results.get("protected_target")
	if not protected_target:
		print("未找到保护目标")
		return
		
	var target_sprite: Sprite3D = battle_scene.find_character_sprite(protected_target)
	if not target_sprite:
		print("未找到目标精灵节点")
		return
	
	# 记录掩护者的原始位置
	var original_position = user_sprite.position
	
	# 创建动画播放器
	var tween = battle_scene.create_tween()
	
	var target_position = target_sprite.position
	target_position.z += 0.05
	target_position.x += 0.5
	# 1. 移动到目标位置
	tween.tween_property(user_sprite, "position", target_position, 0.2)
	await tween.finished
	
	# 2. 等待主技能动画完成
	# 这里我们需要一个信号来通知我们主技能动画已经完成
	await SkillAnimation.skill_animation_completed
	
	# 3. 返回原位
	tween = battle_scene.create_tween()
	tween.tween_property(user_sprite, "position", original_position, 0.3)
	await tween.finished
