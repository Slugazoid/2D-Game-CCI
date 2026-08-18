extends Node2D
class_name TargetShip

## Pesawat target yang dikejar player.
## Muncul (fade-in) di titik jauh/vanishing point pas sisa jarak <= 1000m (FINAL_STRETCH_REMAINING),
## lalu membesar & bergerak mendekat seiring player menutup jarak, sampai player masuk radius aktivasi.

@export var vanish_point: Vector2 = Vector2(640, 340)   # posisi awal muncul, jauh & kecil
@export var arrival_point: Vector2 = Vector2(640, 430)  # posisi saat sudah di radius aktivasi (900m)
@export var min_scale: Vector2 = Vector2(0.04, 0.04)    # skala pas baru muncul (jauh)
@export var max_scale: Vector2 = Vector2(0.35, 0.35)    # skala pas sudah dekat (radius aktivasi)
@export var fade_in_duration: float = 1.0

@export var float_amplitude: float = 4.0  # efek melayang halus
@export var float_speed: float = 1.5

@onready var sprite: Sprite2D = $Sprite2D

var _is_active: bool = false
var _float_t: float = 0.0
var _base_position: Vector2

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	scale = min_scale
	position = vanish_point
	_base_position = vanish_point

## Dipanggil sekali pas GameplayManager emit target_appeared (sisa jarak <= 1000m)
func appear() -> void:
	if _is_active:
		return
	_is_active = true
	visible = true
	position = vanish_point
	_base_position = vanish_point
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
	_base_position = vanish_point.lerp(arrival_point, progress)
	scale = min_scale.lerp(max_scale, progress)

## Dipanggil pas game_won / reset, buat sembunyiin lagi kalau perlu (misal replay).
func reset() -> void:
	_is_active = false
	visible = false
	modulate.a = 0.0
	scale = min_scale
	position = vanish_point
	_base_position = vanish_point

func _process(delta: float) -> void:
	if not _is_active:
		return
	_float_t += delta * float_speed
	position = _base_position + Vector2(0, sin(_float_t) * float_amplitude)
