extends CanvasLayer

## Tempat nitip data kecil antar-scene (mis. clear_time buat ClearScene) tanpa
## perlu bikin autoload baru. Isi sebelum goto_scene(), scene tujuan yang baca
## sebaiknya langsung erase() key-nya biar gak kebawa stale ke transisi berikutnya.
var pending_data: Dictionary = {}

var _fade_rect: ColorRect
var _is_busy := false

func _ready() -> void:
	layer = 100
	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0, 0, 0, 0)
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)

func goto_scene(path: String, fade_duration: float = 0.4) -> void:
	if _is_busy:
		return
	_is_busy = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween_out := create_tween()
	tween_out.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
	await tween_out.finished

	get_tree().change_scene_to_file(path)
	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
	await tween_in.finished

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_busy = false
