extends Node2D

## Obstacle tebing yang spawn dari kejauhan (vanishing point) lalu membesar mendekat
## ke posisi kolom player (perspektif). Ada 4 pola obstacle:
## - "left"   : nutup kolom kiri (0) aja      -> ssCliff (dinding penuh)
## - "right"  : nutup kolom kanan (2) aja     -> ssCliff di-mirror (dinding penuh)
## - "center" : nutup kolom tengah (1) aja    -> tebing tengah
## - "both"   : nutup kolom kiri & kanan (0 & 2), tengah selalu aman
##              -> 2 potong batu kecil (tebing sisi kiri di kolom kiri, tebing 1x2 sisi
##                 kanan di kolom kanan), masing-masing tampil di tempatnya sendiri.
##
## Aturan fair-play: kombinasi obstacle yang lagi aktif bareng GAK PERNAH nutup ke-3 kolom
## sekaligus, jadi player selalu punya minimal 1 kolom aman buat kabur.
##
## Setiap pola bisa punya 1 atau lebih "parts" (potongan visual) yang masing-masing punya
## titik lenyap/akhir/skala/texture sendiri tapi jalan di progress yang sama. Pola "left",
## "right", "center" cuma 1 part; pola "both" ada 2 part (kiri & kanan). Semua data ini
## digabung jadi SATU tabel (_pattern_table, dibangun di _ready) biar gampang di-tuning &
## gak ada logika yang kececer di banyak fungsi terpisah.

# ---------------------------------------------------------------------------
# Texture per pola obstacle
# ---------------------------------------------------------------------------
@export var left_texture: Texture2D          # ssCliff - dinding penuh sisi kiri
@export var right_texture: Texture2D         # ssCliff (mirror) - dinding penuh sisi kanan
@export var center_texture: Texture2D        # tebing tengah

@export var both_left_texture: Texture2D     # tebing sisi kiri (batu kecil, potongan kiri pola "both")
@export var both_right_texture: Texture2D    # tebing 1x2 sisi kanan (batu kecil, potongan kanan pola "both")

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

# Skala maksimal (pas paling deket) per part, disesuaikan sama ukuran asli tiap aset
# biar besar tampilannya konsisten & rapi walau sumber gambarnya beda-beda ukuran.
@export var left_max_scale: Vector2 = Vector2(0.48, 0.48)   # ssCliff gede, jadi skalanya kecil
@export var right_max_scale: Vector2 = Vector2(0.48, 0.48)  # ssCliff (mirror)
@export var center_max_scale: Vector2 = Vector2(2.3, 2.3)
@export var both_left_max_scale: Vector2 = Vector2(2.3, 2.3)   # batu kecil, jadi skalanya gede
@export var both_right_max_scale: Vector2 = Vector2(2.8, 2.8)  # batu kecil, jadi skalanya gede

# Bobot spawn tiap pola (makin gede makin sering muncul).
# "both" dibikin paling jarang karena paling nge-batesin ruang gerak player.
@export var weight_left: float = 30.0
@export var weight_right: float = 30.0
@export var weight_center: float = 25.0
@export var weight_both_sides: float = 15.0

# Threshold tabrakan
@export var collision_progress_min: float = 0.85
@export var collision_progress_max: float = 1.0

# ---------------------------------------------------------------------------
# Visibility / warning telegraph
# Obstacle yang muncul di sisi kiri/kanan gampang ketelen sama tebing dekoratif di BG
# (warna & bentuknya mirip), jadi dikasih rim-light supaya kontras, yang berubah makin
# nge-warning (kuning -> merah + pulsing) pas obstacle-nya udah deket banget.
# ---------------------------------------------------------------------------
@export_group("Visibility Telegraph")
@export var telegraph_patterns: Array[String] = ["left", "right", "both"] # pola yang butuh outline ekstra
@export var telegraph_color_far: Color = Color(1.0, 0.92, 0.55, 0.6)   # rim waktu masih jauh
@export var telegraph_color_near: Color = Color(1.0, 0.25, 0.2, 0.95)  # rim waktu udah deket (warning)
@export var telegraph_near_progress: float = 0.55 # mulai transisi ke warna warning di progress ini
@export var telegraph_pulse_speed: float = 9.0 # kecepatan kedip pas udah deket
@export var telegraph_outline_px: float = 1.5 # tebal outline dalam ruang texture (px sebelum di-scale)

const OUTLINE_DIRECTIONS := [
	Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1),
	Vector2(0.7071, 0.7071), Vector2(-0.7071, 0.7071),
	Vector2(0.7071, -0.7071), Vector2(-0.7071, -0.7071),
]

const PATTERN_COLUMNS := {
	"left": [0],
	"right": [2],
	"center": [1],
	"both": [0, 2],
}

var spawn_timer: float = 0.0
var active_cliffs: Array = []
var _last_pattern: String = ""

## Tabel tunggal berisi semua data per-pola (dibangun sekali di _ready dari @export vars di
## atas). Sesudah ini, seluruh fungsi lain tinggal query ke _pattern_table, gak perlu lagi ada
## logika yang beda-beda buat pola 1-potong (left/right/center) vs pola 2-potong (both).
var _pattern_table: Dictionary = {}

