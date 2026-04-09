extends CharacterBody2D

const CHARACTER_SHEET_COLS: int = 4
const CHARACTER_SHEET_ROWS: int = 4
const WALK_FPS: float = 8.0

@export var speed: float = 150.0

var facing_direction: String = "down"
var blocked: bool = false
var _character_sprite_frames_cache: Dictionary = {}


func _ready() -> void:
	_ensure_camera()
	_build_collision_shape()
	_build_player_sprite()
	_refresh_player_sprite(false)


func _physics_process(delta: float) -> void:
	if blocked:
		velocity = Vector2.ZERO
		move_and_slide()
		_refresh_player_sprite(false)
		return

	var input_vector := Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)

	var moving: bool = input_vector.length() > 0.0
	if moving:
		input_vector = input_vector.normalized()
		if abs(input_vector.x) > abs(input_vector.y):
			facing_direction = "right" if input_vector.x > 0.0 else "left"
		else:
			facing_direction = "down" if input_vector.y > 0.0 else "up"

	velocity = input_vector * speed
	move_and_slide()
	_refresh_player_sprite(moving)


func handle_input(_delta: float) -> void:
	# Input is read directly in _physics_process.
	pass


func set_facing(direction: String) -> void:
	facing_direction = direction
	_refresh_player_sprite(false)


func set_blocked(value: bool) -> void:
	blocked = value
	if blocked:
		velocity = Vector2.ZERO


func block() -> void:
	set_blocked(true)


func unblock() -> void:
	set_blocked(false)


func _ensure_camera() -> void:
	if has_node("Camera2D"):
		return

	var camera := Camera2D.new()
	camera.name = "Camera2D"
	camera.enabled = true
	add_child(camera)


func _build_collision_shape() -> void:
	if has_node("CollisionShape2D"):
		return

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(24, 8)
	collision.shape = shape
	collision.position = Vector2.ZERO
	add_child(collision)


func _build_player_sprite() -> void:
	if not has_node("CharacterSprite"):
		var sprite := AnimatedSprite2D.new()
		sprite.name = "CharacterSprite"
		sprite.centered = true
		sprite.position = Vector2.ZERO
		sprite.speed_scale = WALK_FPS / 6.0
		add_child(sprite)

	if not has_node("FallbackMarker"):
		var marker := Polygon2D.new()
		marker.name = "FallbackMarker"
		marker.polygon = PackedVector2Array([
			Vector2(0, -16),
			Vector2(12, 0),
			Vector2(0, 16),
			Vector2(-12, 0),
		])
		marker.color = Color(0.95, 0.92, 0.35, 1.0)
		marker.visible = false
		add_child(marker)


func _refresh_player_sprite(moving: bool) -> void:
	var sprite: AnimatedSprite2D = get_node_or_null("CharacterSprite") as AnimatedSprite2D
	var marker: Polygon2D = get_node_or_null("FallbackMarker") as Polygon2D
	if sprite == null:
		return

	var frames: SpriteFrames = _get_character_sprite_frames("player", facing_direction)
	if frames == null:
		if marker:
			marker.visible = true
		sprite.visible = false
		return

	if marker:
		marker.visible = false
	sprite.visible = true
	sprite.sprite_frames = frames
	var target_anim: String = "walk" if moving else "idle"
	if sprite.animation != target_anim:
		sprite.animation = target_anim
	if moving:
		if not sprite.is_playing():
			sprite.play()
	else:
		sprite.stop()
		sprite.frame = 0


func _get_character_sprite_frames(graphic_name: String, direction: String) -> SpriteFrames:
	var row_lookup := {"down": 0, "left": 1, "right": 2, "up": 3}
	var row_index: int = int(row_lookup.get(direction, 0))
	var cache_key: String = "%s:%d" % [graphic_name, row_index]
	if _character_sprite_frames_cache.has(cache_key):
		return _character_sprite_frames_cache[cache_key]

	var image_path: String = "res://images/characters/%s.png" % graphic_name
	if not FileAccess.file_exists(image_path):
		return null

	var source_tex: Texture2D = load(image_path)
	if source_tex == null:
		return null
	var image: Image = source_tex.get_image()
	if image == null:
		return null

	var frame_width: int = int(image.get_width() / CHARACTER_SHEET_COLS)
	var frame_height: int = int(image.get_height() / CHARACTER_SHEET_ROWS)
	if frame_width <= 0 or frame_height <= 0:
		return null

	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", 1.0)
	frames.add_animation("walk")
	frames.set_animation_loop("walk", true)
	frames.set_animation_speed("walk", WALK_FPS)

	for col in range(CHARACTER_SHEET_COLS):
		var frame_image: Image = Image.create(frame_width, frame_height, false, image.get_format())
		frame_image.blit_rect(
			image,
			Rect2i(col * frame_width, row_index * frame_height, frame_width, frame_height),
			Vector2i.ZERO
		)
		var tex: Texture2D = ImageTexture.create_from_image(frame_image)
		if col == 0:
			frames.add_frame("idle", tex)
		frames.add_frame("walk", tex)

	_character_sprite_frames_cache[cache_key] = frames
	return frames
