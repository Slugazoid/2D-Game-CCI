extends Node2D

@export var cliff_texture: Texture2D
@export var cliff_count: int = 15 # Jumlah tebing

@export var vanishing_point: Vector2 = Vector2(576, 324) 
@export var end_point: Vector2 = Vector2(0, 200)

@export var speed: float = 0.3
@export var min_scale: Vector2 = Vector2(0.1, 0.1)
@export var max_scale: Vector2 = Vector2(4.0, 4.0)
@export var curve_power: float = 1.5

var global_progress: float = 0.0

func _process(delta: float) -> void:
	global_progress += speed * delta
	
	if global_progress >= 1.0:
		global_progress = fmod(global_progress, 1.0)
		
	queue_redraw()

func _draw() -> void:
	if not cliff_texture:
		return
		
	var draw_data = []
	var spacing = 1.0 / cliff_count # Spacing tebing
	
	# 1. Hitung progres tebing
	for i in range(cliff_count):
		var p = fmod(global_progress + (i * spacing), 1.0)
		draw_data.append(p)
		
	# 2. Depth sort (jauh ke dekat)
	draw_data.sort()
	
	var tex_size = cliff_texture.get_size()
	var offset = -tex_size / 2.0 
	
	# 3. Render
	for p in draw_data:
		var perspective_curve = pow(p, curve_power)
		var pos = vanishing_point.lerp(end_point, perspective_curve)
		var sc = min_scale.lerp(max_scale, perspective_curve)
		
		draw_set_transform(pos, 0.0, sc)
		draw_texture(cliff_texture, offset)
