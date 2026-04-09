extends Node2D

const Settings := preload("res://scripts/Settings.gd")
const BigData := preload("res://scripts/BigBigData.gd")
const AminomonRes := preload("res://scripts/Aminomon.gd")

@onready var player := $Player

var game_active: bool = false
var new_game: bool = false

# Player party and storage mirror Main.Game.player_monsters / player_storage
var player_monsters: Dictionary = {}
var player_storage: Dictionary = {}


func start_game(is_new_game: bool) -> void:
	new_game = is_new_game
	game_active = true

	_create_team()
	_create_storage()
	# TODO: Map loading from TMX and NPC creation can be added here,
	# following the structure of Game.map_creation.


func update_world(delta: float) -> void:
	if not game_active:
		return

	_handle_input(delta)


func _handle_input(delta: float) -> void:
	if player and player.has_method("handle_input"):
		player.handle_input(delta)


func _create_team() -> void:
	var starters: Array = []
	for name in BigData.PEPTIDE_DEX.keys():
		var info: Dictionary = BigData.PEPTIDE_DEX[name]
		if int(info.get("id", 0)) % 3 == 1:
			starters.append(name)

	if new_game or starters.is_empty():
		var count := randi_range(2, 4)
		for i in count:
			var chosen := starters.pick_random()
			player_monsters[i] = AminomonRes.new(chosen, 5, 0)
	else:
		# Placeholder for CSV-based load; can be wired to Godot's FileAccess
		# to mirror load_trainer_data from SettingsAndSupport.py.
		var count := randi_range(2, 4)
		for i in count:
			var chosen := starters.pick_random()
			player_monsters[i] = AminomonRes.new(chosen, 5, 0)


func _create_storage() -> void:
	# Placeholder: in the Pygame version this loads CSV storage.
	# Here we keep storage empty by default; save/load can later use FileAccess
	# and BigData.PEPTIDE_DEX to reconstruct Aminomon instances.
	player_storage.clear()

