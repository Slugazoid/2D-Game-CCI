extends Button

@export var icon_color: Color = Color(0.92, 0.92, 0.96)
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

	var w := size.x
	var h := size.y
	var line_width := h * 0.12
	var p1 := Vector2(w * 0.62, h * 0.25)
	var p2 := Vector2(w * 0.32, h * 0.5)
	var p3 := Vector2(w * 0.62, h * 0.75)
	draw_line(p1, p2, icon_color, line_width, true)
	draw_line(p2, p3, icon_color, line_width, true)


func _on_hover() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.1, 1.1), 0.12)


func _on_unhover() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
