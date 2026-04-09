extends CharacterBody2D

@export var speed: float = 150.0


func _physics_process(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	if input_vector.length() > 0.0:
		input_vector = input_vector.normalized()

	velocity = input_vector * speed
	move_and_slide()


func handle_input(delta: float) -> void:
	# For now, Player reads input directly in _physics_process.
	# This method exists so World.gd can delegate input if you later
	# switch to event-driven or state-based movement.
	pass

