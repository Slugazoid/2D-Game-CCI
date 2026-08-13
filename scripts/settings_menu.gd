extends Node2D

const MAIN_MENU_SCENE := "res://Objects/MainMenu.tscn"

@onready var volume_slider: HSlider = $UI/Root/CenterBox/VolumeRow/VolumeSlider
@onready var volume_value_label: Label = $UI/Root/CenterBox/VolumeRow/VolumeValue


func _ready() -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	var current_linear: float = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
	volume_slider.value = clamp(current_linear, 0.0, 1.0)
	_update_volume_label(volume_slider.value)

	volume_slider.value_changed.connect(_on_volume_slider_changed)


func _on_volume_slider_changed(value: float) -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	_update_volume_label(value)


func _update_volume_label(value: float) -> void:
	volume_value_label.text = "%d%%" % int(round(value * 100.0))


func _on_back_button_pressed() -> void:
	SceneTransition.goto_scene(MAIN_MENU_SCENE)
