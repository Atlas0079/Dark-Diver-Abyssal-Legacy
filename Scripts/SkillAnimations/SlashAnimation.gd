class_name SlashAnimation
extends BaseSkillAnimation

var original_position: Vector3
var target_sprite: Sprite3D
var user_sprite: Sprite3D
var slash_effect: AnimatedSprite3D
var prepare_effect: AnimatedSprite3D
var general_animation: GeneralAnimation
var ui_updater: UpdateUI

func setup(p_battle_scene: Node3D,) -> void:
	self.battle_scene = p_battle_scene
	self.ui_updater = UpdateUI.new(battle_scene)
	self.general_animation = GeneralAnimation.new(battle_scene, ui_updater)

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
	
	# 消耗魔法值（使用UI更新器）
	var mp_cost = battle_event.skill_info.get("mp_cost", 0)
	if mp_cost > 0:
		ui_updater.update_mp(battle_event.source, -mp_cost)
	
	# 等待准备动画完成
	await prepare_effect.animation_finished
	
	# 发出动画完成信号
	self.animation_completed.emit()

func play_execute() -> void:
	if not user_sprite or not target_sprite:
		self.animation_completed.emit()  # 如果精灵不存在，直接发出信号
		return
	
	# 不再使用GeneralAnimation，而是手动处理冲刺动画
	# 注意：我们使用已经保存的实例变量original_position，而不是重新获取
	
	# 计算目标位置（在目标角色前方一段距离）
	var is_source_blue = battle_scene.get_character_team(battle_event.source) == "blue" 
	var dash_direction = 1 if is_source_blue else -1
	var dash_position = target_sprite.global_position
	dash_position.x += -1.0 * dash_direction  # 调整为合适的距离
	
	# 创建冲刺动画
	var tween = battle_scene.create_tween()
	tween.tween_property(user_sprite, "global_position", dash_position, 0.3)
	await tween.finished
	
	# 等待一小段时间
	await battle_scene.get_tree().create_timer(0.2).timeout
	
	# 创建斩击效果
	slash_effect = load("res://Scenes/Animation/Slash.tscn").instantiate()
	battle_scene.add_child(slash_effect)
	slash_effect.global_position = target_sprite.global_position
	slash_effect.play()
	
	# 等待斩击动画完成
	await slash_effect.animation_finished
	
	# 处理伤害和UI更新
	var damage = battle_event.skill_info.get("damage", 0)
	if damage > 0:
		# 手动处理伤害效果
		for target in battle_event.targets:
			# 找到目标精灵
			target_sprite = battle_scene.find_character_sprite(target)
			if target_sprite:
				# 播放受击特效
				var hit_effect = load("res://Scenes/Effects/SlashEffect.tscn").instantiate()
				battle_scene.add_child(hit_effect)
				hit_effect.global_position = target_sprite.global_position
				hit_effect.play()
				
				# 使目标精灵闪烁表示受击
				_flash_sprite(target_sprite)
				
				# 显示伤害数字
				ui_updater.show_damage_popup(target, damage)
				
				# 抖动目标
				await _shake_sprite(target_sprite)
				
				# 更新HP
				ui_updater.update_hp(target, -damage)
				
				# 等待特效完成
				await hit_effect.animation_finished
				hit_effect.queue_free()
	
	# 发出动画完成信号
	self.animation_completed.emit()

# 使精灵闪烁（从GeneralAnimation移植过来的功能）
func _flash_sprite(sprite, flash_color: Color = Color(1, 1, 1, 1), duration: float = 0.2) -> void:
	if not sprite:
		return
	
	var original_color = sprite.modulate
	
	# 创建闪烁动画
	var tween = battle_scene.create_tween()
	tween.tween_property(sprite, "modulate", flash_color, duration/2)
	tween.tween_property(sprite, "modulate", original_color, duration/2)
	await tween.finished

# 抖动精灵（从GeneralAnimation移植过来的功能）
func _shake_sprite(sprite, intensity: float = 0.05, duration: float = 0.2):
	if not sprite:
		return
	
	original_position = sprite.global_position
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	# 抖动循环
	var shake_count = 5
	var shake_time = duration / shake_count
	
	for i in range(shake_count):
		var offset = Vector3(
			rng.randf_range(-intensity, intensity),
			rng.randf_range(-intensity, intensity),
			0
		)
		
		var tween = battle_scene.create_tween()
		tween.tween_property(sprite, "global_position", original_position + offset, shake_time)
		await tween.finished
	
	# 恢复原位
	var tween = battle_scene.create_tween()
	tween.tween_property(sprite, "global_position", original_position, shake_time)
	await tween.finished

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
	
