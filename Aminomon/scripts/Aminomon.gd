extends Resource
class_name Aminomon

const BigData := preload("res://scripts/BigBigData.gd")

var name: String
var level: int
var paused: bool = false
var element: String
var base_stats: Dictionary
var health: float
var energy: float
var initiative: float = 0.0
var abilities: Dictionary
var defending: bool = false
var xp: float
var level_up: float
var fusion: Variant = null
var unfusion: Variant = null


func _init(_name: String, _level: int, xp_amount: float) -> void:
	name = _name
	level = _level
	paused = false

	var data: Dictionary = BigData.PEPTIDE_DEX.get(name, {})
	if data.is_empty() or not data.has("stats") or not data.has("ability"):
		push_error("Unknown Aminomon: %s" % name)
		data = {
			"stats": {"MAX_HEALTH": 10, "MAX_ENERGY": 10, "attack": 1, "defense": 1, "speed": 1, "recovery": 1, "element": "normal"},
			"ability": {}
		}

	element = data["stats"]["element"]
	base_stats = data["stats"]
	health = base_stats["MAX_HEALTH"] * level
	energy = base_stats["MAX_ENERGY"] * level
	initiative = 0.0
	abilities = data["ability"]
	defending = false
	xp = xp_amount
	level_up = float(level) * 150.0

	fusion = data.get("fusion", null)
	unfusion = data.get("unfusion", null)


func get_single_stat(stat: String) -> float:
	return float(base_stats.get(stat, 0)) * float(level)


func get_all_stats() -> Dictionary:
	return {
		"health": get_single_stat("MAX_HEALTH"),
		"energy": get_single_stat("MAX_ENERGY"),
		"attack": get_single_stat("attack"),
		"defense": get_single_stat("defense"),
		"speed": get_single_stat("speed"),
		"recovery": get_single_stat("recovery"),
	}


func get_skills(all: bool = true) -> Array:
	var result: Array = []
	for lvl in abilities.keys():
		var skill: String = abilities[lvl]
		if level >= int(lvl):
			if all:
				result.append(skill)
			else:
				var cost: float = float(BigData.SKILLS_DATA[skill]["cost"])
				if energy > cost:
					result.append(skill)
	return result


func get_info() -> Array:
	return [
		[health, get_single_stat("MAX_HEALTH")],
		[energy, get_single_stat("MAX_ENERGY")],
		[initiative, 100.0],
	]


func subtract_cost(attack: String) -> void:
	var cost: float = float(BigData.SKILLS_DATA[attack]["cost"])
	energy -= cost


func get_attack_value(attack: String) -> float:
	if attack == "heal":
		return get_single_stat("recovery") * BigData.SKILLS_DATA[attack]["amount"]
	return get_single_stat("attack") * BigData.SKILLS_DATA[attack]["amount"]


func add_xp(amount: float) -> void:
	xp += amount
	while xp >= level_up:
		xp -= level_up
		level += 1
		level_up = float(level) * 150.0


func _health_energy_limiter() -> void:
	health = clamp(health, 0.0, get_single_stat("MAX_HEALTH"))
	energy = clamp(energy, 0.0, get_single_stat("MAX_ENERGY"))


func update(delta: float) -> void:
	_health_energy_limiter()
	if not paused:
		initiative += get_single_stat("speed") * delta

