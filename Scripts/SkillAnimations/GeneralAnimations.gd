# GeneralAnimation.gd
class_name GeneralAnimation
extends Node

# 静态函数，用于播放闪避动画
static func play_dodge_animation(target_sprite: Sprite3D, battle_scene: Node3D):
	# 创建MISS标签
	var miss_label = Label3D.new()
	var font = load("res://Assets/UI/Xim-Sans-Brahmic-3.ttf")
	if font:
		miss_label.font = font
	miss_label.text = "MISS"
	miss_label.font_size = 96
	miss_label.modulate = Color(0.5, 0.5, 1)  # 蓝色
	miss_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	miss_label.no_depth_test = true
	miss_label.render_priority = 100
	miss_label.double_sided = true
	miss_label.outline_size = 12
	miss_label.outline_modulate = Color.BLACK
	miss_label.outline_render_priority = 99
	miss_label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	# 添加MISS标签到场景
	battle_scene.get_node("Effects").add_child(miss_label)
	miss_label.global_position = target_sprite.global_position + Vector3(0, 0.8, -0.2)

	# 获取目标原始位置和后退位置
	var original_position = target_sprite.global_position
	var is_blue_team = target_sprite.get_parent().name == "left_team"
	var back_direction = Vector3(-0.5, 0, 0) if is_blue_team else Vector3(0.5, 0, 0)
	var back_position = original_position + back_direction

	# 创建单个tween来处理所有动画
	var dodge_tween = battle_scene.create_tween()

	# 1. 角色后退并开始半透明
	dodge_tween.parallel().tween_property(target_sprite, "global_position",
			back_position, 0.2) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	dodge_tween.parallel().tween_property(target_sprite, "modulate:a",
			0.5, 0.2) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# 2. MISS标签上升动画
	dodge_tween.parallel().tween_property(miss_label, "global_position:y",
			miss_label.global_position.y + 0.8, 1.0) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	# 3. MISS标签淡出动画
	dodge_tween.parallel().tween_property(miss_label, "modulate:a",
			0, 0.3) \
		.set_delay(0.7)

	# 4. 角色返回原位并恢复不透明
	dodge_tween.parallel().tween_property(target_sprite, "global_position",
			original_position, 0.2) \
		.set_delay(0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)
	dodge_tween.parallel().tween_property(target_sprite, "modulate:a",
			1.0, 0.2) \
		.set_delay(0.4) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_OUT)

	await dodge_tween.finished
	miss_label.queue_free()

# 静态函数，用于播放普通受击动画
static func play_hit_animation(target_sprite: Sprite3D, damage: int, battle_scene: Node3D):
	# 目标闪红光
	var hit_tween = battle_scene.create_tween()
	hit_tween.tween_property(target_sprite, "modulate", Color(1, 0, 0), 0.1)
	hit_tween.tween_property(target_sprite, "modulate", Color(1, 1, 1), 0.1)

	# 显示伤害数字
	if damage > 0:
		var damage_label = create_damage_label(damage)
		battle_scene.get_node("Effects").add_child(damage_label)
		damage_label.global_position = target_sprite.global_position + Vector3(0, 0.8, -0.2)

		var label_tween = battle_scene.create_tween()
		label_tween.tween_property(damage_label, "global_position:y",
				damage_label.global_position.y + 0.5, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(damage_label, "global_position:y",
				damage_label.global_position.y + 0.3, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await battle_scene.get_tree().create_timer(0.5).timeout
		var fade_tween = battle_scene.create_tween()
		fade_tween.tween_property(damage_label, "modulate:a", 0, 0.3)
		await fade_tween.finished
		damage_label.queue_free()

# 静态函数，用于创建伤害数字标签
static func create_damage_label(damage: int) -> Label3D:
	var label = Label3D.new()
	var font = load("res://Assets/UI/Xim-Sans-Brahmic-3.ttf")
	if font:
		label.font = font
	label.text = str(damage)
	label.font_size = 96
	label.modulate = Color(1, 0, 0)  # 红色
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 100
	label.double_sided = true
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	label.outline_render_priority = 99
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return label

# 静态函数，用于播放格挡动画
static func play_block_animation(target_sprite: Sprite3D, damage: int, battle_scene: Node3D):
	# 目标闪白光
	var material = target_sprite.material_override
	if material is StandardMaterial3D:
		var original_color = material.albedo_color
		material.albedo_color = Color.WHITE
		await battle_scene.get_tree().create_timer(0.1).timeout
		material.albedo_color = original_color

	# 显示格挡伤害数字
	if damage > 0:
		var damage_label = create_block_damage_label(damage)
		battle_scene.get_node("Effects").add_child(damage_label)
		damage_label.global_position = target_sprite.global_position + Vector3(0, 0.8, -0.2)

		var label_tween = battle_scene.create_tween()
		label_tween.tween_property(damage_label, "global_position:y",
				damage_label.global_position.y + 0.5, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		label_tween.tween_property(damage_label, "global_position:y",
				damage_label.global_position.y + 0.3, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		await battle_scene.get_tree().create_timer(0.5).timeout
		var fade_tween = battle_scene.create_tween()
		fade_tween.tween_property(damage_label, "modulate:a", 0, 0.3)
		await fade_tween.finished
		damage_label.queue_free()



# 静态函数，用于创建格挡伤害数字标签（淡蓝色）
static func create_block_damage_label(damage: int) -> Label3D:
	var label = Label3D.new()
	var font = load("res://Assets/UI/Xim-Sans-Brahmic-3.ttf")
	if font:
		label.font = font
	label.text = str(damage)
	label.font_size = 96
	label.modulate = Color(0.5, 0.7, 1)  # 淡蓝色
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.render_priority = 100
	label.double_sided = true
	label.outline_size = 12
	label.outline_modulate = Color.BLACK
	label.outline_render_priority = 99
	label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return label
