extends Node2D
class_name TargetShip

## Pesawat target yang dikejar player.
## Muncul (fade-in) di titik jauh/vanishing point pas sisa jarak <= 1000m (FINAL_STRETCH_REMAINING),
## lalu membesar & bergerak mendekat seiring player menutup jarak, sampai player masuk radius aktivasi.

@export var vanish_point: Vector2 = Vector2(640, 340)   # posisi awal muncul, jauh & kecil
@export var arrival_point: Vector2 = Vector2(640, 430)  # posisi saat sudah di radius aktivasi (900m)
@export var min_scale: Vector2 = Vector2(0.22, 0.22)    # skala pas baru muncul (jauh)
@export var max_scale: Vector2 = Vector2(1.91, 1.91)    # skala pas sudah dekat (radius aktivasi)
@export var fade_in_duration: float = 1.0

@export var float_amplitude: float = 4.0  # efek melayang halus
@export var float_speed: float = 1.5

# --- Dodge (menghindari obstacle kiri/tengah/kanan) ---
@export var lane_x: Array[float] = [400.0, 640.0, 880.0]  # SAMAKAN dgn end_left/center/right ObstacleCliffSpawner
@export var dodge_lerp_speed: float = 6.0                 # kehalusan gerak pindah kolom
@export var threat_min_progress: float = 0.15             # ancaman mulai "kebaca" di progress ini
@export var react_progress_threshold: float = 0.35        # baru mulai pindah kolom kalau progress >= ini
@export var min_col_switch_interval: float = 0.5          # jeda minimum antar pindah kolom

# --- Reaksi kena laser ---
@export var damaged_duration: float = 0.4  # berapa lama animasi 'damaged' tampil sebelum balik ke 'idle'

@onready var sprite: AnimatedSprite2D = $Sprite2D

var grid_col: int = 1  # 0 = kiri, 1 = tengah, 2 = kanan

var _is_active: bool = false
var _float_t: float = 0.0
var _base_position: Vector2
var _target_y: float = 0.0
var _current_x: float = 640.0
var _spawner: Node = null
var _switch_cooldown: float = 0.0
var _damage_token: int = 0

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	scale = min_scale
	position = vanish_point
	_base_position = vanish_point
	_target_y = vanish_point.y
	_current_x = vanish_point.x
	grid_col = 1
	_spawner = get_tree().get_first_node_in_group("obstacle_spawner")

## Dipanggil sekali pas GameplayManager emit target_appeared (sisa jarak <= 1000m)
func appear() -> void:
	if _is_active:
		return
	_is_active = true
	visible = true
	position = vanish_point
	_base_position = vanish_point
	_target_y = vanish_point.y
	_current_x = vanish_point.x
	grid_col = 1
	scale = min_scale

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

## Dipanggil tiap distance_changed selama final stretch berlangsung.
## remaining: sisa jarak player->target sekarang (get_distance_remaining()).
## window: FINAL_STRETCH_REMAINING (1000.0), dipakai buat normalisasi progress 0-1.
func update_progress(remaining: float, window: float) -> void:
	if not _is_active:
		return

	var progress: float = clampf(1.0 - (remaining / window), 0.0, 1.0)
	# Y & scale tetap ikut progress mendekat seperti semula.
	# X SENGAJA tidak disentuh di sini -> diatur _process()/_evaluate_dodge()
	# supaya bisa geser kiri/tengah/kanan menghindari obstacle.
	_target_y = lerpf(vanish_point.y, arrival_point.y, progress)
	scale = min_scale.lerp(max_scale, progress)

## Dipanggil pas game_won / reset, buat sembunyiin lagi kalau perlu (misal replay).
func reset() -> void:
	_is_active = false
	visible = false
	modulate.a = 0.0
	scale = min_scale
	position = vanish_point
	_base_position = vanish_point
	_target_y = vanish_point.y
	_current_x = vanish_point.x
	grid_col = 1

func _process(delta: float) -> void:
	if not _is_active:
		return

	_evaluate_dodge(delta)

	# X mengejar kolom (lane) yang dipilih AI, Y & scale sudah diatur update_progress()
	var target_x: float = lane_x[clampi(grid_col, 0, lane_x.size() - 1)]
	_current_x = lerpf(_current_x, target_x, delta * dodge_lerp_speed)
	_base_position = Vector2(_current_x, _target_y)

	_float_t += delta * float_speed
	position = _base_position + Vector2(0, sin(_float_t) * float_amplitude)

## Cek apakah kolom (grid_col) yang sedang ditempati bakal kena obstacle yang
## akan datang. Kalau iya, dan cooldown pindah sudah habis, pindah ke kolom
## aman terdekat (prioritas ke tengah dulu, tapi tengah sekarang juga bisa
## kena pola "center" -- jadi tetap dicek seperti kolom lain, bukan dianggap
## selalu aman).
func _evaluate_dodge(delta: float) -> void:
	_switch_cooldown = maxf(0.0, _switch_cooldown - delta)

	if _spawner == null:
		_spawner = get_tree().get_first_node_in_group("obstacle_spawner")
		if _spawner == null:
			return
	if not _spawner.has_method("get_upcoming_threats"):
		return
	if _switch_cooldown > 0.0:
		return

	var threats: Array = _spawner.get_upcoming_threats(threat_min_progress)

	var danger_cols: Dictionary = {}
	for t in threats:
		if t.progress >= react_progress_threshold:
			danger_cols[t.col] = true

	if not danger_cols.has(grid_col):
		return  # kolom sekarang masih aman

	# ObstacleCliffSpawner menjamin gak pernah nutup ke-3 kolom sekaligus,
	# jadi selalu ada minimal 1 opsi aman di sini.
	for col in [1, 0, 2]:
		if col == grid_col:
			continue
		if not danger_cols.has(col):
			grid_col = col
			_switch_cooldown = min_col_switch_interval
			return

## Dipanggil laser.gd (lewat Area2D anak "HitArea") saat TargetShip kena tembak.
## Ganti animasi sprite dari 'idle' ke 'damaged' sesaat, lalu balik lagi.
## Pakai token supaya kalau kena beberapa laser beruntun, durasi 'damaged'
## otomatis diperpanjang (gak flicker balik ke idle di tengah-tengah).
func take_hit() -> void:
	if not _is_active or sprite == null:
		return

	_damage_token += 1
	var token := _damage_token

	sprite.play("damaged")

	await get_tree().create_timer(damaged_duration).timeout
	if token == _damage_token: # gak ada hit baru masuk selama nunggu
		sprite.play("idle")
