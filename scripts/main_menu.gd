extends Node2D

const SETTINGS_SCENE := "res://Objects/SettingsMenu.tscn"
const GAMEPLAY_SCENE := "res://Worlds/World1.tscn"

func _on_settings_button_pressed() -> void:
	SceneTransition.goto_scene(SETTINGS_SCENE)

func _on_play_button_pressed() -> void:
	SceneTransition.goto_scene(GAMEPLAY_SCENE)
