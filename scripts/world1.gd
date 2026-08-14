extends Node2D

@onready var player: PlayerShip = $Player
@onready var hp_label: Label = $HpHud/HpLabel

func _ready() -> void:
	BGMPlayer.stop_bgm()
	
	# Connect player signals
	if player:
		player.health_changed.connect(_on_health_changed)
		player.player_died.connect(_on_player_died)
		# Initialize HP display
		_update_hp_label(player.hp, player.max_hp)

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	_update_hp_label(current_hp, max_hp)

func _update_hp_label(current_hp: int, max_hp: int) -> void:
	if hp_label:
		hp_label.text = "%d/%d" % [current_hp, max_hp]
		
		# Warna berubah berdasarkan HP
		if current_hp <= 1:
			hp_label.modulate = Color(1, 0.2, 0.2)  # Merah
		elif current_hp <= 2:
			hp_label.modulate = Color(1, 0.6, 0.2)  # Orange
		else:
			hp_label.modulate = Color.WHITE

func _on_player_died() -> void:
	# Delay sebentar sebelum kembali ke main menu
	await get_tree().create_timer(1.5).timeout
	SceneTransition.goto_scene("res://Objects/MainMenu.tscn")
