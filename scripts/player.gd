extends CharacterBody2D
class_name PlayerShip

signal health_changed(current_hp: int, max_hp: int)
signal player_died

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

# --- Health system ---
@export var max_hp: int = 5
var hp: int = 5
var is_dead: bool = false
var is_invincible: bool = false
var invincible_duration: float = 1.0

# --- Speed slowdown system ---
## Kecepatan global yang bisa diubah saat player nabrak
var speed_multiplier: float = 1.0
var slowdown_duration: float = 2.0
var slowdown_amount: float = 0.3  # Saat nabrak, speed jadi 30%
var _slowdown_tween: Tween

# --- Laser SFX ---
var _laser_sfx: AudioStreamPlayer

func _ready() -> void:
	add_to_group("player")
	
	if position != Vector2.ZERO:
		grid_center = position
		
	visual_pos = get_cell_position(grid_col, grid_row)
	position = visual_pos
	
	hp = max_hp
	
	# Setup laser SFX player
	_laser_sfx = AudioStreamPlayer.new()
	_laser_sfx.bus = &"Master"
	_laser_sfx.volume_db = -12.0
	add_child(_laser_sfx)
	_create_laser_sound()

func _create_laser_sound() -> void:
	# Generate a short procedural "zap" sound
	var sample_rate := 22050
	var duration_sec := 0.08
	var num_samples := int(sample_rate * duration_sec)
	
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_8_BITS
	audio.mix_rate = sample_rate
	audio.stereo = false
	
	var data := PackedByteArray()
	data.resize(num_samples)
	
	for i in range(num_samples):
		var t := float(i) / sample_rate
		var envelope := 1.0 - (float(i) / num_samples)  # Fade out
		# High frequency zap: mix of high freq sine waves
		var freq1 := 1800.0 - (t * 12000.0)  # Descending pitch
		var sample := sin(t * freq1 * TAU) * envelope
		# Add some noise for texture
		sample += (randf() * 2.0 - 1.0) * 0.15 * envelope
		# Convert to 8-bit unsigned (0-255, center at 128)
		var byte_val := int(clamp(sample * 80.0 + 128.0, 0, 255))
		data[i] = byte_val
	
	audio.data = data
	_laser_sfx.stream = audio

func get_cell_position(col: int, row: int) -> Vector2:
	var col_offset = float(clampi(col, 0, 2) - 1)
	var row_offset = float(clampi(row, 0, 2) - 1)
	return grid_center + Vector2(col_offset * cell_width, row_offset * cell_height)

func _unhandled_input(event: InputEvent) -> void:
	if is_dead:
		return
		
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
	
	# Play laser SFX
	if _laser_sfx and _laser_sfx.stream:
		_laser_sfx.play()
	
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

func take_hit() -> void:
	if is_dead or is_invincible:
		return
	
	hp -= 1
	health_changed.emit(hp, max_hp)
	
	# Red flash effect
	_flash_red()
	
	# Speed slowdown
	_apply_slowdown()
	
	# Invincibility frames
	is_invincible = true
	get_tree().create_timer(invincible_duration).timeout.connect(func(): is_invincible = false)
	
	if hp <= 0:
		is_dead = true
		player_died.emit()

func _flash_red() -> void:
	# Flash merah saat kena hit
	var sprite = get_node_or_null("Player_animation")
	if sprite == null:
		# Fallback: flash self
		modulate = Color(1, 0.2, 0.2, 1)
		var tween = create_tween()
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)
		return
	
	# Flash sequence: merah -> normal (beberapa kali)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2, 1), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	tween.tween_property(self, "modulate", Color(1, 0.2, 0.2, 1), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	tween.tween_property(self, "modulate", Color(1, 0.3, 0.3, 0.7), 0.05)
	tween.tween_property(self, "modulate", Color.WHITE, 0.15)

func _apply_slowdown() -> void:
	# Lambatkan kecepatan
	speed_multiplier = slowdown_amount
	
	if _slowdown_tween and _slowdown_tween.is_running():
		_slowdown_tween.kill()
	
	_slowdown_tween = create_tween()
	_slowdown_tween.tween_interval(slowdown_duration * 0.6)
	_slowdown_tween.tween_property(self, "speed_multiplier", 1.0, slowdown_duration * 0.4)

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
