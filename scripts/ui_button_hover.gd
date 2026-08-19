extends TextureButton

func _ready() -> void:
	pivot_offset = size / 2.0
	resized.connect(func(): pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover)
	mouse_exited.connect(_on_unhover)

func _on_hover() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.08, 1.08), 0.12)

func _on_unhover() -> void:
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)
