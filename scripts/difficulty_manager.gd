extends Node

## Autoload (singleton) yang nyimpen pilihan difficulty player dari scene
## DifficultySelect, terus dipakai GameplayManager buat nentuin berapa kali
## boleh nabrak sebelum game over. Cuma itu doang yang beda antar difficulty.

enum Difficulty { EASY, MEDIUM, HARD }

# Default difficulty kalau player entah gimana caranya masuk ke gameplay
# tanpa lewat scene pilih difficulty dulu (jaga-jaga).
var current_difficulty: Difficulty = Difficulty.MEDIUM

# Jumlah maksimum nabrak yang diperbolehkan per difficulty.
const MAX_COLLISIONS_BY_DIFFICULTY := {
	Difficulty.EASY: 10,
	Difficulty.MEDIUM: 7,
	Difficulty.HARD: 5,
}

func set_difficulty(difficulty: Difficulty) -> void:
	current_difficulty = difficulty

func get_max_collisions() -> int:
	return MAX_COLLISIONS_BY_DIFFICULTY.get(current_difficulty, 10)

func get_difficulty_name() -> String:
	match current_difficulty:
		Difficulty.EASY:
			return "Easy"
		Difficulty.MEDIUM:
			return "Medium"
		Difficulty.HARD:
			return "Hard"
	return "Medium"
