extends Node2D

const MAIN_MENU_SCENE := "res://Objects/MainMenu.tscn"

const SPEAKER_ON_TEX := preload("res://Assets/Button/PNG/Speaker_On_Button.png")
const SPEAKER_OFF_TEX := preload("res://Assets/Button/PNG/Speaker_Off_Button.png")

@onready var volume_slider: HSlider = $UI/Root/CenterBox/VolumeRow/VolumeSlider
@onready var volume_value_label: Label = $UI/Root/CenterBox/VolumeRow/VolumeValue
@onready var mute_button: TextureButton = $UI/Root/CenterBox/VolumeRow/MuteButton

var _is_muted: bool = false

func _ready() -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	var current_linear: float = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	volume_slider.value = clamp(current_linear, 0.0, 1.0)
	_update_volume_label(volume_slider.value)

	_is_muted = AudioServer.is_bus_mute(bus_idx)
	_update_mute_icon()

	volume_slider.value_changed.connect(_on_volume_slider_changed)
	mute_button.pressed.connect(_on_mute_button_pressed)

func _on_volume_slider_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	_update_volume_label(value)

func _update_volume_label(value: float) -> void:
	volume_value_label.text = "%d%%" % int(round(value * 100.0))

func _on_mute_button_pressed() -> void:
	_is_muted = not _is_muted
	var bus_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_idx, _is_muted)
	_update_mute_icon()

func _update_mute_icon() -> void:
	mute_button.texture_normal = SPEAKER_OFF_TEX if _is_muted else SPEAKER_ON_TEX

func _on_back_button_pressed() -> void:
	SceneTransition.goto_scene(MAIN_MENU_SCENE)