func _ready() -> void:
	_build_pattern_table()
	_reset_spawn_timer()

func _build_pattern_table() -> void:
	_pattern_table = {
		"left": {
			"columns": PATTERN_COLUMNS["left"],
			"weight": weight_left,
			"parts": [
				{
					"vanish": Vector2(vanishing_point_left_x, vanishing_point_y),
					"end": end_left,
					"max_scale": left_max_scale,
					"texture": left_texture,
				},
			],
		},
		"right": {
			"columns": PATTERN_COLUMNS["right"],
			"weight": weight_right,
			"parts": [
				{
					"vanish": Vector2(vanishing_point_right_x, vanishing_point_y),
					"end": end_right,
					"max_scale": right_max_scale,
					"texture": right_texture,
				},
			],
		},
		"center": {
			"columns": PATTERN_COLUMNS["center"],
			"weight": weight_center,
			"parts": [
				{
					"vanish": Vector2(vanishing_point_center_x, vanishing_point_y),
					"end": end_center,
					"max_scale": center_max_scale,
					"texture": center_texture,
				},
			],
		},
		"both": {
			"columns": PATTERN_COLUMNS["both"],
			"weight": weight_both_sides,
			"parts": [
				{
					"vanish": Vector2(vanishing_point_left_x, vanishing_point_y),
					"end": end_left,
					"max_scale": both_left_max_scale,
					"texture": both_left_texture,
				},
				{
					"vanish": Vector2(vanishing_point_right_x, vanishing_point_y),
					"end": end_right,
					"max_scale": both_right_max_scale,
					"texture": both_right_texture,
				},
			],
		},
	}

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
		var pattern_cfg: Dictionary = _pattern_table.get(cliff_data.pattern, {})
		var parts: Array = pattern_cfg.get("parts", [])
		if parts.is_empty():
			continue

		var part_states: Array = []
		for part in parts:
			part_states.append({
				"position": part.vanish.lerp(part.end, perspective_curve),
				"scale": min_scale.lerp(part.max_scale, perspective_curve),
			})

		cliff_data.part_states = part_states
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
	var candidates: Array = []
	var total_weight := 0.0

	for pattern in _pattern_table.keys():
		if pattern == "both" and _last_pattern == "both":
			continue # jangan "both" 2x berturut-turut, biar ritme-nya gak berat mulu

		var union: Array = existing_blocked.duplicate()
		for col in _pattern_table[pattern].columns:
			if col not in union:
				union.append(col)

		if union.size() >= 3:
			continue # bakal nutup semua kolom, gak fair buat player -> skip

		var w: float = _pattern_table[pattern].weight
		if w <= 0.0:
			continue

		candidates.append(pattern)
		total_weight += w

	if candidates.is_empty() or total_weight <= 0.0:
		return ""

	var roll := randf() * total_weight
	var cumulative := 0.0
	for pattern in candidates:
		cumulative += _pattern_table[pattern].weight
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
		"part_states": [],
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

## Warna rim-light buat 1 obstacle di frame sekarang: kuning transparan waktu masih jauh,
## geser ke merah pekat + pulsing waktu udah lewat telegraph_near_progress (mepet ke player).
## Ini yang bikin obstacle kiri/kanan/both tetep gampang dibaca walau warnanya mirip BG.
func _get_telegraph_color(cliff_data: Dictionary) -> Color:
	var p: float = cliff_data.progress
	if p <= telegraph_near_progress:
		return telegraph_color_far

	var t: float = clampf((p - telegraph_near_progress) / max(0.0001, 1.0 - telegraph_near_progress), 0.0, 1.0)
	var base_color := telegraph_color_far.lerp(telegraph_color_near, t)

	# Pulsing makin cepet & makin kentara pas makin deket, biar mata player ketarik ke situ.
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 1000.0 * telegraph_pulse_speed)
	base_color.a = lerpf(base_color.a, base_color.a * (0.55 + 0.45 * pulse), t)
	return base_color

func _draw() -> void:
	var sorted_cliffs = active_cliffs.duplicate()
	sorted_cliffs.sort_custom(func(a, b): return a.progress < b.progress)

	for cliff_data in sorted_cliffs:
		var pattern_cfg: Dictionary = _pattern_table.get(cliff_data.pattern, {})
		var parts: Array = pattern_cfg.get("parts", [])
		var part_states: Array = cliff_data.get("part_states", [])
		var needs_telegraph: bool = cliff_data.pattern in telegraph_patterns
		var rim_color: Color = _get_telegraph_color(cliff_data) if needs_telegraph else Color.WHITE

		for i in range(parts.size()):
			if i >= part_states.size():
				continue

			var tex: Texture2D = parts[i].get("texture")
			if tex == null:
				continue

			var state: Dictionary = part_states[i]
			var tex_size = tex.get_size()
			var offset = -tex_size / 2.0

			draw_set_transform(state.position, 0.0, state.scale)

			# Rim-light/outline ekstra biar obstacle di kiri/kanan gak nyampur sama tebing
			# dekoratif di background (warna & siluetnya kebetulan mirip).
			if needs_telegraph:
				for dir in OUTLINE_DIRECTIONS:
					draw_texture(tex, offset + dir * telegraph_outline_px, rim_color)

			draw_texture(tex, offset)
