extends Node2D

@export var cliff_texture: Texture2D
@export var cliff_count: int = 15 # Berapa banyak tebing yang mau digambar

@export var vanishing_point: Vector2 = Vector2(576, 324) 
@export var end_point: Vector2 = Vector2(0, 200)

@export var speed: float = 0.3
@export var min_scale: Vector2 = Vector2(0.1, 0.1)
@export var max_scale: Vector2 = Vector2(4.0, 4.0)
@export var curve_power: float = 1.5

# Ini adalah waktu progres global yang akan menggerakkan semua tebing
var global_progress: float = 0.0

func _process(delta: float) -> void:
	global_progress += speed * delta
	
	if global_progress >= 1.0:
		global_progress = fmod(global_progress, 1.0)
		
	# queue_redraw() akan memerintahkan Godot untuk mengeksekusi ulang fungsi _draw() di frame ini
	queue_redraw()

func _draw() -> void:
	if not cliff_texture:
		return # Jangan menggambar jika tekstur belum dimasukkan
		
	var draw_data = []
	var spacing = 1.0 / cliff_count # Jarak antar tebing agar terdistribusi merata
	
	# 1. Hitung progres masing-masing tebing menggunakan perulangan
	for i in range(cliff_count):
		# fmod menjaga agar nilainya tetap berada di rentang 0.0 hingga 1.0
		var p = fmod(global_progress + (i * spacing), 1.0)
		draw_data.append(p)
		
	# 2. Urutkan data progres dari yang terkecil ke terbesar
	# Ini sangat penting! Benda yang jauh (progres kecil) harus digambar lebih dulu 
	# agar nantinya tertutup oleh benda yang dekat (progres besar).
	draw_data.sort()
	
	# Menentukan titik tengah gambar agar skalanya pas di tengah
	var tex_size = cliff_texture.get_size()
	var offset = -tex_size / 2.0 
	
	# 3. Proses menggambar ke layar
	for p in draw_data:
		var perspective_curve = pow(p, curve_power)
		var pos = vanishing_point.lerp(end_point, perspective_curve)
		var sc = min_scale.lerp(max_scale, perspective_curve)
		
		# Setel matriks transformasi (posisi dan skala) sebelum menggambar
		draw_set_transform(pos, 0.0, sc)
		
		# Gambar teksturnya!
		draw_texture(cliff_texture, offset)
