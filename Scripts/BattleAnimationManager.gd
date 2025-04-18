extends Node
class_name BattleAnimationManager

var battle_scene: BattleScene
var animation_map = {
	"slash": "res://Scripts/SkillAnimations/SlashAnimation.gd",
	"cover_return": "res://Scripts/SkillAnimations/CoverReturnAnimation.gd",
	"cover": "res://Scripts/SkillAnimations/CoverAnimation.gd",
	# 这里可以添加更多的动画脚本映射
}

var animation_instances = {}
var ui_updater: UpdateUI
var general_animation: GeneralAnimation

func _init(p_battle_scene: BattleScene): 
	battle_scene = p_battle_scene
	
	# 初始化UI更新器和通用动画控制器
	ui_updater = UpdateUI.new(battle_scene)
	general_animation = GeneralAnimation.new(battle_scene, ui_updater)
	
	# 预加载所有技能动画脚本
	for anim_name in animation_map:
		var script_path = animation_map[anim_name]
		var script = load(script_path)
		if script:
			var animation_instance = script.new()
			animation_instance.setup(battle_scene)
			animation_instances[anim_name] = animation_instance
		else:
			push_error("无法加载动画脚本: " + script_path)

# 根据事件构建动画队列
func build_animation_queue(battle_events: Array) -> Array:
	print("BattleAnimationManager.build_animation_queue 开始处理 %d 个事件" % battle_events.size())
	var animation_queue = []
	
	# 首先将所有原始事件添加到队列中
	for event in battle_events:
		animation_queue.append(event)
		print("BattleAnimationManager.build_animation_queue 添加原始事件类型: %s" % event.event_type)
	
	# 创建一个新的队列用于存储额外事件
	var extra_events_to_add = []
	
	# 遍历所有原始事件，收集需要添加的额外事件
	for index in range(battle_events.size()):
		var event = battle_events[index]
		
		# 检查是否有对应的动画脚本
		var animation_name = event.skill_info.get("animation") if event.skill_info else null
		if not animation_name and event.state_info:
			animation_name = event.state_info.get("animation")
			
		if animation_name and animation_instances.has(animation_name):
			var animation = animation_instances[animation_name]
			print("BattleAnimationManager.build_animation_queue 找到动画脚本: %s" % animation_name)
			
			# 获取额外事件（如果有），传入完整的事件队列
			if animation.has_method("extra_event"):
				print("BattleAnimationManager.build_animation_queue 调用 %s.extra_event" % animation_name)
				var extra_events = animation.extra_event(animation_queue, event)
				if extra_events:
					print("BattleAnimationManager.build_animation_queue extra_event 返回 %d 个事件" % extra_events.size())
					
					if extra_events.size() > 0:
						# 收集额外事件及其插入位置
						for extra_event in extra_events:
							extra_events_to_add.append(extra_event)
	
	# 处理所有收集到的额外事件
	# 按照位置从大到小排序，以便从后向前插入不会影响前面的位置
	extra_events_to_add.sort_custom(func(a, b): 
		var pos_a = a.get("position", animation_queue.size()) if a is Dictionary else animation_queue.size()
		var pos_b = b.get("position", animation_queue.size()) if b is Dictionary else animation_queue.size()
		return pos_a > pos_b
	)
	
	# 插入所有额外事件
	for extra_item in extra_events_to_add:
		if extra_item is Dictionary and extra_item.has("position") and extra_item.has("event"):
			var position = extra_item.get("position", animation_queue.size())
			position = min(position, animation_queue.size())
			print("BattleAnimationManager.build_animation_queue 在位置 %d 插入额外事件" % position)
			animation_queue.insert(position, extra_item.get("event"))
		else:
			print("BattleAnimationManager.build_animation_queue 添加额外事件到队列末尾")
			animation_queue.append(extra_item)
	
	print("BattleAnimationManager.build_animation_queue 最终动画队列包含 %d 个事件" % animation_queue.size())
	return animation_queue

# 播放动画队列
func play_animation_with_queue(animation_queue: Array) -> void:
	for event in animation_queue:
		await play_single_animation(event)

# 播放单个事件的动画
func play_single_animation(battle_event: BattleEvent) -> void:
	
	# 获取动画名称
	var animation_name = battle_event.skill_info.get("animation")
	if animation_name == null:
		animation_name = battle_event.state_info.get("animation")
	
	print("BattleAnimationManager.play_single_animation - 动画名称: %s" % str(animation_name))
	
	if animation_name and animation_instances.has(animation_name):
		# 使用指定的动画脚本
		var animation = animation_instances[animation_name]
		print("BattleAnimationManager.play_single_animation - 找到对应动画实例: %s" % animation)
		
		# 播放各个阶段的动画
		print("BattleAnimationManager.play_single_animation - 播放准备动画")
		animation.play(BaseSkillAnimation.AnimationPhase.PREPARE, battle_event)
		await animation.animation_completed  # 等待准备阶段完成信号
		
		print("BattleAnimationManager.play_single_animation - 播放执行动画")
		animation.play(BaseSkillAnimation.AnimationPhase.EXECUTE, battle_event)
		await animation.animation_completed  
		
		print("BattleAnimationManager.play_single_animation - 播放结束动画")
		animation.play(BaseSkillAnimation.AnimationPhase.FINISH, battle_event)
		await animation.animation_completed
	else:
		# 如果没有指定动画或找不到对应脚本，使用通用动画处理
		print("BattleAnimationManager.play_single_animation - 没有找到对应动画，使用默认动画处理: %s" % animation_name)
		await _play_default_animation(battle_event)

# 默认的动画处理（使用GeneralAnimation自动处理）
func _play_default_animation(battle_event: BattleEvent) -> void:
	# 使用GeneralAnimation自动处理事件的UI和特效
	general_animation.handle_battle_event(battle_event)
	
	# 等待一小段时间，使动画效果更明显
	await battle_scene.get_tree().create_timer(0.3).timeout
	
# 获取UI更新器，供其他脚本使用
func get_ui_updater() -> UpdateUI:
	return ui_updater

# 获取通用动画控制器，供其他脚本使用
func get_general_animation() -> GeneralAnimation:
	return general_animation
