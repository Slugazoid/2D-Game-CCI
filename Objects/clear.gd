extends Node2D
class_name ClearScene

@onready var time_label: Label = $TimeLabel

## Berapa lama panel "You Win" ini tampil sebelum otomatis balik ke Main Menu.
const AUTO_RETURN_DELAY: float = 5.0

var clear_time: float = 0.0

func _ready() -> void:
	_load_clear_time()
	_display_clear_time()

	await get_tree().create_timer(AUTO_RETURN_DELAY).timeout
	SceneTransition.goto_scene("res://Objects/MainMenu.tscn")

func _load_clear_time() -> void:
	if SceneTransition and SceneTransition.pending_data.has("clear_time"):
		clear_time = SceneTransition.pending_data["clear_time"]
		# Hapus supaya gak kebawa stale kalau nanti scene ini diakses lagi
		# tanpa lewat alur game_won (mis. buka manual dari editor).
		SceneTransition.pending_data.erase("clear_time")
	else:
		push_warning("ClearScene: clear_time gak ditemukan di SceneTransition.pending_data, default ke 0.0")

func _display_clear_time() -> void:
	if not time_label:
		return

	var total_seconds: int = int(clear_time)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	var millis: int = int((clear_time - total_seconds) * 100)
	time_label.text = "Clear Time %02d:%02d:%02d" % [minutes, seconds, millis]
