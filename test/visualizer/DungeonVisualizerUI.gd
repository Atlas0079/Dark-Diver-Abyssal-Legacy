extends Control

@onready var visualizer = $DungeonVisualizer

func _ready():
	$RegenerateButton.pressed.connect(_on_regenerate_pressed)

func _on_regenerate_pressed():
	visualizer._on_regenerate_button_pressed() 
