extends Node2D

const SETTINGS_SCENE := "res://Objects/SettingsMaenu.tscn"
const GAMEPLAY_SCENE := "res://Worlds/World1.tscn"
const MAIN_MUSIC := "res://audio/main_music.tscn"

func _ready() -> void:
	# Balik ke Main Menu (misal abis menang/kalah di gameplay) -> pastiin BGM-nya
	# balik lagi ke Main Menu BGM, bukan nyangkut di Gameplay BGM.
	BGMPlayer.play_bgm(BGMPlayer.MAIN_MENU_BGM)

func _on_settings_button_pressed() -> void:
	SceneTransition.goto_scene(SETTINGS_SCENE)

func _on_play_button_pressed() -> void:
	SceneTransition.goto_scene(GAMEPLAY_SCENE)
