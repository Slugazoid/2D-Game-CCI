extends Node2D


@export var cliff_texture: Texture2D
@export var spawn_interval_min: float = 1.5
@export var spawn_interval_max: float = 3.5
@export var cliff_speed: float = 0.6  # Kecepatan

# Perspektif settings
@export var vanishing_point_y: float = 350.0
@export var vanishing_point_left_x: float = 540.0
@export var vanishing_point_right_x: float = 740.0

# End points
@export var end_left: Vector2 = Vector2(400, 354)
@export var end_right: Vector2 = Vector2(880, 354)

@export var min_scale: Vector2 = Vector2(0.05, 0.05)
@export var max_scale: Vector2 = Vector2(2.5, 2.5)
@export var curve_power: float = 2.0

# Collision threshold
@export var collision_progress_min: float = 0.85
@export var collision_progress_max: float = 1.0

var spawn_timer: float = 0.0
var active_cliffs: Array = []

func _ready() -> void:
	_reset_spawn_timer()

func _reset_spawn_timer() -> void:
	spawn_timer = randf_range(spawn_interval_min, spawn_interval_max)

func _process(delta: float) -> void:
	var speed_mult := _get_speed_multiplier()
	
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_cliff()
		_reset_spawn_timer()
	
	var cliffs_to_remove: Array = []
	for cliff_data in active_cliffs:
		cliff_data.progress += cliff_speed * speed_mult * delta
		
		if cliff_data.progress >= 1.1:
			cliffs_to_remove.append(cliff_data)
			continue
		
		var p = cliff_data.progress
		var perspective_curve = pow(p, curve_power)
		
		var vanish_x = vanishing_point_left_x if cliff_data.side == 0 else vanishing_point_right_x
		var vanishing_point = Vector2(vanish_x, vanishing_point_y)
		var end_point = end_left if cliff_data.side == 0 else end_right
		
		var pos = vanishing_point.lerp(end_point, perspective_curve)
		var sc = min_scale.lerp(max_scale, perspective_curve)
		
		cliff_data.position = pos
		cliff_data.scale = sc
		cliff_data.perspective = perspective_curve
		
		# Cek collision
		if p >= collision_progress_min and p <= collision_progress_max and not cliff_data.hit:
			_check_collision(cliff_data)
	
	# Hapus cliff yang sudah lewat
	for cliff_data in cliffs_to_remove:
		active_cliffs.erase(cliff_data)
	
	queue_redraw()

func _spawn_cliff() -> void:
	var side = randi_range(0, 1)
	
	var cliff_data = {
		"side": side,
		"progress": 0.0,
		"position": Vector2.ZERO,
		"scale": Vector2.ONE,
		"perspective": 0.0,
		"hit": false
	}
	active_cliffs.append(cliff_data)

func _check_collision(cliff_data: Dictionary) -> void:
	var player = _find_player()
	if player == null:
		return
	
	var cliff_col = 0 if cliff_data.side == 0 else 2
	
	if player.grid_col == cliff_col:
		cliff_data.hit = true
		if player.has_method("take_hit"):
			player.take_hit()

func _find_player() -> PlayerShip:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as PlayerShip
	
	var parent = get_parent()
	if parent:
		for child in parent.get_children():
			if child is PlayerShip:
				return child
	
	return null

func _get_speed_multiplier() -> float:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and players[0] is PlayerShip:
		return players[0].speed_multiplier
	return 1.0

func _draw() -> void:
	if not cliff_texture:
		return
	
	var tex_size = cliff_texture.get_size()
	var offset = -tex_size / 2.0
	
	var sorted_cliffs = active_cliffs.duplicate()
	sorted_cliffs.sort_custom(func(a, b): return a.progress < b.progress)
	
	for cliff_data in sorted_cliffs:
		var flip_x = cliff_data.side == 1  # Flip untuk sisi kanan
		var sc = cliff_data.scale
		if flip_x:
			sc.x = -sc.x  # Flip horizontal
		
		draw_set_transform(cliff_data.position, 0.0, sc)
		draw_texture(cliff_texture, offset)
