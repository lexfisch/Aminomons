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
var rarity_variant: String = "normal"
var trait_id: String = "neutral"
var status_state: Dictionary = {"type": "none", "turns": 0}
var passive_id: String = ""


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
	rarity_variant = "normal"
	trait_id = "neutral"
	status_state = {"type": "none", "turns": 0}
	passive_id = BigData.get_species_passive(name, element)


func get_single_stat(stat: String) -> float:
	var base_value: float = float(base_stats.get(stat, 0)) * float(level)
	var trait_data: Dictionary = BigData.TRAIT_DATA.get(trait_id, BigData.TRAIT_DATA.get("neutral", {}))
	var multipliers: Dictionary = trait_data.get("multipliers", {})
	var multiplier: float = float(multipliers.get(stat, 1.0))
	multiplier = clamp(multiplier, 0.75, 1.5)
	return base_value * multiplier


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


func set_mon_metadata(
	rarity_value: String = "normal",
	trait_value: String = "neutral",
	status_value: Dictionary = {},
	passive_value: String = ""
) -> void:
	set_rarity(rarity_value)
	set_trait(trait_value)
	if status_value.is_empty():
		clear_status_state()
	else:
		var status_type: String = str(status_value.get("type", "none")).strip_edges().to_lower()
		var status_turns: int = int(status_value.get("turns", 0))
		set_status(status_type, status_turns)
	if passive_value.strip_edges().is_empty():
		passive_id = BigData.get_species_passive(name, element)
	else:
		passive_id = passive_value.strip_edges().to_lower()


func set_rarity(value: String) -> void:
	var next_value: String = value.strip_edges().to_lower()
	if not BigData.RARITY_VARIANTS.has(next_value):
		next_value = "normal"
	rarity_variant = next_value


func set_trait(value: String) -> void:
	var next_value: String = value.strip_edges().to_lower()
	if not BigData.TRAIT_DATA.has(next_value):
		next_value = "neutral"
	trait_id = next_value


func set_status(status_type: String, turns: int = 0) -> void:
	var normalized: String = status_type.strip_edges().to_lower()
	if normalized == "none" or not BigData.STATUS_RULES.has(normalized):
		clear_status_state()
		return
	var rule: Dictionary = BigData.STATUS_RULES.get(normalized, {})
	var default_turns: int = int(rule.get("default_turns", 0))
	var final_turns: int = max(0, turns if turns > 0 else default_turns)
	status_state = {"type": normalized, "turns": final_turns}


func clear_status_state() -> void:
	status_state = {"type": "none", "turns": 0}


func has_status(status_type: String = "") -> bool:
	var current_type: String = str(status_state.get("type", "none")).strip_edges().to_lower()
	if current_type == "none":
		return false
	if status_type.strip_edges().is_empty():
		return true
	return current_type == status_type.strip_edges().to_lower()


func status_type() -> String:
	return str(status_state.get("type", "none")).strip_edges().to_lower()


func status_turns_remaining() -> int:
	return int(status_state.get("turns", 0))


func decrement_status_turn() -> int:
	if not has_status():
		return 0
	var turns_left: int = max(0, int(status_state.get("turns", 0)) - 1)
	status_state["turns"] = turns_left
	if turns_left <= 0:
		clear_status_state()
	return turns_left

