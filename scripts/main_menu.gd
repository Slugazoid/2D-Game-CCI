extends Node2D

const SETTINGS_SCENE := "res://Objects/SettingsMenu.tscn"
const GAMEPLAY_SCENE := "res://Worlds/World1.tscn"
const MAIN_MUSIC := "res://audio/main_music.tscn"


func _on_settings_button_pressed() -> void:
	SceneTransition.goto_scene(SETTINGS_SCENE)


func _on_play_button_pressed() -> void:
	MainMusic.fade_out(1.0)
	SceneTransition.goto_scene(GAMEPLAY_SCENE)
	
