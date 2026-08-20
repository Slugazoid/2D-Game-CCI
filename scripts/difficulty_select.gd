extends Node2D

const GAMEPLAY_SCENE := "res://Worlds/World1.tscn"

func _on_easy_button_pressed() -> void:
	_start_game(DifficultyManager.Difficulty.EASY)

func _on_medium_button_pressed() -> void:
	_start_game(DifficultyManager.Difficulty.MEDIUM)

func _on_hard_button_pressed() -> void:
	_start_game(DifficultyManager.Difficulty.HARD)

func _start_game(difficulty: DifficultyManager.Difficulty) -> void:
	DifficultyManager.set_difficulty(difficulty)
	SceneTransition.goto_scene(GAMEPLAY_SCENE)

func _on_back_button_pressed() -> void:
	SceneTransition.goto_scene("res://Objects/MainMenu.tscn")
