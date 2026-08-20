extends Node2D

const SETTINGS_SCENE := "res://Objects/SettingsMenu.tscn"
const DIFFICULTY_SCENE := "res://Objects/DifficultySelect.tscn"
const MAIN_MUSIC := "res://audio/main_music.tscn"

func _ready() -> void:
	# Balik ke Main Menu (misal abis menang/kalah di gameplay) -> pastiin BGM-nya
	# balik lagi ke Main Menu BGM, bukan nyangkut di Gameplay BGM.
	BGMPlayer.play_bgm(BGMPlayer.MAIN_MENU_BGM)

func _on_settings_button_pressed() -> void:
	SceneTransition.goto_scene(SETTINGS_SCENE)

func _on_play_button_pressed() -> void:
	# Play gak langsung ke gameplay -> mampir dulu ke scene pilih difficulty.
	SceneTransition.goto_scene(DIFFICULTY_SCENE)
