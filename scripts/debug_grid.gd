extends Node2D

func _draw() -> void:
	var spacing := 100
	var range_px := 2000
	for x in range(-range_px, range_px, spacing):
		draw_line(Vector2(x, -range_px), Vector2(x, range_px), Color(1, 1, 1, 0.15), 1.0)
	for y in range(-range_px, range_px, spacing):
		draw_line(Vector2(-range_px, y), Vector2(range_px, y), Color(1, 1, 1, 0.15), 1.0)
