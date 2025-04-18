extends RefCounted
class_name BaseSkillAnimation

signal animation_completed  # 添加动画完成信号

var battle_scene: Node3D
var battle_event: BattleEvent

enum AnimationPhase {
	PREPARE,    # 准备阶段 (如起手动作)
	EXECUTE,    # 执行阶段 (主要动画)
	FINISH      # 结束阶段 (收招动作)
}


func setup(p_battle_scene: Node3D,) -> void:
	battle_scene = p_battle_scene


func play(phase: AnimationPhase, battle_event: BattleEvent) -> void: 
	push_error("BaseSkillAnimation.play() 需要被子类重写")

func extra_event(animation_queue: Array, current_event: BattleEvent):
	#push_error("BaseSkillAnimation.extra_event() 需要被子类重写")
	pass
