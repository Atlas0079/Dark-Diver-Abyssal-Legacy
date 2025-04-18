class_name CoverAnimation
extends BaseSkillAnimation

var original_position: Vector3
var target_sprite: Sprite3D
var user_sprite: Sprite3D
var prepare_effect: AnimatedSprite3D
var general_animation: GeneralAnimation
var ui_updater: UpdateUI

# 添加extra_event函数，处理额外事件逻辑
func extra_event(animation_queue: Array, current_event: BattleEvent) -> Array:

	var extra_events = []
	user_sprite = battle_scene.find_character_sprite(current_event.source)
	original_position = user_sprite.global_position
	# 如果当前事件在队列中的位置是最后一个，则直接返回空数组
	var current_index = animation_queue.find(current_event)
	if current_index == animation_queue.size() - 1:
		return extra_events
	
	# 从当前事件之后开始找下一个主动技能事件
	var next_active_skill_event = null
	var next_active_skill_index = -1
	
	for i in range(current_index + 1, animation_queue.size()):
		var event = animation_queue[i]
		if event.event_type == BattleEvent.EventType.ACTIVE_SKILL:
			next_active_skill_event = event
			next_active_skill_index = i
			break
	
	# 如果找到了下一个主动技能事件，在它后面插入标记事件
	if next_active_skill_event != null:
		# 创建一个标记事件，用于角色返回动画
		var mark_event = BattleEvent.new()
		mark_event.event_type = BattleEvent.EventType.MARK_EVENT
		mark_event.turn_number = current_event.turn_number
		mark_event.source = current_event.source
		mark_event.targets = current_event.targets.duplicate()
		
		# 获取保护的目标
		var protected_target = null
		if current_event.targets.size() > 0:
			protected_target = current_event.targets[0]
		
		# 标记事件包含返回动画所需信息
		mark_event.skill_info = {
			"animation": "cover_return",
			"skill_name": "保护返回",
			"original_skill": "cover",
			"original_position": original_position,
			"protected_target": protected_target  # 添加保护目标信息
		}
		
		# 将标记事件与位置信息打包成字典，插入到下一个主动技能事件之后
		extra_events.append({
			"position": next_active_skill_index + 1,  # 在下一个主动技能事件之后
			"event": mark_event
		})
	print("CoverAnimation.extra_event 返回事件: %s" % extra_events)
	return extra_events

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
	if not user_sprite:
		push_error("无法找到使用者精灵")
		animation_completed.emit()  # 发出信号
		return
		
	# 保存原始位置
	original_position = user_sprite.global_position

	var protected_target = battle_event.skill_info.get("protected_target")
	# 如果没有指定保护目标，则使用第一个目标
	if protected_target:
		target_sprite = battle_scene.find_character_sprite(protected_target)
	else:
		# 兼容原来的逻辑，使用第一个目标
		push_error("无法找到目标精灵，使用第一个目标")
		target_sprite = battle_scene.find_character_sprite(battle_event.targets[0])
	
	if not target_sprite:
		push_error("无法找到目标精灵")
		animation_completed.emit()  # 发出信号
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
	
	# 计算目标位置
	var target_position = target_sprite.global_position
	
	# 确定角色所在队伍及位置调整
	var is_source_blue_team = battle_scene.battle.get_character_team(battle_event.source) == "blue"
	
	# 根据队伍位置调整X方向偏移
	var x_offset = 0.5
	# 如果是蓝队（左边），角色应该站在目标左边
	if is_source_blue_team:
		x_offset = 1
	else:
		# 如果是红队（右边），角色应该站在目标右边
		x_offset = -1
	
	target_position.x += x_offset
	
	# 创建跳跃动画效果
	var tween = battle_scene.create_tween()
	tween.set_parallel(true) # 允许并行动画
	
	# 起始点和目标点
	var start_pos = user_sprite.global_position
	var jump_height = 1.0 # 跳跃高度
	
	# X和Z方向的直线移动
	tween.tween_property(user_sprite, "global_position:x", target_position.x - 0.2, 0.3)
	tween.tween_property(user_sprite, "global_position:z", target_position.z, 0.3)
	
	# Y方向的抛物线移动（跳跃效果）
	# 第一阶段：向上跳
	var mid_tween = battle_scene.create_tween()
	mid_tween.tween_property(user_sprite, "global_position:y", start_pos.y + jump_height, 0.15)
	# 第二阶段：落下
	mid_tween.tween_property(user_sprite, "global_position:y", target_position.y, 0.15)
	
	# 等待动画完成
	await tween.finished
	await mid_tween.finished
	
	# 发出动画完成信号
	animation_completed.emit()

func play_execute() -> void:
	var timer = self.battle_scene.get_tree().create_timer(0.1)
	await timer.timeout
	
	self.animation_completed.emit()

func play_finish() -> void:
	# 清理动画资源
	if prepare_effect:
		prepare_effect.queue_free()
	var timer = self.battle_scene.get_tree().create_timer(0.1)
	await timer.timeout
	
	self.animation_completed.emit()
