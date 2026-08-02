extends CanvasLayer
class_name HudTextBox

@export var test_mode: bool = true
@export var test_interval: float = 5.0
@export var display_duration: float = 3.0

# list 
@export var test_messages: Array[String] = [
	"Test 111",
	"Test 222",
	"Test 333",
	"Test 444"
]

@onready var content: Node2D = $Content
@onready var text_label: Label = $Content/TextBox/Label
@onready var test_timer: Timer = $TestTimer

var message_index: int = 0
var fade_tween: Tween

func _ready() -> void:
	visible = false
	
	if test_mode:
		test_timer.wait_time = test_interval
		test_timer.timeout.connect(_on_test_timer_timeout)
		test_timer.start()
		# Show first message on start
		_show_next_test_message()

func _on_test_timer_timeout() -> void:
	_show_next_test_message()

func _show_next_test_message() -> void:
	if test_messages.size() == 0:
		return
	
	var msg = test_messages[message_index]
	message_index = (message_index + 1) % test_messages.size()
	show_message(msg, display_duration)

func show_message(text: String, duration: float = 3.0) -> void:
	if text_label:
		text_label.text = text
	
	if fade_tween and fade_tween.is_running():
		fade_tween.kill()
	
	visible = true
	if content:
		content.modulate.a = 0.0
		fade_tween = create_tween()
		fade_tween.tween_property(content, "modulate:a", 1.0, 0.3)
		fade_tween.tween_interval(duration)
		fade_tween.tween_property(content, "modulate:a", 0.0, 0.4)
		fade_tween.tween_callback(func(): visible = false)
