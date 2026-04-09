extends Control

var game_active: bool = false
var new_game: bool = false

func _ready() -> void:
	game_active = false
	new_game = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not game_active:
		game_active = true
		new_game = true

