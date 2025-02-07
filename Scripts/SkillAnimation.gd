# res://Scripts/SkillAnimation.gd
# AutoLoad

extends Node

var battle_scene: Node3D
var battle: Battle

func setup_scene(scene: Node3D):
	battle_scene = scene
	battle = scene.battle  # 获取 Battle 实例的引用
	print("动画系统初始化完成，battle实例：", battle)  # 添加调试信息

func play_skill_animation(skill: BaseSkill, user: Character, effects_results: Dictionary) -> void:
	print("开始播放技能动画: ", skill.skill_name)
	
	if battle_scene:
		battle_scene.is_animation_playing = true  # 设置动画播放标志
	
	# 获取精灵节点
	var user_sprite: Sprite3D = battle_scene.find_character_sprite(user)
	if not user_sprite:
		print("未找到用户精灵节点")
		_finish_animation()
		return
		
	print("获取到精灵节点: ", user_sprite)
	
	# 根据技能类型播放对应动画
	match skill.animation:
		"slash":
			var slash = preload("res://Scripts/SkillAnimations/Slash.gd")
			await slash.play(battle_scene, user, effects_results) 
		"fireball":
			pass
		_:
			pass
	
	_finish_animation()

# 添加动画完成处理函数
func _finish_animation() -> void:
	print("动画完成 animation_completed")
	if battle:
		battle.emit_signal("animation_completed")
	else:
		push_error("Battle实例为空")
	if battle_scene:
		battle_scene.is_animation_playing = false
