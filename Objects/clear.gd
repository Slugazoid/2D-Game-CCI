extends Node2D
class_name ClearScene

@onready var time_label: Label = $TimeLabel

var clear_time: float = 0.0

func _ready() -> void:
	_load_clear_time()
	_display_time()

func _load_clear_time() -> void:
	if SceneTransition and SceneTransition.pending_data.has("clear_time"):
		clear_time = SceneTransition.pending_data["clear_time"]
		# Hapus supaya gak kebawa stale kalau nanti scene ini diakses lagi
		# tanpa lewat alur game_won (mis. buka manual dari editor).
		SceneTransition.pending_data.erase("clear_time")
	else:
		push_warning("ClearScene: clear_time gak ditemukan di SceneTransition.pending_data, default ke 0.0")

func _display_time() -> void:
	if time_label:
		time_label.text = "Waktu: %s" % GameplayManager.format_time(clear_time)

## Contoh handler kalau kamu tambah tombol "Main Menu" di scene ini
func _on_main_menu_button_pressed() -> void:
	SceneTransition.goto_scene("res://Objects/MainMenu.tscn")

## Contoh handler kalau kamu tambah tombol "Main Lagi"
func _on_retry_button_pressed() -> void:
	SceneTransition.goto_scene("res://Objects/World1.tscn")
