extends Control

var game_active: bool = false
var new_game: bool = false
var selection_index: int = 0

@onready var option_new: Label = get_node_or_null("OptionNew") as Label
@onready var option_load: Label = get_node_or_null("OptionLoad") as Label

func _ready() -> void:
	game_active = false
	new_game = true
	selection_index = 0
	_refresh_option_labels()


func _unhandled_input(event: InputEvent) -> void:
	if game_active:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event
		if not key_event.pressed or key_event.echo:
			return

		match key_event.keycode:
			KEY_LEFT:
				selection_index = posmod(selection_index - 1, 2)
				_refresh_option_labels()
			KEY_RIGHT:
				selection_index = posmod(selection_index + 1, 2)
				_refresh_option_labels()
			KEY_SPACE, KEY_ENTER:
				_activate_selected_mode()
			KEY_L:
				selection_index = 1
				_refresh_option_labels()
				_activate_selected_mode()
			_:
				pass
		return

	if event.is_action_pressed("ui_accept"):
		_activate_selected_mode()


func _activate_selected_mode() -> void:
	game_active = true
	new_game = selection_index == 0


func _refresh_option_labels() -> void:
	if option_new != null:
		option_new.text = ">> New Game <<" if selection_index == 0 else "New Game"
		option_new.add_theme_font_size_override("font_size", 44 if selection_index == 0 else 34)
		option_new.modulate = Color(1.0, 0.95, 0.45, 1.0) if selection_index == 0 else Color(0.92, 0.92, 0.92, 1.0)
	if option_load != null:
		option_load.text = ">> Load Game <<" if selection_index == 1 else "Load Game"
		option_load.add_theme_font_size_override("font_size", 44 if selection_index == 1 else 34)
		option_load.modulate = Color(1.0, 0.95, 0.45, 1.0) if selection_index == 1 else Color(0.92, 0.92, 0.92, 1.0)

