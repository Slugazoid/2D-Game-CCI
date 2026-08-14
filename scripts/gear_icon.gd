extends Button
## Tombol Settings, iconnya digambar manual pake _draw() (gak butuh file gambar).

@export var icon_color: Color = Color(0.92, 0.92, 0.96)
@export var bg_color: Color = Color(0.08, 0.08, 0.1, 0.55)

func _ready() -> void:
	flat = true # hilangin style default tombol Godot
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)


func _draw() -> void:
	var center := size / 2.0
	var base_radius: float = min(size.x, size.y) * 0.5

	# lingkaran belakang (biar keliatan kayak tombol bulat)
	draw_circle(center, base_radius, bg_color)

	var ring_radius := base_radius * 0.55
	var ring_width := ring_radius * 0.42

	# badan gear (ring/cincin, tengahnya otomatis bolong karna cuma garis)
	draw_arc(center, ring_radius, 0, TAU, 40, icon_color, ring_width, true)

	# gigi-gigi gear di sekeliling ring
	var teeth := 8
	var tooth_len := ring_radius * 0.45
	var tooth_w := ring_radius * 0.5
	for i in range(teeth):
		var angle: float = i * TAU / teeth
		var dir := Vector2(cos(angle), sin(angle))
		var perp := Vector2(-dir.y, dir.x)
		var base_point: Vector2 = center + dir * (ring_radius + ring_width * 0.1)
		var tip_point: Vector2 = center + dir * (ring_radius + ring_width * 0.1 + tooth_len)
		var p1: Vector2 = base_point + perp * (tooth_w * 0.5)
		var p2: Vector2 = base_point - perp * (tooth_w * 0.5)
		var p3: Vector2 = tip_point - perp * (tooth_w * 0.5)
		var p4: Vector2 = tip_point + perp * (tooth_w * 0.5)
		draw_polygon(PackedVector2Array([p1, p2, p3, p4]), PackedColorArray([icon_color]))


func _on_hover() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.12)


func _on_unhover() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
