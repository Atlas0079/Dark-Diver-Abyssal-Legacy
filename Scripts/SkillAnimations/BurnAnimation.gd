class_name BurnAnimation
extends BaseSkillAnimation

var fire_effect: AnimatedSprite3D

func play(phase: AnimationPhase, p_battle_event: BattleEvent) -> void:
	self.battle_event = p_battle_event
	match phase:
		AnimationPhase.PREPARE:
			play_prepare()
		AnimationPhase.EXECUTE:
			play_execute()
		AnimationPhase.FINISH:
			play_finish()

func play_prepare() -> void:
	# 状态动画通常没有准备阶段，但为了避免时序问题 (race condition),
	# 我们需要确保 'animation_completed' 信号在下一帧发出，
	# 这样 BattleAnimationManager 中的 'await' 才能正确捕获它。
	await battle_scene.get_tree().process_frame
	animation_completed.emit()

func play_execute() -> void:
	# 获取受影响的角色精灵（对于状态效果，使用者就是目标）
	var target_sprite = battle_scene.find_character_sprite(battle_event.source)
	if target_sprite == null:
		push_error("BurnAnimation: 无法找到目标 %s 的精灵" % battle_event.source.character_name)
		animation_completed.emit()
		return

	# 1. 播放火焰特效
	# 我注意到 state_fire.tscn 已经设置了3倍缩放，所以这里直接使用
	fire_effect = load("res://Scenes/Animation/state_fire.tscn").instantiate()
	battle_scene.add_child(fire_effect)
	fire_effect.global_position = target_sprite.global_position # 放置在角色脚下
	fire_effect.play()

	# 2. 触发伤害数字和角色受击动画
	if battle_event.state_info and battle_event.state_info.has("state_effect"):
		var effect_info = battle_event.state_info.state_effect
		# 为了复用通用的受击动画函数，我们在这里手动构建一个效果包
		var effect_package = {
			"damage": effect_info.get("damage", 0),
			"heal": effect_info.get("heal", 0),
			"targets": [battle_event.source]
		}
		# 调用通用的受击动画序列，它会处理伤害/治疗数字和角色的受击反应
		await general_animation.play_hit_sequence(battle_event.source, effect_package)

	# 3. 等待火焰动画播放完毕
	await fire_effect.animation_finished

	# 4. 清理动画资源
	if fire_effect:
		fire_effect.queue_free()

	# 5. 发出动画完成信号
	animation_completed.emit()

func play_finish() -> void:
	# 同样，等待下一帧再发出信号
	await battle_scene.get_tree().process_frame
	animation_completed.emit() 
