extends Node2D

@onready var start_screen := $StartScreen
@onready var world := $World

var game_active: bool = false
var new_game: bool = false

func _ready() -> void:
	game_active = false
	new_game = false
	if start_screen:
		start_screen.visible = true
	if world:
		world.visible = false


func _process(delta: float) -> void:
	if not game_active:
		if start_screen and start_screen.game_active:
			game_active = true
			new_game = start_screen.new_game
			start_screen.visible = false

			if world:
				world.visible = true
				if world.has_method("start_game"):
					world.start_game(new_game)
	else:
		if world and world.has_method("update_world"):
			world.update_world(delta)

