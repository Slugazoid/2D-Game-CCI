extends Button
## Tombol Play, iconnya segitiga digambar manual pake _draw().

@export var icon_color: Color = Color(0.92, 0.25, 0.25)
@export var bg_color: Color = Color(0.08, 0.08, 0.1, 0.55)

func _ready() -> void:
	flat = true
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)


func _draw() -> void:
	var center := size / 2.0
	var base_radius: float = min(size.x, size.y) * 0.5

	draw_circle(center, base_radius, bg_color)

	var r := base_radius * 0.5
	var p1 := center + Vector2(-r * 0.6, -r)
	var p2 := center + Vector2(-r * 0.6, r)
	var p3 := center + Vector2(r * 1.05, 0)
	draw_polygon(PackedVector2Array([p1, p2, p3]), PackedColorArray([icon_color]))


func _on_hover() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.12, 1.12), 0.12)


func _on_unhover() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
