extends AnimatedSprite2D

@export var amplitude: float = 8.0
@export var speed: float = 2.0

var _base_y: float = 0.0
var _t: float = 0.0

func _ready() -> void:
	_base_y = position.y
	if sprite_frames and sprite_frames.has_animation("idle"):
		play("idle")


func _process(delta: float) -> void:
	_t += delta * speed
	position.y = _base_y + sin(_t) * amplitude
