class_name CoverReturnAnimation
extends BaseSkillAnimation

var general_animation: GeneralAnimation
var ui_updater: UpdateUI

func setup(p_battle_scene: Node3D) -> void:
	self.battle_scene = p_battle_scene

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
	var timer = self.battle_scene.get_tree().create_timer(0.1)
	await timer.timeout
	
	self.animation_completed.emit()

func play_execute() -> void:
	# 获取使用者精灵
	var user_sprite = battle_scene.find_character_sprite(battle_event.source)
	if not user_sprite:
		push_error("无法找到使用者精灵")
		self.animation_completed.emit()  # 发出信号
		return
	
	# 获取原始位置
	var original_position = battle_event.skill_info.get("original_position")
	if not original_position:
		push_error("无法获取原始位置信息")
		self.animation_completed.emit()  # 发出信号
		return
	
	# 角色返回原位
	var tween = battle_scene.create_tween()
	tween.tween_property(user_sprite, "global_position", original_position, 0.3)
	
	# 使用await等待tween完成，然后发出信号
	await tween.finished
	self.animation_completed.emit()

func play_finish() -> void:
	var timer = self.battle_scene.get_tree().create_timer(0.1)
	await timer.timeout
	
	self.animation_completed.emit()
