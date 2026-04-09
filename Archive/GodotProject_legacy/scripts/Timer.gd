extends Resource
class_name TimerGD

var duration: int
var repeat: bool = false
var autostart: bool = false
var func_ref: Callable = Callable()

var _start_time: int = 0
var active: bool = false


func _init(_duration: int, _repeat: bool = false, _autostart: bool = false, _func: Callable = Callable()) -> void:
	duration = _duration
	repeat = _repeat
	autostart = _autostart
	func_ref = _func
	if autostart:
		turn_on()


func turn_on() -> void:
	active = true
	_start_time = Time.get_ticks_msec()


func turn_off() -> void:
	active = false
	_start_time = 0
	if repeat:
		turn_on()


func update() -> void:
	if not active:
		return
	var current_time := Time.get_ticks_msec()
	if current_time - _start_time >= duration:
		if func_ref.is_valid():
			func_ref.call()
		turn_off()

