extends Node2D

@onready var game_over: AudioStreamPlayer2D = $GameOver

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_over.play()

func _on_yes_button_pressed() -> void:
	SceneTransition.goto_scene("res://Worlds/World1.tscn")
	

func _on_no_button_pressed() -> void:
	SceneTransition.goto_scene("res://Objects/MainMenu.tscn")
