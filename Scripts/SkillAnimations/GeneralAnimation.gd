extends RefCounted
class_name GeneralAnimation

var battle_scene: Node3D
var ui_updater: UpdateUI

# 特效资源路径
const EFFECT_PATHS = {
	"hit": "res://Scenes/Effects/HitEffect.tscn",
	"heal": "res://Scenes/Effects/HealEffect.tscn",
	"block": "res://Scenes/Effects/ShieldEffect.tscn",
	"buff": "res://Scenes/Effects/BuffEffect.tscn",
	"debuff": "res://Scenes/Effects/DebuffEffect.tscn",
}

func _init(p_battle_scene: Node3D, p_ui_updater: UpdateUI = null):
	battle_scene = p_battle_scene
	ui_updater = p_ui_updater if p_ui_updater else UpdateUI.new(p_battle_scene)

# ------------ 通用特效函数 ------------

# 播放受击特效
func play_hit_effect(target, effect_type: String = "hit") -> void:
	var sprite = battle_scene.find_character_sprite(target)
	if not sprite:
		push_error("GeneralAnimation: 找不到目标精灵")
		return
	
	if not EFFECT_PATHS.has(effect_type):
		effect_type = "hit"  # 默认使用普通受击特效
	
	var effect_scene = load(EFFECT_PATHS[effect_type])
	if not effect_scene:
		push_error("GeneralAnimation: 无法加载特效场景: " + EFFECT_PATHS[effect_type])
		return
	
	var effect = effect_scene.instantiate()
	battle_scene.add_child(effect)
	
	# 设置特效位置和播放
	effect.global_position = sprite.global_position
	effect.play()
	
	# 使目标精灵闪烁表示受击
	_flash_sprite(sprite)
	
	# 等待特效完成
	await effect.animation_finished
	effect.queue_free()



# ------------ 角色移动函数 ------------



# 角色跳跃
func jump(character, height: float = 0.5, duration: float = 0.5) -> void:
	var sprite = battle_scene.find_character_sprite(character)
	if not sprite:
		push_error("GeneralAnimation: 找不到角色精灵")
		return
	
	var original_position = sprite.global_position
	var jump_position = original_position + Vector3(0, height, 0)
	
	# 创建跳跃动画
	var tween = battle_scene.create_tween()
	tween.tween_property(sprite, "global_position", jump_position, duration/2).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "global_position", original_position, duration/2).set_ease(Tween.EASE_IN)
	await tween.finished

# 角色抖动（受击反馈）
func shake(character, intensity: float = 0.05, duration: float = 0.2) -> void:
	var sprite = battle_scene.find_character_sprite(character)
	if not sprite:
		push_error("GeneralAnimation: 找不到角色精灵")
		return
	
	var original_position = sprite.global_position
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

# ------------ 辅助函数 ------------

# 使精灵闪烁
func _flash_sprite(sprite, flash_color: Color = Color(1, 1, 1, 1), duration: float = 0.2) -> void:
	if not sprite:
		return
	
	var original_color = sprite.modulate
	
	# 创建闪烁动画
	var tween = battle_scene.create_tween()
	tween.tween_property(sprite, "modulate", flash_color, duration/2)
	tween.tween_property(sprite, "modulate", original_color, duration/2)
	await tween.finished

# ------------ 使用UI更新函数的快捷方式 ------------

# 显示伤害数字
func show_damage(target, damage: int) -> void:
	ui_updater.show_damage_popup(target, damage)

# 显示治疗数字
func show_heal(target, heal: int) -> void:
	ui_updater.show_heal_popup(target, heal)

# 更新生命值
func update_hp(character, change_amount: int) -> void:
	ui_updater.update_hp(character, change_amount)

# 更新魔法值/能量
func update_mp(character, change_amount: int) -> void:
	ui_updater.update_mp(character, change_amount)

# 播放完整的受击动画序列（异步）
# 这个函数现在是异步的，调用方可以 await 它
func play_hit_sequence(target: Character, effect_package: Dictionary) -> void:
	
	var hit_type = effect_package.get("hit_type", "normal")
	var damage = effect_package.get("damage", 0)
	var heal = effect_package.get("heal", 0)
	
	# 根据命中类型播放不同效果
	match hit_type:
		"miss":
			_popup_text(target, "闪避", Color.GRAY)
			# TODO: 在这里播放闪避动画
			await battle_scene.get_tree().create_timer(0.6) # 等待一个动画时间
			return # 闪避了，直接结束，不处理伤害

		"block":
			_popup_text(target, "格挡", Color.CYAN)
			# TODO: 在这里播放格挡动画
			play_hit_effect(target, "block")
			# 格挡后可能依然有伤害，所以流程继续

		"crit":
			_popup_text(target, "暴击!", Color.ORANGE_RED)
			# 暴击流程继续，处理伤害
			play_hit_effect(target, "crit")

		"normal":
			# 普通命中，流程继续
			pass 

	# --- 处理伤害/治疗的视觉效果 ---
	if damage > 0:
		# 播放伤害特效
		var effect_type = effect_package.get("element", "hit")
		play_hit_effect(target, effect_type)
		
		# 显示伤害数字
		show_damage(target, damage)
		
		# 更新HP
		update_hp(target, -damage)
		
		# 等待角色抖动动画完成
		await shake(target)

	if heal > 0:
		# 播放治疗特效
		play_hit_effect(target, "heal")
		
		# 显示治疗数字
		show_heal(target, heal)
		
		# 更新HP
		update_hp(target, heal)
		
		# 等待一个短暂的延迟
		await battle_scene.get_tree().create_timer(0.3).timeout

# 创建一个通用的文字弹出函数（发射后不管）
func _popup_text(target: Character, text: String, color: Color) -> void:
	var sprite = battle_scene.find_character_sprite(target)
	if not sprite:
		return
		
	var label = Label3D.new()
	label.text = text
	label.font_size = 28
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.pixel_size = 0.01
	
	battle_scene.add_child(label)
	
	var start_pos = sprite.global_position + Vector3(0, 1.8, 0) # 放在比伤害数字稍高一点的位置
	label.global_position = start_pos
	
	# 创建一个 tween，并绑定到 label 节点上
	# 这样即使 GeneralAnimation 对象被销毁，tween 也能继续执行
	var tween = label.create_tween() 
	
	var end_pos = start_pos + Vector3(0, 0.5, 0)
	tween.tween_property(label, "global_position", end_pos, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.4).set_delay(0.2)
	
	# 让 tween 在完成后自动调用 label 的 queue_free 方法
	tween.tween_callback(label.queue_free)

# 从BattleEvent自动处理UI和动画效果（这个函数现在可以被废弃，或只用于非常简单的情况）
func handle_battle_event(battle_event: BattleEvent) -> void:
	# ... (保留或删除) ...
	pass
