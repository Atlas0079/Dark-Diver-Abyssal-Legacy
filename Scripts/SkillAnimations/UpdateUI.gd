extends RefCounted
class_name UpdateUI

var battle_scene: Node3D

# UI更新类型枚举
enum UpdateType {
	HP_CHANGE,           # 生命值变化
	MP_CHANGE,           # 魔法值/能量变化
	BUFF_ADDED,          # 增加状态效果
	BUFF_REMOVED,        # 移除状态效果
	BUFF_UPDATED,        # 更新状态效果
	DAMAGE_POPUP,        # 伤害数字弹出
	HEAL_POPUP,          # 治疗数字弹出
	STATE_CHANGED,       # 角色状态变化（如昏迷、死亡等）
	SKILL_READY,         # 技能准备完成
	SKILL_USED           # 技能使用完成
}

func _init(p_battle_scene: Node3D):
	battle_scene = p_battle_scene

# 根据事件自动更新UI
func update_from_event(battle_event: BattleEvent) -> void:
	if not battle_event:
		push_error("UpdateUI: 传入的BattleEvent为空")
		return
	
	# 根据事件类型进行不同处理
	match battle_event.event_type:
		BattleEvent.EventType.ACTIVE_SKILL, BattleEvent.EventType.PASSIVE_SKILL:
			_handle_skill_event(battle_event)
		BattleEvent.EventType.STATE_RESOLVE:
			_handle_state_event(battle_event)
		_:
			push_error("UpdateUI: 未知的事件类型")

# 处理技能事件
func _handle_skill_event(battle_event: BattleEvent) -> void:
	var skill_info = battle_event.skill_info
	var source = battle_event.source
	var targets = battle_event.targets
	
	# 处理技能消耗
	if skill_info.has("mp_cost") and skill_info.mp_cost > 0:
		update_mp(source, -skill_info.mp_cost)
	
	# 处理伤害效果
	if skill_info.has("damage"):
		for target in targets:
			if skill_info.damage > 0:
				show_damage_popup(target, skill_info.damage)
				update_hp(target, -skill_info.damage)
	
	# 处理治疗效果
	if skill_info.has("heal"):
		for target in targets:
			if skill_info.heal > 0:
				show_heal_popup(target, skill_info.heal)
				update_hp(target, skill_info.heal)
	
	# 处理buff效果
	if skill_info.has("buffs"):
		for target in targets:
			for buff in skill_info.buffs:
				add_buff(target, buff)

# 处理状态事件
func _handle_state_event(battle_event: BattleEvent) -> void:
	var state_info = battle_event.state_info
	var source = battle_event.source
	
	# 处理DOT伤害
	if state_info.has("dot_damage"):
		show_damage_popup(source, state_info.dot_damage)
		update_hp(source, -state_info.dot_damage)
	
	# 处理HOT治疗
	if state_info.has("hot_heal"):
		show_heal_popup(source, state_info.hot_heal)
		update_hp(source, state_info.hot_heal)
	
	# 处理状态移除
	if state_info.has("remove_buff"):
		remove_buff(source, state_info.remove_buff)

# 以下是手动更新UI的辅助函数，可以被动画脚本直接调用

# 更新生命值
func update_hp(character, change_amount: int) -> void:
	var hp_bar = battle_scene.find_character_ui(character, "HP")
	if hp_bar:
		var original_value = hp_bar.value
		hp_bar.value += change_amount
		
		# 添加动画效果
		var tween = battle_scene.create_tween()
		tween.tween_property(hp_bar, "value", hp_bar.value, 0.5)
	else:
		push_error("UpdateUI: 找不到角色的HP控件")

# 更新魔法值/能量
func update_mp(character, change_amount: int) -> void:
	var mp_bar = battle_scene.find_character_ui(character, "MP")
	if mp_bar:
		var original_value = mp_bar.value
		mp_bar.value += change_amount
		
		# 添加动画效果
		var tween = battle_scene.create_tween()
		tween.tween_property(mp_bar, "value", mp_bar.value, 0.5)
	else:
		push_error("UpdateUI: 找不到角色的MP控件")

