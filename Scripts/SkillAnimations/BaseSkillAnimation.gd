extends RefCounted
class_name BaseSkillAnimation

var battle_scene: Node3D
var user: Character
var effects_results: Dictionary

enum AnimationPhase {
	PREPARE,    # 准备阶段 (如起手动作)
	EXECUTE,    # 执行阶段 (主要动画)
	FINISH      # 结束阶段 (收招动作)
}

func _init() -> void:
	pass

func setup(p_battle_scene: Node3D, p_user: Character, p_effects_results: Dictionary) -> void:
	battle_scene = p_battle_scene
	user = p_user
	effects_results = p_effects_results

func play(phase: AnimationPhase) -> void:
	push_error("BaseSkillAnimation.play() 需要被子类重写")

func extra_event(event: Dictionary) -> void:
	pass