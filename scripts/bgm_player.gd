extends Node

# Autoload/singleton - persists across scene changes (Main Menu <-> Settings, etc)
# so the music doesn't restart every time SceneTransition swaps the scene.

const MAIN_MENU_BGM := preload("res://Assets/Audio/BGM/Main Menu BGM.mp3")
const GAMEPLAY_BGM := preload("res://Assets/Audio/BGM/Gameplay BGM.mp3")

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.bus = &"Master"
	_player.volume_db = -6.0
	add_child(_player)

	# Start the main menu BGM on boot. Remove this line if you'd rather
	# have each scene call play_bgm() explicitly.
	play_bgm(MAIN_MENU_BGM)

## Plays a track. If the same stream is already playing, does nothing
## (so switching Main Menu <-> Settings doesn't restart the song).
func play_bgm(stream: AudioStream, restart_if_same: bool = false) -> void:
	if _player.stream == stream and _player.playing and not restart_if_same:
		return
	_player.stream = stream
	_player.play()

func stop_bgm() -> void:
	_player.stop()

func set_bgm_volume_db(db: float) -> void:
	_player.volume_db = db
