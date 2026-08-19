extends Node2D

const TargetShipScene: PackedScene = preload("res://Objects/target_ship.tscn")

@onready var player: PlayerShip = $Player
@onready var hud_text_box: HudTextBox = $HudTextBox
@onready var obstacle_spawner: Node = $ObstacleCliffSpawner

# UI TextHud
@onready var speed_label: Label = $TextHud/SpeedLabel
@onready var distance_label: Label = $TextHud/DistanceLabel
@onready var crash_label: Label = $TextHud/CrashLabel

# Manager
var gameplay_manager: GameplayManager
var target_ship: TargetShip

func _ready() -> void:
	BGMPlayer.play_bgm(BGMPlayer.GAMEPLAY_BGM)
	
	# Setup GameplayManager
	gameplay_manager = GameplayManager.new()
	gameplay_manager.name = "GameplayManager"
	add_child(gameplay_manager)

	# Setup TargetShip (belum kelihatan sampai sisa jarak <= 1000m)
	target_ship = TargetShipScene.instantiate()
	target_ship.name = "TargetShip"
	target_ship.z_index = 0
	add_child(target_ship)
	
	# Hubungkan sinyal player
	if player:
		player.player_hit.connect(_on_player_hit)
		gameplay_manager.player = player
	
	# Hubungkan sinyal manager
	gameplay_manager.distance_changed.connect(_on_distance_changed)
	gameplay_manager.speed_changed.connect(_on_speed_changed)
	gameplay_manager.collision_happened.connect(_on_collision_happened)
	gameplay_manager.target_appeared.connect(_on_target_appeared)
	gameplay_manager.zone_entered.connect(_on_zone_entered)
	gameplay_manager.game_won.connect(_on_game_won)
	gameplay_manager.game_lost.connect(_on_game_lost)
	
	_init_hud()
	gameplay_manager.start_game()
	
	if hud_text_box:
		hud_text_box.show_message("Target berada 8000m dari kita! Kejar dia!!!", 2.5, 3.0)


func _init_hud() -> void:
	if distance_label:
		distance_label.text = "Jarak: 0/9000"
	if speed_label:
		speed_label.text = "Speed: 50 m/s"
	if crash_label:
		crash_label.text = "Crash: 0/10"

# Callback manager
func _on_distance_changed(distance: float, total: float) -> void:
	if distance_label:
		distance_label.text = "Jarak: %d/%d" % [int(distance), int(total)]

	# Update posisi/skala TargetShip selama final stretch (sisa jarak <= 1000m)
	if target_ship and gameplay_manager:
		target_ship.update_progress(
			gameplay_manager.get_distance_remaining(),
			gameplay_manager.FINAL_STRETCH_REMAINING
		)

func _on_speed_changed(speed: float, _top_speed: float) -> void:
	if speed_label:
		speed_label.text = "Speed: %d m/s" % int(speed)

func _on_collision_happened(count: int, max_count: int) -> void:
	if crash_label:
		crash_label.text = "Crash: %d/%d" % [count, max_count]
	
	if hud_text_box:
		hud_text_box.show_message("Tabrakan! -500m, Speed Reset!", 2.0)

# Notif #1: sisa jarak <= 1000m -> target mulai terlihat + pesawat target muncul
# + obstacle dikurangin biar player fokus ngejar target
func _on_target_appeared() -> void:
	if hud_text_box:
		hud_text_box.show_message("Target terdeteksi di depan!", 2.5)

	if target_ship:
		target_ship.appear()

	if obstacle_spawner and obstacle_spawner.has_method("set_final_stretch"):
		obstacle_spawner.set_final_stretch(true)

# Notif #2: sudah masuk radius aktivasi (900m), kasih jeda sebelum menang resmi
func _on_zone_entered(grace_seconds: float) -> void:
	if hud_text_box:
		hud_text_box.show_message("Masuk zona aktivasi! Bersiap...", grace_seconds)

func _on_game_won() -> void:
	if hud_text_box:
		hud_text_box.show_message("Target tercapai! Kerja Bagus!", 3.0)
	
	await get_tree().create_timer(3.0).timeout
	SceneTransition.goto_scene("res://Objects/MainMenu.tscn")

func _on_game_lost(reason: String) -> void:
	var message := "Game Over!"
	match reason:
		"no_time":
			message = "Bensin habis! Game Over!"
		"no_lives":
			message = "Pesawat rusak parah! Game Over!"
	
	if hud_text_box:
		hud_text_box.show_message(message, 3.0)
	
	await get_tree().create_timer(2.0).timeout
	SceneTransition.goto_scene("res://Objects/game_over.tscn")
	BGMPlayer.stop_bgm()
	

# Callback player
func _on_player_hit() -> void:
	if gameplay_manager:
		gameplay_manager.on_player_hit()
