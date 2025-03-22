extends RefCounted
class_name BaseSkillAnimation

signal animation_completed
signal animation_ready # 新增信号，用于表示准备动作完成
signal skill_animation_completed # 用于通知主技能动画完成

var battle_scene: Node3D
var user: Character
var effects_results: Dictionary

func _init() -> void:
	pass

func setup(p_battle_scene: Node3D, p_user: Character, p_effects_results: Dictionary) -> void:
	battle_scene = p_battle_scene
	user = p_user
	effects_results = p_effects_results

func play() -> void:
	push_error("BaseSkillAnimation.play() 需要被子类重写")

func find_sprite(character: Character) -> Sprite3D:
	return battle_scene.find_character_sprite(character)

func create_tween() -> Tween:
	return battle_scene.create_tween()

func get_effects_node() -> Node:
	return battle_scene.get_node("Effects")
