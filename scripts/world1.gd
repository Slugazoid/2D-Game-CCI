extends Node2D

@onready var player: PlayerShip = $Player
@onready var hud_text_box: HudTextBox = $HudTextBox

# UI TextHud
@onready var speed_label: Label = $TextHud/SpeedLabel
@onready var distance_label: Label = $TextHud/DistanceLabel
@onready var crash_label: Label = $TextHud/CrashLabel

# Manager
var gameplay_manager: GameplayManager

func _ready() -> void:
	BGMPlayer.stop_bgm()
	
	# Setup GameplayManager
	gameplay_manager = GameplayManager.new()
	gameplay_manager.name = "GameplayManager"
	add_child(gameplay_manager)
	
	# Hubungkan sinyal player
	if player:
		player.player_hit.connect(_on_player_hit)
		gameplay_manager.player = player
	
	# Hubungkan sinyal manager
	gameplay_manager.distance_changed.connect(_on_distance_changed)
	gameplay_manager.speed_changed.connect(_on_speed_changed)
	gameplay_manager.collision_happened.connect(_on_collision_happened)
	gameplay_manager.game_won.connect(_on_game_won)
	gameplay_manager.game_lost.connect(_on_game_lost)
	
	_init_hud()
	gameplay_manager.start_game()

func _init_hud() -> void:
	if distance_label:
		distance_label.text = "Jarak: 0/9000"
	if speed_label:
		speed_label.text = "Speed: 50 m/s"
	if crash_label:
		crash_label.text = "Crash: 0"

# Callback manager
func _on_distance_changed(distance: float, total: float) -> void:
	if distance_label:
		distance_label.text = "Jarak: %d/%d" % [int(distance), int(total)]

func _on_speed_changed(speed: float, _top_speed: float) -> void:
	if speed_label:
		speed_label.text = "Speed: %d m/s" % int(speed)

func _on_collision_happened(count: int) -> void:
	if crash_label:
		crash_label.text = "Crash: %d" % count
	
	if hud_text_box:
		hud_text_box.show_message("Tabrakan! -500m, Speed Reset!", 2.0)

func _on_game_won() -> void:
	if hud_text_box:
		hud_text_box.show_message("Target tercapai! Skill aktif!", 3.0)
	
	await get_tree().create_timer(3.0).timeout
	SceneTransition.goto_scene("res://Objects/MainMenu.tscn")

func _on_game_lost() -> void:
	if hud_text_box:
		hud_text_box.show_message("Waktu habis! Game Over!", 3.0)
	
	await get_tree().create_timer(3.0).timeout
	SceneTransition.goto_scene("res://Objects/MainMenu.tscn")

# Callback player
func _on_player_hit() -> void:
	if gameplay_manager:
		gameplay_manager.on_player_hit()
