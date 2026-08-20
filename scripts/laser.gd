extends Area2D
class_name Laser

@export var duration: float = 0.2
@export var start_scale: Vector2 = Vector2(1.5, 1.5)
@export var target_scale: Vector2 = Vector2(0.1, 0.1)

var start_pos: Vector2
var target_pos: Vector2
var progress: float = 0.0
var initialized: bool = false

func _ready() -> void:
	if not initialized:
		setup(global_position, global_position + Vector2(0, -160))

func setup(start_position: Vector2, target_position: Vector2) -> void:
	initialized = true
	start_pos = start_position
	target_pos = target_position
	global_position = start_pos
	scale = start_scale
	
	var diff = target_pos - start_pos
	if diff.length() > 1.0:
		rotation = diff.angle() + (PI / 2.0)

func _process(delta: float) -> void:
	progress += delta / duration
	if progress >= 1.0:
		queue_free()
		return
	
	global_position = start_pos.lerp(target_pos, progress)
	scale = start_scale.lerp(target_scale, progress)

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body is PlayerShip:
		return
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area == self:
		return

	# Batu obstacle (pola "both") yang bisa dihancurin -> hitbox virtualnya
	# adalah ObstacleHitbox, bukan child dari sesuatu, jadi dicek duluan.
	if area is ObstacleHitbox:
		area.take_hit()
		queue_free()
		return

	# TargetShip dideteksi lewat Area2D anak (mis. "HitArea") yang jadi
	# child langsung dari node TargetShip -> parent-nya adalah TargetShip.
	var target := area.get_parent()
	if target is TargetShip:
		target.take_hit()

	queue_free()
