extends Node2D
class_name PlayerShip

var grid_col: int = 1
var grid_row: int = 1

@export var grid_center: Vector2 = Vector2(640, 360)
@export var cell_width: float = 240.0
@export var cell_height: float = 160.0

@export var laser_scene: PackedScene = preload("res://Objects/laser.tscn")
@export var shoot_cooldown: float = 0.2
@export var vanish_offset: Vector2 = Vector2(0, -160) # Vanishing point in front and slightly above player
var can_shoot: bool = true
var shoot_timer: float = 0.0

var visual_pos: Vector2 = Vector2.ZERO
var bank_angle: float = 0.0
var pitch_angle: float = 0.0
var anim_pulse: float = 0.0

func _ready() -> void:
	if position != Vector2.ZERO:
		grid_center = position
		
	visual_pos = get_cell_position(grid_col, grid_row)
	position = visual_pos

func get_cell_position(col: int, row: int) -> Vector2:
	var col_offset = float(clampi(col, 0, 2) - 1)
	var row_offset = float(clampi(row, 0, 2) - 1)
	return grid_center + Vector2(col_offset * cell_width, row_offset * cell_height)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left") or event.is_action_pressed("move_left"):
		move_grid(-1, 0)
	elif event.is_action_pressed("ui_right") or event.is_action_pressed("move_right"):
		move_grid(1, 0)
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		move_grid(0, -1)
	elif event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		move_grid(0, 1)
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("shoot"):
		shoot_laser()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		shoot_laser()

func move_grid(delta_col: int, delta_row: int) -> void:
	var prev_col = grid_col
	var prev_row = grid_row
	
	grid_col = clampi(grid_col + delta_col, 0, 2)
	grid_row = clampi(grid_row + delta_row, 0, 2)
	
	if grid_col != prev_col:
		bank_angle = (grid_col - prev_col) * 0.35
	if grid_row != prev_row:
		pitch_angle = (grid_row - prev_row) * 0.20

func shoot_laser() -> void:
	if not can_shoot or laser_scene == null:
		return
	
	can_shoot = false
	shoot_timer = shoot_cooldown
	
	var target_point = global_position + vanish_offset
	var offsets = [Vector2(-35, -10), Vector2(35, -10)]
	var current_scene = get_tree().current_scene
	
	for offset in offsets:
		var laser = laser_scene.instantiate()
		var spawn_pos = global_position + offset
		if current_scene:
			current_scene.add_child(laser)
		elif get_parent():
			get_parent().add_child(laser)
			
		if laser.has_method("setup"):
			laser.setup(spawn_pos, target_point)
		else:
			laser.global_position = spawn_pos

func _process(delta: float) -> void:
	if not can_shoot:
		shoot_timer -= delta
		if shoot_timer <= 0.0:
			can_shoot = true

	anim_pulse += delta * 6.0
	
	var target_pos = get_cell_position(grid_col, grid_row)
	visual_pos = visual_pos.lerp(target_pos, delta * 16.0)
	position = visual_pos
	
	bank_angle = lerpf(bank_angle, 0.0, delta * 8.0)
	pitch_angle = lerpf(pitch_angle, 0.0, delta * 8.0)
	rotation = bank_angle
	
	queue_redraw()
