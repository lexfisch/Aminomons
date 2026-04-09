extends RefCounted
class_name BattleState


func build_opponent_party(ctx: Dictionary, aminomon_script: Script) -> Dictionary:
	var party: Dictionary = {}
	var kind: String = str(ctx.get("kind", ""))

	if kind == "trainer":
		var monsters: Dictionary = ctx.get("monsters", {})
		var indexes: Array = monsters.keys()
		indexes.sort()
		for index_variant in indexes:
			var source_index: int = int(index_variant)
			var row = monsters.get(source_index)
			if row is Array and (row as Array).size() >= 2:
				var row_array: Array = row
				var mon_name: String = str(row_array[0])
				var mon_level: int = int(row_array[1])
				party[source_index] = aminomon_script.new(mon_name, mon_level, 0.0)

	elif kind == "wild":
		var mon_name_wild: String = str(ctx.get("opponent_name", "alanine"))
		var mon_level_wild: int = int(ctx.get("opponent_level", 1))
		party[0] = aminomon_script.new(mon_name_wild, mon_level_wild, 0.0)

	return party


func build_runtime_context(input_context: Dictionary, player_party: Dictionary, opponent_party: Dictionary) -> Dictionary:
	var ctx: Dictionary = input_context.duplicate(true)
	ctx["state"] = "main_menu"
	ctx["cursor"] = 0
	ctx["message_queue"] = []
	ctx["message_index"] = 0
	ctx["next_state_after_messages"] = "main_menu"
	ctx["pending_end"] = {}
	ctx["turn"] = "player"
	ctx["effect"] = {}
	ctx["player_party"] = player_party
	ctx["opponent_party"] = opponent_party

	var player_active: int = first_alive_index(player_party)
	var opp_active: int = first_alive_index(opponent_party)
	if player_active == -1 or opp_active == -1:
		return {}

	ctx["active_player_index"] = player_active
	ctx["active_opponent_index"] = opp_active
	return ctx


func active_mon(ctx: Dictionary, player_side: bool):
	var party: Dictionary = ctx.get("player_party", {}) if player_side else ctx.get("opponent_party", {})
	var key_name: String = "active_player_index" if player_side else "active_opponent_index"
	var active_idx: int = int(ctx.get(key_name, -1))
	return party.get(active_idx, null)


func side_status_line(ctx: Dictionary, label_prefix: String, player_side: bool) -> String:
	var mon = active_mon(ctx, player_side)
	if mon == null:
		return "%s: (none)" % label_prefix
	var hp_now: int = int(round(float(mon.health)))
	var hp_max: int = int(round(mon.get_single_stat("MAX_HEALTH")))
	var en_now: int = int(round(float(mon.energy)))
	var en_max: int = int(round(mon.get_single_stat("MAX_ENERGY")))
	return "%s: %s Lv%d | HP %d/%d | EN %d/%d" % [
		label_prefix,
		str(mon.name),
		int(mon.level),
		hp_now, hp_max,
		en_now, en_max
	]


func menu_prompt(state: String) -> String:
	match state:
		"attack_menu":
			return "Choose an attack:"
		"switch_menu":
			return "Choose a party member to switch in:"
		_:
			return "Choose an action:"


func usable_skills_for_active_player(ctx: Dictionary) -> Array:
	var mon = active_mon(ctx, true)
	if mon == null:
		return []
	return mon.get_skills(false)


func switchable_player_indices(ctx: Dictionary, player_monsters: Dictionary) -> Array:
	var result: Array = []
	var active_idx: int = int(ctx.get("active_player_index", -1))
	var indexes: Array = player_monsters.keys()
	indexes.sort()
	for index_variant in indexes:
		var idx: int = int(index_variant)
		if idx == active_idx:
			continue
		var mon = player_monsters.get(idx)
		if mon == null:
			continue
		if float(mon.health) > 0.0:
			result.append(idx)
	return result


func current_menu_options(ctx: Dictionary, player_monsters: Dictionary) -> Array:
	var state: String = str(ctx.get("state", "main_menu"))
	if state == "attack_menu":
		var options_attack: Array = []
		var usable_skills: Array = usable_skills_for_active_player(ctx)
		if usable_skills.is_empty():
			options_attack.append("Basic Attack")
		else:
			for skill_variant in usable_skills:
				options_attack.append(str(skill_variant))
		options_attack.append("Wait")
		options_attack.append("Back")
		return options_attack

	if state == "switch_menu":
		var options_switch: Array = []
		var switchable: Array = switchable_player_indices(ctx, player_monsters)
		for index_variant in switchable:
			var idx: int = int(index_variant)
			var mon = player_monsters.get(idx)
			if mon == null:
				continue
			options_switch.append("%d: %s Lv%d" % [idx, str(mon.name), int(mon.level)])
		options_switch.append("Back")
		return options_switch

	var kind: String = str(ctx.get("kind", ""))
	var options_main: Array = ["Fight", "Switch"]
	if kind == "wild":
		options_main.append("Catch")
		options_main.append("Run")
	return options_main


func first_alive_index(party: Dictionary) -> int:
	var indexes: Array = party.keys()
	indexes.sort()
	for index_variant in indexes:
		var idx: int = int(index_variant)
		var mon = party.get(idx)
		if mon != null and float(mon.health) > 0.0:
			return idx
	return -1


func next_alive_index(party: Dictionary, exclude_index: int = -1) -> int:
	var indexes: Array = party.keys()
	indexes.sort()
	for index_variant in indexes:
		var idx: int = int(index_variant)
		if idx == exclude_index:
			continue
		var mon = party.get(idx)
		if mon != null and float(mon.health) > 0.0:
			return idx
	return -1


func set_state(ctx: Dictionary, state: String) -> void:
	ctx["state"] = state
	ctx["cursor"] = 0


func move_cursor(ctx: Dictionary, delta: int, options: Array) -> void:
	if options.is_empty():
		return
	var cursor: int = int(ctx.get("cursor", 0))
	ctx["cursor"] = posmod(cursor + delta, options.size())
