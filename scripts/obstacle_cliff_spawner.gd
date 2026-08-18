extends Node2D

## Obstacle tebing yang spawn dari kejauhan (vanishing point) lalu membesar mendekat
## ke posisi kolom player (perspektif). Ada 4 pola obstacle:
## - "left"   : nutup kolom kiri (0) aja      -> tebing_sisi_kiri
## - "right"  : nutup kolom kanan (2) aja     -> tebing_1x2_sisi_kanan
## - "center" : nutup kolom tengah (1) aja    -> tebing_tengah
## - "both"   : nutup kolom kiri & kanan (0 & 2), tengah selalu aman -> rintangan_tebing_2_sisi
##
## Aturan fair-play: kombinasi obstacle yang lagi aktif bareng GAK PERNAH nutup ke-3 kolom
## sekaligus, jadi player selalu punya minimal 1 kolom aman buat kabur.

const PATTERN_COLUMNS := {
	"left": [0],
	"right": [2],
	"center": [1],
	"both": [0, 2],
}

# Texture per pola obstacle
@export var left_texture: Texture2D          # tebing sisi kiri
@export var right_texture: Texture2D         # tebing 1x2 sisi kanan
@export var center_texture: Texture2D        # tebing tengah
@export var both_sides_texture: Texture2D    # rintangan tebing 2 sisi

@export var spawn_interval_min: float = 1.5
@export var spawn_interval_max: float = 3.5
@export var cliff_speed: float = 0.6 # Kecepatan obstacle

# Final stretch (sisa jarak <= 1000m, pas target udah muncul): obstacle dikurangin biar
# player fokus ke target, bukan malah tambah ribet. Dikontrol dari luar via set_final_stretch().
@export var final_stretch_interval_multiplier: float = 2.5 # jarak spawn makin jarang (dikali interval normal)
@export var final_stretch_stop_spawning: bool = false # true = obstacle baru berhenti sama sekali

var _in_final_stretch: bool = false

# Setting perspektif per jalur (kiri/kanan/tengah)
@export var vanishing_point_y: float = 350.0
@export var vanishing_point_left_x: float = 540.0
@export var vanishing_point_right_x: float = 740.0
@export var vanishing_point_center_x: float = 640.0

# Titik akhir (posisi kolom player: kiri, tengah, kanan)
@export var end_left: Vector2 = Vector2(400, 354)
@export var end_center: Vector2 = Vector2(640, 354)
@export var end_right: Vector2 = Vector2(880, 354)

@export var min_scale: Vector2 = Vector2(0.05, 0.05)
@export var curve_power: float = 2.0

# Skala maksimal (pas paling deket) per pola, disesuaikan sama ukuran asli tiap aset
# biar besar tampilannya konsisten & rapi walau sumber gambarnya beda-beda ukuran.
@export var left_max_scale: Vector2 = Vector2(2.3, 2.3)
@export var right_max_scale: Vector2 = Vector2(2.8, 2.8)
@export var center_max_scale: Vector2 = Vector2(2.3, 2.3)
@export var both_sides_max_scale: Vector2 = Vector2(4.8, 4.8)

# Bobot spawn tiap pola (makin gede makin sering muncul).
# "both" dibikin paling jarang karena paling nge-batesin ruang gerak player.
@export var weight_left: float = 30.0
@export var weight_right: float = 30.0
@export var weight_center: float = 25.0
@export var weight_both_sides: float = 15.0

# Threshold tabrakan
@export var collision_progress_min: float = 0.85
@export var collision_progress_max: float = 1.0

var spawn_timer: float = 0.0
var active_cliffs: Array = []
var _last_pattern: String = ""

func _ready() -> void:
	_reset_spawn_timer()

func _reset_spawn_timer() -> void:
	var interval_min := spawn_interval_min
	var interval_max := spawn_interval_max
	if _in_final_stretch:
		interval_min *= final_stretch_interval_multiplier
		interval_max *= final_stretch_interval_multiplier
	spawn_timer = randf_range(interval_min, interval_max)

## Dipanggil dari world1.gd pas GameplayManager emit target_appeared (sisa jarak <= 1000m)
## dan pas game_won/reset buat balikin ke normal lagi.
func set_final_stretch(active: bool) -> void:
	_in_final_stretch = active
	_reset_spawn_timer() # langsung apply interval baru, gak nunggu timer abis dulu

