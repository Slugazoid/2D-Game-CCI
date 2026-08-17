extends Node
class_name GameplayManager

# Sinyal gameplay
signal distance_changed(distance: float, total: float)
signal speed_changed(speed: float, top_speed: float)
signal time_changed(elapsed: float, max_time: float)
signal collision_happened(count: int)
signal game_won
signal game_lost

# Konstanta gameplay
const TOTAL_DISTANCE: float = 9000.0 # Target jarak (9900m - 900m)
const MAX_GAME_TIME: float = 300.0 # Batas waktu (5 menit)
const STARTING_SPEED: float = 50.0 # Kecepatan awal & reset
const TOP_SPEED: float = 150.0 # Kecepatan maksimal
const INITIAL_ACCEL_TIME: float = 3.0 # Durasi akselerasi awal (detik)
const RECOVERY_ACCEL_TIME: float = 4.0 # Durasi recovery setelah hit (detik)
const HIT_PENALTY_DISTANCE: float = 500.0 # Penalti jarak saat nabrak (meter)

const INITIAL_ACCELERATION: float = (TOP_SPEED - STARTING_SPEED) / INITIAL_ACCEL_TIME # 33.33 m/s²
const RECOVERY_ACCELERATION: float = (TOP_SPEED - STARTING_SPEED) / RECOVERY_ACCEL_TIME # 25.0 m/s²

# State game
enum GameState {
	ACCELERATING, # Akselerasi
	CRUISING,     # Top speed
	WON,          # Menang (9000m)
	LOST          # Kalah (5 menit)
}

var game_state: GameState = GameState.ACCELERATING
var distance_traveled: float = 0.0
var current_speed: float = STARTING_SPEED
var elapsed_time: float = 0.0
var collision_count: int = 0
var current_acceleration: float = INITIAL_ACCELERATION
var player: PlayerShip = null
var is_active: bool = false

func start_game() -> void:
	distance_traveled = 0.0
	current_speed = STARTING_SPEED
	elapsed_time = 0.0
	collision_count = 0
	current_acceleration = INITIAL_ACCELERATION
	game_state = GameState.ACCELERATING
	is_active = true
	
	_update_player_speed_multiplier()
	
	# Emit data awal
	distance_changed.emit(distance_traveled, TOTAL_DISTANCE)
	speed_changed.emit(current_speed, TOP_SPEED)
	time_changed.emit(elapsed_time, MAX_GAME_TIME)

func _process(delta: float) -> void:
	if not is_active or is_game_over():
		return
	
	# 1. Update waktu
	elapsed_time += delta
	time_changed.emit(elapsed_time, MAX_GAME_TIME)
	
	# 2. Cek batas waktu (5 menit)
	if elapsed_time >= MAX_GAME_TIME:
		_trigger_game_lost()
		return
	
	# 3. Update kecepatan
	if game_state == GameState.ACCELERATING:
		current_speed += current_acceleration * delta
		if current_speed >= TOP_SPEED:
			current_speed = TOP_SPEED
			game_state = GameState.CRUISING
		speed_changed.emit(current_speed, TOP_SPEED)
	
	# 4. Update jarak
	distance_traveled += current_speed * delta
	distance_changed.emit(distance_traveled, TOTAL_DISTANCE)
	
	# 5. Cek kondisi menang
	if distance_traveled >= TOTAL_DISTANCE:
		_trigger_game_won()
		return
	
	# 6. Sinkron speed visual ke player
	_update_player_speed_multiplier()

func on_player_hit() -> void:
	if is_game_over():
		return
	
	# Penalti jarak & reset kecepatan
	distance_traveled = maxf(distance_traveled - HIT_PENALTY_DISTANCE, 0.0)
	current_speed = STARTING_SPEED
	current_acceleration = RECOVERY_ACCELERATION
	game_state = GameState.ACCELERATING
	collision_count += 1
	
	# Emit update
	collision_happened.emit(collision_count)
	distance_changed.emit(distance_traveled, TOTAL_DISTANCE)
	speed_changed.emit(current_speed, TOP_SPEED)
	
	_update_player_speed_multiplier()

func _update_player_speed_multiplier() -> void:
	# Rasio speed player: 0.33 - 1.0
	if player and is_instance_valid(player):
		player.speed_multiplier = current_speed / TOP_SPEED

func _trigger_game_won() -> void:
	game_state = GameState.WON
	distance_traveled = TOTAL_DISTANCE
	distance_changed.emit(distance_traveled, TOTAL_DISTANCE)
	game_won.emit()

func _trigger_game_lost() -> void:
	game_state = GameState.LOST
	game_lost.emit()

# Helper
func get_distance_remaining() -> float:
	return TOTAL_DISTANCE - distance_traveled

func get_progress_percent() -> float:
	return clampf(distance_traveled / TOTAL_DISTANCE, 0.0, 1.0) * 100.0

func get_time_remaining() -> float:
	return MAX_GAME_TIME - elapsed_time

func get_speed_percent() -> float:
	return clampf(current_speed / TOP_SPEED, 0.0, 1.0) * 100.0

func is_game_over() -> bool:
	return game_state == GameState.WON or game_state == GameState.LOST
