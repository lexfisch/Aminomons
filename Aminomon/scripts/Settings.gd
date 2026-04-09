extends Resource
class_name Settings

const WIN_WIDTH: int = 1280
const WIN_HEIGHT: int = 720
const TILESIZE: int = 64
const ANISPEED: float = 6.0
const BATTLEWINDOW_WIDTH: int = 4

static var POSITIONS_IN_BATTLE := {
	"player": {"top": Vector2(900, 550)},
	"opp": {"top": Vector2(360, 260)},
}

const BATTLE_GRAPHICS_LAYERS := {
	"outline": 0,
	"monster": 1,
	"name": 2,
	"effects": 3,
	"overlay": 4,
}

static var CHOICES_FOR_BATTLE := {
	"fight": {"pos": Vector2(-40, -20), "icon": "sword"},
	"switch": {"pos": Vector2(-40, 20), "icon": "arrows"},
	"catch": {"pos": Vector2(-30, 60), "icon": "hand"},
}

static var COLORS := {
	"white": Color.hex(0xf4fefa),
	"pure white": Color.hex(0xffffff),
	"dark": Color.hex(0x2b292c),
	"light": Color.hex(0xc8c8c8),
	"gray": Color.hex(0x3a373b),
	"gold": Color.hex(0xffd700),
	"light-gray": Color.hex(0x4b484d),
	"fire": Color.hex(0xf8a060),
	"water": Color.hex(0x50b0d8),
	"earth": Color.hex(0x64a990),
	"electric": Color.hex(0xffff00),
	"black": Color.hex(0x000000),
	"red": Color.hex(0xf03131),
	"blue": Color.hex(0x66d7ee),
	"normal": Color.hex(0xffffff),
	"dark white": Color.hex(0xf0f0f0),
	"yellow": Color.hex(0xffff00),
	"green": Color.hex(0x00ff00),
	"salmon": Color.hex(0xfa8072),
}

const LAYERS := {
	"basement": 0,
	"bg": 1,
	"shadow": 2,
	"main": 3,
	"top": 4,
}

