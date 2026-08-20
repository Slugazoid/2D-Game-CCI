extends CanvasLayer

# Panel pause in-game: muncul pas ditekan tombol Pause (HUD) atau tombol ESC,
# nge-pause seluruh tree (get_tree().paused = true) supaya gameplay bener-bener
# berhenti, terus nawarin "Resume" (lanjut main) atau "Main Menu" (balik ke menu utama).

const MAIN_MENU_SCENE := "res://Objects/MainMenu.tscn"

@onready var resume_button: TextureButton = $Root/PanelBg/ResumeButton
@onready var main_menu_button: TextureButton = $Root/PanelBg/MainMenuButton

var _is_paused: bool = false

func _ready() -> void:
	# CanvasLayer ini juga di-set process_mode = Always di scene, biar tetep
	# jalan (nerima input & bisa nge-tween) walaupun tree lagi paused.
	visible = false
	resume_button.pressed.connect(_on_resume_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
		get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	if _is_paused:
		resume()
	else:
		pause()

func pause() -> void:
	if _is_paused:
		return
	_is_paused = true
	get_tree().paused = true
	visible = true

func resume() -> void:
	if not _is_paused:
		return
	_is_paused = false
	get_tree().paused = false
	visible = false

func _on_resume_button_pressed() -> void:
	resume()

func _on_main_menu_button_pressed() -> void:
	# Un-pause dulu sebelum pindah scene, soalnya SceneTransition (autoload)
	# butuh tree jalan normal buat nge-tween fade-nya.
	get_tree().paused = false
	SceneTransition.goto_scene(MAIN_MENU_SCENE)
