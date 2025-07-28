class_name DefaultAnimation
extends BaseSkillAnimation

func setup(p_battle_scene: Node3D, p_general_animation: GeneralAnimation) -> void:
	super.setup(p_battle_scene, p_general_animation)
	# general_animation 已经在父类中设置好了，不需要额外处理

func play(phase: AnimationPhase, p_battle_event: BattleEvent) -> void:
	self.battle_event = p_battle_event
	
	match phase:
		AnimationPhase.PREPARE:
			await play_prepare()
		AnimationPhase.EXECUTE:
			await play_execute()
		AnimationPhase.FINISH:
			await play_finish()

# 准备阶段 - 保持简单
func play_prepare() -> void:
	await battle_scene.get_tree().create_timer(0.1).timeout
	animation_completed.emit()

# 执行阶段 - 实现占位符动画
func play_execute() -> void:
	# 在技能发起者头顶显示 "DefaultAnimation"
	var source = battle_event.source
	var sprite = battle_scene.find_character_sprite(source)
	if not sprite:
		push_error("DefaultAnimation: 找不到发起者精灵")
		animation_completed.emit()
		return
	
	# --- 创建占位符 Label3D ---
	var label = Label3D.new()
	label.text = "DefaultAnimation"
	label.font_size = 24
	label.modulate = Color.YELLOW # 使用醒目的黄色
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	
	# 先将节点添加到场景树
	battle_scene.add_child(label)
	
	# 然后再设置它的全局位置
	var start_pos = sprite.global_position + Vector3(0, 0.5, 0)
	label.global_position = start_pos
	
	# --- 创建上浮并消失的动画 ---
	var tween = battle_scene.create_tween()
	var end_pos = start_pos + Vector3(0, 1, 0)
	tween.tween_property(label, "global_position", end_pos, 1.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.5).set_delay(0.5)
	
	# 等待动画完成
	await tween.finished
	
	# 动画完成后，节点会自动被queue_free，我们只需要发出完成信号
	label.queue_free() # 确保动画完成后节点被移除
	
	animation_completed.emit()

# 结束阶段 - 保持简单
func play_finish() -> void:
	await battle_scene.get_tree().create_timer(0.1).timeout
	animation_completed.emit()