# 显示伤害数字
func show_damage_popup(character, damage: int) -> void:
	var sprite = battle_scene.find_character_sprite(character)
	if not sprite:
		push_error("UpdateUI: 找不到角色精灵")
		return
	
	# 创建伤害数字实例
	# 注意：这里假设您有一个伤害数字场景，根据实际情况调整
	var damage_popup = load("res://Scenes/UI/DamagePopup.tscn").instantiate()
	battle_scene.add_child(damage_popup)
	
	# 设置伤害数字属性
	damage_popup.global_position = sprite.global_position + Vector3(0, 0.5, 0)
	damage_popup.set_damage(damage)
	damage_popup.pop()

# 显示治疗数字
func show_heal_popup(character, heal: int) -> void:
	var sprite = battle_scene.find_character_sprite(character)
	if not sprite:
		push_error("UpdateUI: 找不到角色精灵")
		return
	
	# 创建治疗数字实例
	# 注意：这里假设您有一个治疗数字场景，根据实际情况调整
	var heal_popup = load("res://Scenes/UI/HealPopup.tscn").instantiate()
	battle_scene.add_child(heal_popup)
	
	# 设置治疗数字属性
	heal_popup.global_position = sprite.global_position + Vector3(0, 0.5, 0)
	heal_popup.set_heal(heal)
	heal_popup.pop()

# 添加状态效果图标
func add_buff(character, buff_data: Dictionary) -> void:
	var buff_container = battle_scene.find_character_ui(character, "BuffContainer")
	if not buff_container:
		push_error("UpdateUI: 找不到角色的Buff容器")
		return
	
	# 创建buff图标实例
	# 注意：这里假设您有一个buff图标场景，根据实际情况调整
	var buff_icon = load("res://Scenes/UI/BuffIcon.tscn").instantiate()
	buff_container.add_child(buff_icon)
	
	# 设置buff图标属性
	buff_icon.set_buff_data(buff_data)
	
	# 添加出现动画
	buff_icon.play_add_animation()

# 移除状态效果图标
func remove_buff(character, buff_id: String) -> void:
	var buff_container = battle_scene.find_character_ui(character, "BuffContainer")
	if not buff_container:
		push_error("UpdateUI: 找不到角色的Buff容器")
		return
	
	# 查找对应的buff图标
	var buff_icon = null
	for child in buff_container.get_children():
		if child.buff_id == buff_id:
			buff_icon = child
			break
	
	if buff_icon:
		# 播放移除动画
		buff_icon.play_remove_animation()
		await buff_icon.animation_finished
		buff_icon.queue_free()
	else:
		push_error("UpdateUI: 找不到要移除的Buff图标: " + buff_id)

# 更新角色状态（如昏迷、死亡等）
func update_character_state(character, new_state: String) -> void:
	var sprite = battle_scene.find_character_sprite(character)
	if not sprite:
		push_error("UpdateUI: 找不到角色精灵")
		return
	
	# 根据状态调整角色外观
	match new_state:
		"dead":
			# 角色死亡效果
			var tween = battle_scene.create_tween()
			tween.tween_property(sprite, "modulate", Color(0.5, 0.5, 0.5, 0.5), 0.5)
		"stunned":
			# 角色眩晕效果
			var stun_effect = load("res://Scenes/Effects/StunEffect.tscn").instantiate()
			sprite.add_child(stun_effect)
			stun_effect.position = Vector3(0, 0.7, 0)
		_:
			# 恢复正常状态
			sprite.modulate = Color(1, 1, 1, 1)
			# 移除可能存在的特效
			for child in sprite.get_children():
				if child.is_in_group("status_effects"):
					child.queue_free()
