extends CanvasLayer

signal sequence_finished

@onready var tint: ColorRect = $Tint
@onready var title_label: Label = $Panel/Title
@onready var start_sprite: TextureRect = $Panel/StartSprite
@onready var arrow_label: Label = $Panel/Arrow
@onready var end_sprite: TextureRect = $Panel/EndSprite

var _active: bool = false
var _elapsed: float = 0.0
var _duration: float = 1.8
var _start_tex: Texture2D
var _end_tex: Texture2D
var _title_text: String = ""


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_active() -> bool:
	return _active


func play_sequence(start_tex: Texture2D, end_tex: Texture2D, start_name: String, end_name: String, is_unfusion: bool) -> void:
	_start_tex = start_tex
	_end_tex = end_tex
	_title_text = "Unfusing %s -> %s" % [start_name, end_name] if is_unfusion else "Fusing %s -> %s" % [start_name, end_name]
	_elapsed = 0.0
	_active = true
	visible = true
	tint.visible = true
	title_label.text = _title_text
	start_sprite.texture = _start_tex
	end_sprite.texture = _end_tex
	start_sprite.modulate = Color(1, 1, 1, 1)
	end_sprite.modulate = Color(1, 1, 1, 0.0)
	arrow_label.modulate = Color(1, 1, 1, 0.4)
	set_process(true)


func skip() -> void:
	if not _active:
		return
	_finish_sequence()


func _process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta
	var t: float = clamp(_elapsed / _duration, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(_elapsed * 9.0)
	tint.color = Color(0, 0, 0, 0.35 + pulse * 0.15)
	arrow_label.modulate = Color(1, 1, 1, 0.35 + pulse * 0.65)

	if t < 0.5:
		start_sprite.modulate.a = 1.0
		end_sprite.modulate.a = 0.0
	else:
		var blend: float = (t - 0.5) / 0.5
		start_sprite.modulate.a = 1.0 - blend
		end_sprite.modulate.a = blend

	if t >= 1.0:
		_finish_sequence()


func _finish_sequence() -> void:
	_active = false
	set_process(false)
	visible = false
	emit_signal("sequence_finished")
