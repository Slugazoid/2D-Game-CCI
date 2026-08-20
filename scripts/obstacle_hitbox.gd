extends Area2D
class_name ObstacleHitbox

## Hitbox "virtual" buat 1 potongan batu obstacle pola "both" (kiri/kanan).
## Obstacle-nya sendiri digambar prosedural (_draw()) di obstacle_cliff_spawner.gd,
## jadi node Area2D ini cuma NGIKUTIN posisi & skala gambar tiap frame supaya laser
## (yang emang Area2D) bisa detect tabrakan lewat sinyal area_entered.

signal hit_by_laser

func _ready() -> void:
	add_to_group("destructible_obstacle")
	# Gak perlu nabrak obstacle lain / player, cuma buat dideteksi si laser.
	monitoring = false
	monitorable = true

func take_hit() -> void:
	hit_by_laser.emit()
