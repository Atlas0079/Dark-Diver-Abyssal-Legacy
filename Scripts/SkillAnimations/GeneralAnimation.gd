extends RefCounted
class_name GeneralAnimation

var battle_scene: Node3D
var ui_updater: UpdateUI

# 特效资源路径
const EFFECT_PATHS = {
	"hit": "res://Scenes/Effects/HitEffect.tscn",
	"slash": "res://Scenes/Effects/SlashEffect.tscn",
	"fire": "res://Scenes/Effects/FireEffect.tscn",
	"ice": "res://Scenes/Effects/IceEffect.tscn",
	"lightning": "res://Scenes/Effects/LightningEffect.tscn",
	"heal": "res://Scenes/Effects/HealEffect.tscn",
	"shield": "res://Scenes/Effects/ShieldEffect.tscn",
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

# 播放治疗特效
func play_heal_effect(target) -> void:
	play_hit_effect(target, "heal")

# 播放护盾特效
func play_shield_effect(target) -> void:
	play_hit_effect(target, "shield")

# 播放增益效果特效
func play_buff_effect(target) -> void:
	play_hit_effect(target, "buff")

# 播放减益效果特效
func play_debuff_effect(target) -> void:
	play_hit_effect(target, "debuff")

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

# 播放伤害动画组合（特效+数字+抖动+HP更新）
func play_damage_sequence(target, damage: int, effect_type: String = "hit") -> void:
	# 播放特效
	play_hit_effect(target, effect_type)
	
	# 显示伤害数字
	show_damage(target, damage)
	
	# 角色抖动
	shake(target)
	
	# 更新HP
	update_hp(target, -damage)

# 播放治疗动画组合（特效+数字+HP更新）
func play_heal_sequence(target, heal: int) -> void:
	# 播放特效
	play_heal_effect(target)
	
	# 显示治疗数字
	show_heal(target, heal)
	
	# 更新HP
	update_hp(target, heal)

# 从BattleEvent自动处理UI和动画效果
func handle_battle_event(battle_event: BattleEvent) -> void:
	# 更新UI
	ui_updater.update_from_event(battle_event)
	
	# 根据事件类型和技能信息添加适当的视觉效果
	if battle_event.event_type == BattleEvent.EventType.ACTIVE_SKILL or battle_event.event_type == BattleEvent.EventType.PASSIVE_SKILL:
		var skill_info = battle_event.skill_info
		var targets = battle_event.targets
		
		# 处理伤害效果的视觉表现
		if skill_info.has("damage") and skill_info.damage > 0:
			var effect_type = skill_info.get("element", "hit")
			for target in targets:
				play_damage_sequence(target, skill_info.damage, effect_type)
		
		# 处理治疗效果的视觉表现
		if skill_info.has("heal") and skill_info.heal > 0:
			for target in targets:
				play_heal_sequence(target, skill_info.heal)
	
	# 处理状态效果
	elif battle_event.event_type == BattleEvent.EventType.STATE_RESOLVE:
		var state_info = battle_event.state_info
		var source = battle_event.source
		
		# 处理DOT伤害的视觉表现
		if state_info.has("dot_damage") and state_info.dot_damage > 0:
			var effect_type = state_info.get("element", "hit")
			play_damage_sequence(source, state_info.dot_damage, effect_type)
		
		# 处理HOT治疗的视觉表现
		if state_info.has("hot_heal") and state_info.hot_heal > 0:
			play_heal_sequence(source, state_info.hot_heal)