func _process(delta: float) -> void:
	var speed_mult := _get_speed_multiplier()

	if not (_in_final_stretch and final_stretch_stop_spawning):
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
		var visuals := _get_pattern_visuals(cliff_data.pattern)
		if visuals.is_empty():
			continue

		var pos = visuals.vanish.lerp(visuals.end, perspective_curve)
		var sc = min_scale.lerp(visuals.max_scale, perspective_curve)

		cliff_data.position = pos
		cliff_data.scale = sc
		cliff_data.perspective = perspective_curve

		# Cek tabrakan
		if p >= collision_progress_min and p <= collision_progress_max and not cliff_data.hit:
			_check_collision(cliff_data)

	# Hapus obstacle lewat
	for cliff_data in cliffs_to_remove:
		active_cliffs.erase(cliff_data)

	queue_redraw()

## Kolom-kolom yang lagi "diduduki" obstacle yang masih aktif (belum kelewatan).
func _get_blocked_columns() -> Array:
	var blocked: Array = []
	for cliff_data in active_cliffs:
		if cliff_data.progress < 1.0:
			for col in PATTERN_COLUMNS.get(cliff_data.pattern, []):
				if col not in blocked:
					blocked.append(col)
	return blocked

## Pilih pola obstacle baru secara random-berbobot, tapi SKIP pola apa pun yang kalau
## digabung sama obstacle yang lagi aktif bakal nutup ke-3 kolom sekaligus.
## Balikin "" kalau gak ada pola yang aman buat di-spawn saat ini (skip spawn kali ini).
func _choose_pattern(existing_blocked: Array) -> String:
	var weights := {
		"left": weight_left,
		"right": weight_right,
		"center": weight_center,
		"both": weight_both_sides,
	}

	var candidates: Array = []
	var total_weight := 0.0

	for pattern in weights.keys():
		if pattern == "both" and _last_pattern == "both":
			continue # jangan "both" 2x berturut-turut, biar ritme-nya gak berat mulu

		var union: Array = existing_blocked.duplicate()
		for col in PATTERN_COLUMNS[pattern]:
			if col not in union:
				union.append(col)

		if union.size() >= 3:
			continue # bakal nutup semua kolom, gak fair buat player -> skip

		var w: float = weights[pattern]
		if w <= 0.0:
			continue

		candidates.append(pattern)
		total_weight += w

	if candidates.is_empty() or total_weight <= 0.0:
		return ""

	var roll := randf() * total_weight
	var cumulative := 0.0
	for pattern in candidates:
		cumulative += weights[pattern]
		if roll <= cumulative:
			return pattern

	return candidates[-1]

func _spawn_cliff() -> void:
	var existing_blocked := _get_blocked_columns()
	var pattern := _choose_pattern(existing_blocked)
	if pattern == "":
		return # gak ada pola yang aman buat di-spawn sekarang, coba lagi timer berikutnya

	var cliff_data = {
		"pattern": pattern,
		"progress": 0.0,
		"position": Vector2.ZERO,
		"scale": Vector2.ONE,
		"perspective": 0.0,
		"hit": false,
	}
	active_cliffs.append(cliff_data)
	_last_pattern = pattern

func _check_collision(cliff_data: Dictionary) -> void:
	var player = _find_player()
	if player == null:
		return

	var blocked_cols: Array = PATTERN_COLUMNS.get(cliff_data.pattern, [])
	if player.grid_col in blocked_cols:
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

## Data visual (titik lenyap, titik akhir, skala maks, texture) buat 1 pola obstacle.
func _get_pattern_visuals(pattern: String) -> Dictionary:
	match pattern:
		"left":
			return {
				"vanish": Vector2(vanishing_point_left_x, vanishing_point_y),
				"end": end_left,
				"max_scale": left_max_scale,
				"texture": left_texture,
			}
		"right":
			return {
				"vanish": Vector2(vanishing_point_right_x, vanishing_point_y),
				"end": end_right,
				"max_scale": right_max_scale,
				"texture": right_texture,
			}
		"center":
			return {
				"vanish": Vector2(vanishing_point_center_x, vanishing_point_y),
				"end": end_center,
				"max_scale": center_max_scale,
				"texture": center_texture,
			}
		"both":
			return {
				"vanish": Vector2(vanishing_point_center_x, vanishing_point_y),
				"end": end_center,
				"max_scale": both_sides_max_scale,
				"texture": both_sides_texture,
			}
		_:
			return {}

func _draw() -> void:
	var sorted_cliffs = active_cliffs.duplicate()
	sorted_cliffs.sort_custom(func(a, b): return a.progress < b.progress)

	for cliff_data in sorted_cliffs:
		var visuals := _get_pattern_visuals(cliff_data.pattern)
		var tex: Texture2D = visuals.get("texture")
		if tex == null:
			continue

		var tex_size = tex.get_size()
		var offset = -tex_size / 2.0

		draw_set_transform(cliff_data.position, 0.0, cliff_data.scale)
		draw_texture(tex, offset)
