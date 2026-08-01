extends Area2D

@export var lane_spacing: float = 160.0
@export var row_spacing: float = 130.0
@export var move_lerp_speed: float = 10.0

var grid_x: int = 0
var grid_y: int = 0
var base_position: Vector2

func _ready() -> void:
	base_position = position

func _process(delta: float) -> void:
	_handle_input()

	var target_pos := base_position + Vector2(grid_x * lane_spacing, -grid_y * row_spacing)
	position = position.lerp(target_pos, delta * move_lerp_speed)

func _handle_input() -> void:
	if Input.is_action_just_pressed("ui_left"):
		grid_x = clamp(grid_x - 1, -1, 1)
	elif Input.is_action_just_pressed("ui_right"):
		grid_x = clamp(grid_x + 1, -1, 1)

	if Input.is_action_just_pressed("ui_up"):
		grid_y = clamp(grid_y + 1, -1, 1)
	elif Input.is_action_just_pressed("ui_down"):
		grid_y = clamp(grid_y - 1, -1, 1)
