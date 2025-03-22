extends Control

@onready var hp_bar = $HealthProgressBar
@onready var mp_bar = $ManaProgressBar
@onready var qi_bar = $QiProgressBar
@onready var ap_bar = $APProgressBar

var current_character: Character = null

func _ready():
	pass

func setup_with_character(character: Character):
	current_character = character
	show_all_bars()
	update_display()

func clear():
	current_character = null
	hide_all_bars()

func show_all_bars():
	if hp_bar: hp_bar.show()
	if mp_bar: mp_bar.show()
	if qi_bar: qi_bar.show()
	
	if ap_bar: ap_bar.show()

func hide_all_bars():
	if hp_bar: hp_bar.hide()
	if mp_bar: mp_bar.hide()
	if qi_bar: qi_bar.hide()
	if ap_bar: ap_bar.hide()

func update_display():
	if current_character == null:
		hide_all_bars()
		return
		
	show_all_bars()
	
	update_bar(hp_bar, current_character.resources.health.current, current_character.resources.health.max)
	update_bar(mp_bar, current_character.resources.mana.current, current_character.resources.mana.max)
	update_bar(qi_bar, current_character.resources.qi.current, current_character.resources.qi.max)
	update_bar(ap_bar, current_character.battle_stats.action_point, current_character.battle_stats.action_threshold)

func update_bar(bar, current, max_value):
	bar.max_value = max_value
	bar.value = current

func _process(delta):
	pass
	#update_display()
