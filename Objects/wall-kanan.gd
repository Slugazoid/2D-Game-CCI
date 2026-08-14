extends Sprite2D

@export var vanishing_point: Vector2 = Vector2(740, 350) 

@export var end_point: Vector2 = Vector2(1280, 200)

@export var speed: float = 0.7
@export var min_scale: Vector2 = Vector2(0.2, 0.2)
@export var max_scale: Vector2 = Vector2(4.0, 4.0)

@export var min_z_index: int = 0
@export var max_z_index: int = 1

@export var initial_progress: float = 0.0
var progress: float = 0.0

func _ready() -> void:
	progress = initial_progress
	top_level = false 

func _process(delta: float) -> void:
	progress += speed * delta
	
	if progress >= 1.0:
		progress = 0.0
	
	var perspective_curve = progress * progress
	
	position = vanishing_point.lerp(end_point, perspective_curve)
	scale = min_scale.lerp(max_scale, perspective_curve)
	
	z_index = int(lerp(float(min_z_index), float(max_z_index), progress))
