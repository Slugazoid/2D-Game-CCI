extends Node

@onready var main_music: AudioStreamPlayer = $MainMusic

func fade_out(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(main_music, "volume_db", -80.0, duration)
	tween.tween_callback(main_music.stop)
