extends Node
class_name GameplayManager

# Sinyal gameplay
signal distance_changed(distance: float, total: float)
signal speed_changed(speed: float, top_speed: float)
signal time_changed(elapsed: float, max_time: float)
signal collision_happened(count: int, max_count: int)
signal target_appeared # Notif + munculnya pesawat target (radius 1000m)
signal zone_entered(grace_seconds: float) # Notif masuk radius aktivasi 900m
signal game_won
signal game_lost(reason: String) # "no_time" (bensin habis) atau "no_lives" (nyawa habis)

# Konstanta gameplay
const START_GAP: float = 9900.0 # Jarak awal player <-> target
const ACTIVATION_RADIUS: float = 900.0 # Radius aktivasi skill
const TOTAL_DISTANCE: float = START_GAP - ACTIVATION_RADIUS # 9000m yang perlu ditempuh
const FINAL_STRETCH_REMAINING: float = 1000.0 # Sisa jarak saat target muncul & obstacle dikurangi

const MAX_GAME_TIME: float = 300.0 # Batas waktu (5 menit) = "bensin habis"
const MAX_COLLISIONS: int = 10 # Nyawa habis setelah 10x nabrak

const TARGET_SPEED: float = 100.0 # Kecepatan pesawat target (konstan)
const STARTING_SPEED: float = 50.0 # Kecepatan awal & reset saat nabrak
const TOP_SPEED: float = 150.0 # Kecepatan maksimal player

const INITIAL_ACCEL_TIME: float = 3.0 # Durasi akselerasi awal (detik)
const RECOVERY_ACCEL_TIME: float = 4.0 # Durasi recovery setelah hit (detik)
const HIT_PENALTY_DISTANCE: float = 500.0 # Penalti jarak saat nabrak (meter)

const ZONE_ENTRY_GRACE: float = 3.0 # Jeda notif sebelum "menang" resmi dideklarasikan

const INITIAL_ACCELERATION: float = (TOP_SPEED - STARTING_SPEED) / INITIAL_ACCEL_TIME # 33.33 m/s^2
const RECOVERY_ACCELERATION: float = (TOP_SPEED - STARTING_SPEED) / RECOVERY_ACCEL_TIME # 25.0 m/s^2

# State game
enum GameState {
	ACCELERATING,  # Akselerasi
	CRUISING,      # Top speed
	ENTERING_ZONE, # Sudah masuk radius 900m, jeda sebelum menang resmi
	WON,           # Menang
	LOST           # Kalah
}

var game_state: GameState = GameState.ACCELERATING
var distance_traveled: float = 0.0 # 0 - TOTAL_DISTANCE (progress menutup jarak ke target)
var current_speed: float = STARTING_SPEED
var elapsed_time: float = 0.0
var collision_count: int = 0
var current_acceleration: float = INITIAL_ACCELERATION
var player: PlayerShip = null
var is_active: bool = false

var _final_stretch_triggered: bool = false
var _zone_timer: float = 0.0

func start_game() -> void:
	distance_traveled = 0.0
	current_speed = STARTING_SPEED
	elapsed_time = 0.0
	collision_count = 0
	current_acceleration = INITIAL_ACCELERATION
	game_state = GameState.ACCELERATING
	is_active = true
	_final_stretch_triggered = false
	_zone_timer = 0.0

	_update_player_speed_multiplier()

	# Emit data awal
	distance_changed.emit(distance_traveled, TOTAL_DISTANCE)
	speed_changed.emit(current_speed, TOP_SPEED)
	time_changed.emit(elapsed_time, MAX_GAME_TIME)

func _process(delta: float) -> void:
	if not is_active or is_game_over():
		return

	# Kalau sudah masuk radius aktivasi, jalani jeda notif sebelum menang resmi
	if game_state == GameState.ENTERING_ZONE:
		_zone_timer -= delta
		if _zone_timer <= 0.0:
			_trigger_game_won()
		return

	# 1. Update waktu
	elapsed_time += delta
	time_changed.emit(elapsed_time, MAX_GAME_TIME)

	# 2. Cek batas waktu (5 menit) -> kalah karena "kehabisan bensin"
	if elapsed_time >= MAX_GAME_TIME:
		_trigger_game_lost("no_time")
		return

	# 3. Update kecepatan player
	if game_state == GameState.ACCELERATING:
		current_speed += current_acceleration * delta
		if current_speed >= TOP_SPEED:
			current_speed = TOP_SPEED
			game_state = GameState.CRUISING
		speed_changed.emit(current_speed, TOP_SPEED)

	# 4. Update jarak berdasarkan CLOSING RATE (speed player - speed target)
	# Ini kunci utamanya: jarak hanya menyempit kalau player LEBIH CEPAT dari target (100 m/d).
	# Kalau player masih di bawah 100 m/d (misal baru mulai / baru recovery abis nabrak),
	# jarak malah melebar dulu, persis kayak "jarak antara player dgn target bertambah".
	var closing_rate: float = current_speed - TARGET_SPEED
	distance_traveled = clampf(distance_traveled + closing_rate * delta, 0.0, TOTAL_DISTANCE)
	distance_changed.emit(distance_traveled, TOTAL_DISTANCE)

	# 5. Cek target muncul + obstacle dikurangi (sisa jarak <= 1000m)
	if not _final_stretch_triggered and (TOTAL_DISTANCE - distance_traveled) <= FINAL_STRETCH_REMAINING:
		_final_stretch_triggered = true
		target_appeared.emit()

	# 6. Cek kondisi masuk radius aktivasi (900m) -> bukan langsung menang, kasih jeda notif dulu
	if distance_traveled >= TOTAL_DISTANCE:
		game_state = GameState.ENTERING_ZONE
		_zone_timer = ZONE_ENTRY_GRACE
		zone_entered.emit(ZONE_ENTRY_GRACE)
		return

	# 7. Sinkron speed visual ke player
	_update_player_speed_multiplier()

func on_player_hit() -> void:
	if is_game_over() or game_state == GameState.ENTERING_ZONE:
		return

	# Penalti jarak & reset kecepatan
	distance_traveled = maxf(distance_traveled - HIT_PENALTY_DISTANCE, 0.0)
	current_speed = STARTING_SPEED
	current_acceleration = RECOVERY_ACCELERATION
	game_state = GameState.ACCELERATING
	collision_count += 1

	# Emit update
	collision_happened.emit(collision_count, MAX_COLLISIONS)
	distance_changed.emit(distance_traveled, TOTAL_DISTANCE)
	speed_changed.emit(current_speed, TOP_SPEED)

	_update_player_speed_multiplier()

	# Nyawa habis (10x nabrak) -> kalah
	if collision_count >= MAX_COLLISIONS:
		_trigger_game_lost("no_lives")

func _update_player_speed_multiplier() -> void:
	# Rasio speed player: 0.33 - 1.0
	if player and is_instance_valid(player):
		player.speed_multiplier = current_speed / TOP_SPEED

func _trigger_game_won() -> void:
	game_state = GameState.WON
	distance_traveled = TOTAL_DISTANCE
	distance_changed.emit(distance_traveled, TOTAL_DISTANCE)
	game_won.emit()

func _trigger_game_lost(reason: String) -> void:
	game_state = GameState.LOST
	game_lost.emit(reason)

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
