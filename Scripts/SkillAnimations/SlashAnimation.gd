class_name SlashAnimation
extends BaseSkillAnimation

var original_position: Vector3
var target_sprite: Sprite3D
var user_sprite: Sprite3D
var slash_effect: AnimatedSprite3D
var prepare_effect: AnimatedSprite3D

func setup(p_battle_scene: Node3D, p_general_animation: GeneralAnimation) -> void:
	super.setup(p_battle_scene, p_general_animation)
	# general_animation 已经在父类中设置好了
	# 如果需要直接访问 ui_updater，可以通过 general_animation.ui_updater 获取

func play(phase: AnimationPhase, p_battle_event: BattleEvent) -> void: 
	self.battle_event = p_battle_event
	match phase:
		AnimationPhase.PREPARE:
			play_prepare()
		AnimationPhase.EXECUTE:
			play_execute()
		AnimationPhase.FINISH:
			play_finish()
		_:
			play_prepare()
			play_execute()
			play_finish()

func play_prepare() -> void:
	# 获取使用者精灵
	user_sprite = battle_scene.find_character_sprite(battle_event.source)
	print("SlashAnimation.play_prepare user_sprite: %s" % user_sprite)
	if user_sprite == null:
		push_error("无法找到使用者精灵")
		animation_completed.emit()  # 即使失败也发出信号
		return
		
	# 保存原始位置 - 确保保存到实例变量中
	original_position = user_sprite.global_position
	
	# 获取目标精灵
	target_sprite = battle_scene.find_character_sprite(battle_event.targets[0])
	
	if target_sprite == null:
		push_error("无法找到目标精灵")
		animation_completed.emit()  # 即使失败也发出信号
		return
	
	# 播放准备动画
	prepare_effect = load("res://Scenes/Animation/normal_start_white.tscn").instantiate()
	battle_scene.add_child(prepare_effect)
	prepare_effect.global_position = user_sprite.global_position
	prepare_effect.play()
	
	# 等待准备动画完成
	await prepare_effect.animation_finished
	
	# 发出动画完成信号
	self.animation_completed.emit()

func play_execute() -> void:
	if not user_sprite or not target_sprite:
		self.animation_completed.emit()  # 如果精灵不存在，直接发出信号
		return
	
	# 计算目标位置
	var is_source_blue = battle_scene.get_character_team(battle_event.source) == "blue" 
	var dash_direction = 1 if is_source_blue else -1
	var dash_position = target_sprite.global_position
	dash_position.x += -1.0 * dash_direction
	
	# 创建冲刺动画
	var tween = battle_scene.create_tween()
	tween.tween_property(user_sprite, "global_position", dash_position, 0.3)
	await tween.finished
	
	# 创建并播放斩击特效（不等待）
	slash_effect = load("res://Scenes/Animation/Slash.tscn").instantiate()
	battle_scene.add_child(slash_effect)
	slash_effect.global_position = target_sprite.global_position
	
	# --- 新增：特效反转逻辑 ---
	is_source_blue = battle_scene.get_character_team(battle_event.source) == "blue"
	if not is_source_blue:
		# 如果攻击者不是蓝队（即在右边），则将特效水平翻转
		slash_effect.flip_h = true
	
	slash_effect.play()
	
	# 等待0.2秒
	await battle_scene.get_tree().create_timer(0.2).timeout
	
	# --- 新的、可控制的受击动画 ---
	if battle_event.skill_info and battle_event.skill_info.has("effects"):
		for effect_package in battle_event.skill_info.effects:
			if not effect_package.targets.is_empty():
				var target = effect_package.targets[0]
				# 调用并等待受击动画完成
				await general_animation.play_hit_sequence(target, effect_package)

	# 等待斩击特效播放完毕（如果需要的话，可以和受击动画并行）
	await slash_effect.animation_finished
	
	# 发出动画完成信号
	self.animation_completed.emit()

func play_finish() -> void:
	if not user_sprite:
		self.animation_completed.emit()  # 如果精灵不存在，直接发出信号
		return
	
	# 角色跳回原位（使用自定义动画而非GeneralAnimation）
	var tween = battle_scene.create_tween()
	tween.tween_property(user_sprite, "global_position", original_position, 0.3)
	await tween.finished
	
	# 清理动画资源
	if prepare_effect:
		prepare_effect.queue_free()
	
	if slash_effect:
		slash_effect.queue_free()
	
	# 发出动画结束信号
	self.animation_completed.emit()
	
