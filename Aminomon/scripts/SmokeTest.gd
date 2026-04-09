extends SceneTree

var _failures: Array = []
var _checks_run: int = 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("[SmokeTest] Starting Godot migration smoke tests...")

	var world_scene: PackedScene = load("res://scenes/World.tscn")
	_check(world_scene != null, "World scene loads")
	if world_scene == null:
		_finish()
		return

	var world: Node = world_scene.instantiate()
	get_root().add_child(world)
	await process_frame
	await physics_frame
	await process_frame

	_check(world.has_method("start_game"), "World has start_game()")
	if not world.has_method("start_game"):
		_finish()
		return

	world.start_game(true)
	await process_frame
	await physics_frame

	await _run_world_tests(world)
	_finish()


func _run_world_tests(world: Node) -> void:
	_check(bool(world.get("game_active")), "World game_active set after start_game")
	_check(str(world.get("current_map_name")) == "firstlab", "Initial map is firstlab")

	var transition_zones: Array = world.get("transition_zones")
	var chemical_spill_zones: Array = world.get("chemical_spill_zones")
	var npc_records: Array = world.get("npc_records")
	var collision_root: Node = world.get("map_collision_root")
	var player: Node = world.get("player")

	_check(transition_zones.size() > 0, "Transition zones parsed from TMX")
	_check(chemical_spill_zones.size() > 0, "Chemical spill zones parsed from TMX")
	_check(npc_records.size() > 0, "NPCs parsed from TMX GameObjects")
	_check(collision_root != null, "Collision root exists")
	if collision_root != null:
		_check(collision_root.get_child_count() >= 10, "Collision bodies include walls + NPCs")
	_check(player != null, "Player exists")
	if player == null:
		return

	var player_collision: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	_check(player_collision != null, "Player collision shape exists")

	# Geometry sanity: first spill in firstlab is a tile object at x=512.5,y=800.25,h=32 so top-left y should be 768.25
	if chemical_spill_zones.size() > 0:
		var first_spill: Dictionary = chemical_spill_zones[0]
		var spill_rect: Rect2 = first_spill.get("rect", Rect2())
		_check(_approx(spill_rect.position.y, 768.25, 0.2), "Spill TMX rect uses tile-object top-left conversion")
		_check(_approx(spill_rect.size.x, 32.0, 0.1) and _approx(spill_rect.size.y, 32.0, 0.1), "Spill rect size is 32x32")

	# Physics-space overlap queries for wall and NPC collisions
	_check(_shape_overlaps(world, player_collision, Vector2(30, 200)), "Wall collision shape is queryable near left wall")
	if npc_records.size() > 0:
		var npc0: Dictionary = npc_records[0]
		var npc_pos: Vector2 = npc0.get("position", Vector2.ZERO)
		_check(_shape_overlaps(world, player_collision, npc_pos), "NPC collision body is queryable at NPC position")

	# Transition should change maps when player footprint intersects a transition rect
	if transition_zones.size() > 0 and world.has_method("_check_transitions"):
		var first_transition: Dictionary = transition_zones[0]
		var zone_rect: Rect2 = first_transition.get("rect", Rect2())
		var expected_target: String = str(first_transition.get("target", ""))
		player.set("global_position", zone_rect.get_center())
		world.set("transition_cooldown_until_msec", 0)
		world._check_transitions()
		_check(str(world.get("current_map_name")) == expected_target, "Transition zone changes current map")

	# Reload firstlab for spill/NPC interaction tests
	if world.has_method("_load_map"):
		world._load_map("firstlab", "world")
		await process_frame
		await physics_frame

	chemical_spill_zones = world.get("chemical_spill_zones")
	npc_records = world.get("npc_records")

	# Spill encounter timer should arm while standing still inside spill and cancel when leaving.
	if chemical_spill_zones.size() > 0 and world.has_method("_check_chemical_spills"):
		var spill_zone: Dictionary = chemical_spill_zones[0]
		var spill_zone_rect: Rect2 = spill_zone.get("rect", Rect2())
		player.set("global_position", spill_zone_rect.get_center())
		player.set("velocity", Vector2.ZERO)
		world.set("wild_encounter_cooldown_until_msec", 0)
		world.set("pending_spill_index", -1)
		world.set("pending_spill_encounter_at_msec", 0)
		world._check_chemical_spills()
		var pending_index: int = int(world.get("pending_spill_index"))
		var pending_time: int = int(world.get("pending_spill_encounter_at_msec"))
		_check(pending_index >= 0, "Standing in spill arms encounter timer without movement")
		_check(pending_time > Time.get_ticks_msec(), "Spill encounter timer is scheduled in the future")

		player.set("global_position", Vector2.ZERO)
		world._check_chemical_spills()
		_check(int(world.get("pending_spill_index")) == -1, "Leaving spill clears pending encounter index")
		_check(int(world.get("pending_spill_encounter_at_msec")) == 0, "Leaving spill clears pending encounter timer")

		player.set("global_position", spill_zone_rect.get_center())
		world.set("pending_spill_index", 0)
		world.set("pending_spill_encounter_at_msec", Time.get_ticks_msec() - 1)
		world._check_chemical_spills()
		_check(bool(world.get("battle_active")), "Spill encounter opens battle modal while standing in spill")
		var battle_context: Dictionary = world.get("battle_context")
		_check(str(battle_context.get("kind", "")) == "wild", "Spill encounter battle kind is wild")
		var battle_backdrop: TextureRect = world.get_node_or_null("UILayer/BattleBackdrop") as TextureRect
		var battle_opp_sprite: TextureRect = world.get_node_or_null("UILayer/BattleOppSprite") as TextureRect
		var battle_player_sprite: TextureRect = world.get_node_or_null("UILayer/BattlePlayerSprite") as TextureRect
		var battle_opp_hp: ProgressBar = world.get_node_or_null("UILayer/BattleOppHP") as ProgressBar
		var battle_player_hp: ProgressBar = world.get_node_or_null("UILayer/BattlePlayerHP") as ProgressBar
		var battle_action_icon0: TextureRect = world.get_node_or_null("UILayer/BattleActionIcon0") as TextureRect
		_check(battle_backdrop != null and battle_backdrop.visible, "Battle backdrop visual renders on battle start")
		_check(battle_opp_sprite != null and battle_opp_sprite.texture != null, "Opponent battle sprite texture renders")
		_check(battle_player_sprite != null and battle_player_sprite.texture != null, "Player battle sprite texture renders")
		_check(battle_opp_hp != null and battle_opp_hp.visible and battle_opp_hp.value > 0.0, "Opponent battle HP bar renders")
		_check(battle_player_hp != null and battle_player_hp.visible and battle_player_hp.value > 0.0, "Player battle HP bar renders")
		_check(battle_action_icon0 != null and battle_action_icon0.visible and battle_action_icon0.texture != null, "Battle action icon strip renders")
		_auto_finish_battle(world)
		_check(bool(world.get("dialog_active")), "Wild battle resolution opens result dialog")
		_drain_dialogs(world)

	# Healer should restore HP/energy
	var healer_npc: Dictionary = _find_npc(world, "healer")
	if not healer_npc.is_empty():
		var party: Dictionary = world.get("player_monsters")
		if not party.is_empty():
			var first_slot: int = int(party.keys()[0])
			var mon = party[first_slot]
			mon.health = 1.0
			mon.energy = 1.0
			world._interact_with_npc(healer_npc)
			_check(mon.health >= mon.get_single_stat("MAX_HEALTH") - 0.001, "Healer restores health")
			_check(mon.energy >= mon.get_single_stat("MAX_ENERGY") - 0.001, "Healer restores energy")
			_drain_dialogs(world)

	# Fuser + unfuser behavior (force a test-eligible monster)
	var fuser_npc: Dictionary = _find_npc(world, "fuser")
	var unfuser_npc: Dictionary = _find_npc(world, "unfuser")
	var party_for_fusion: Dictionary = world.get("player_monsters")
	if not fuser_npc.is_empty() and not unfuser_npc.is_empty() and not party_for_fusion.is_empty():
		var slot0: int = int(party_for_fusion.keys()[0])
		var aminomon_script = load("res://scripts/Aminomon.gd")
		party_for_fusion[slot0] = aminomon_script.new("alanine", 8, 0.0)
		world._interact_with_npc(fuser_npc)
		_check(str(party_for_fusion[slot0].name) == "alaninex2", "Fuser upgrades eligible monster")
		_drain_dialogs(world)
		world._interact_with_npc(unfuser_npc)
		_check(str(party_for_fusion[slot0].name) == "alanine", "Unfuser downgrades fused monster")
		_drain_dialogs(world)

	# Trainer interaction should run intro dialog -> battle modal -> victory -> defeated state
	var boss_npc: Dictionary = _find_npc(world, "boss")
	if not boss_npc.is_empty():
		var trainer_state: Dictionary = world.get("trainer_battle_state")
		var record_key: String = str(boss_npc.get("record_key", ""))
		if not record_key.is_empty():
			trainer_state[record_key] = false
		world._interact_with_npc(boss_npc)
		_check(bool(world.get("dialog_active")), "Trainer interaction opens intro dialog")
		_drain_dialogs(world, 50) # closes intro and starts battle via callback
		_check(bool(world.get("battle_active")), "Trainer intro dialog hands off to battle modal")
		var trainer_battle_context: Dictionary = world.get("battle_context")
		_check(str(trainer_battle_context.get("kind", "")) == "trainer", "Trainer battle kind is trainer")
		_auto_finish_battle(world)
		_check(bool(world.get("dialog_active")), "Trainer battle victory opens post-battle dialog")
		_drain_dialogs(world, 50)
		var trainer_state_after: Dictionary = world.get("trainer_battle_state")
		_check(bool(trainer_state_after.get(record_key, false)), "Trainer battle marks trainer defeated")

	# Utility dialogs should open without errors
	if world.has_method("_show_team_dialog"):
		world._show_team_dialog()
		_check(bool(world.get("dialog_active")), "Team dialog opens")
		_drain_dialogs(world, 50)
	if world.has_method("_show_storage_dialog"):
		world._show_storage_dialog()
		_check(bool(world.get("dialog_active")), "Storage dialog opens")
		_drain_dialogs(world, 50)
	if world.has_method("_show_pause_help_dialog"):
		world._show_pause_help_dialog()
		_check(bool(world.get("dialog_active")), "Pause/help dialog opens")
		_drain_dialogs(world, 50)

	# Pause menu should open and close cleanly
	if world.has_method("_open_pause_menu") and world.has_method("_close_pause_menu"):
		world._open_pause_menu()
		_check(bool(world.get("pause_menu_active")), "Pause menu opens")
		_check(bool(player.get("blocked")), "Pause menu blocks player movement")
		world._close_pause_menu()
		_check(not bool(world.get("pause_menu_active")), "Pause menu closes")
		_check(not bool(player.get("blocked")), "Pause menu unblocks player movement")

	# Peptide Dex should open and support cursor movement
	if world.has_method("_open_peptide_dex") and world.has_method("_close_peptide_dex"):
		world._open_peptide_dex()
		_check(bool(world.get("peptide_dex_active")), "Peptide Dex opens")
		var dex_entries: Array = world.get("peptide_dex_entries")
		var dex_cursor_before: int = int(world.get("peptide_dex_cursor"))
		if dex_entries.size() > 1 and world.has_method("_peptide_dex_move_cursor"):
			world._peptide_dex_move_cursor(1)
			var dex_cursor_after: int = int(world.get("peptide_dex_cursor"))
			_check(dex_cursor_after != dex_cursor_before, "Peptide Dex cursor moves")
		world._close_peptide_dex()
		_check(not bool(world.get("peptide_dex_active")), "Peptide Dex closes")

	# Pause -> Party Peptides -> Close should return to pause
	if world.has_method("_open_pause_menu") and world.has_method("_pause_menu_confirm") and world.has_method("_close_pause_menu"):
		world._open_pause_menu()
		world.set("pause_menu_cursor", 1) # Party Peptides
		world._pause_menu_confirm()
		_check(bool(world.get("team_menu_active")), "Pause Party Peptides option opens team menu")
		_check(not bool(world.get("pause_menu_active")), "Pause closes when opening team submenu")
		world._close_team_menu()
		_check(bool(world.get("pause_menu_active")), "Closing team submenu returns to pause menu")
		_check(not bool(world.get("team_menu_active")), "Team submenu closes cleanly")
		world._close_pause_menu()

	# Pause -> Peptide Dex -> Close should return to pause
	if world.has_method("_open_pause_menu") and world.has_method("_pause_menu_confirm") and world.has_method("_close_pause_menu"):
		world._open_pause_menu()
		world.set("pause_menu_cursor", 0) # Peptide Dex
		world._pause_menu_confirm()
		_check(bool(world.get("peptide_dex_active")), "Pause Peptide Dex option opens dex submenu")
		_check(not bool(world.get("pause_menu_active")), "Pause closes when opening dex submenu")
		world._close_peptide_dex()
		_check(bool(world.get("pause_menu_active")), "Closing dex submenu returns to pause menu")
		_check(not bool(world.get("peptide_dex_active")), "Dex submenu closes cleanly")
		world._close_pause_menu()

	# Manual battle menu flows should work (fight/switch/run + trainer run block)
	await _run_battle_menu_flow_tests(world)

	# Wait/basic-attack behaviors should work for player and enemy out-of-energy turns
	await _run_wait_and_basic_attack_tests(world)

	# Defeating a wild opponent should award XP during battle processing
	await _run_battle_xp_tests(world)

	# Wild battle catch flow: fail above threshold, succeed below threshold
	await _run_catch_flow_tests(world)

	# Party manager should support action menu, inspect, placeholder Give Item, and slot swapping.
	await _run_team_menu_tests(world)

	# Storage PC modal should support panel switching, sorted storage ordering, and transfers.
	await _run_storage_menu_tests(world)

	# Genre-parity additions: deterministic collection rolls, metadata persistence, status/accuracy/passive rules, and milestone loop scaffolding.
	await _run_collection_meta_tests(world)
	await _run_status_accuracy_and_passive_tests(world)
	await _run_progression_loop_tests(world)


func _run_collection_meta_tests(world: Node) -> void:
	if not world.has_method("_set_debug_rng_seed") or not world.has_method("_roll_rarity_variant"):
		_record_failure("World missing deterministic rarity-roll helpers")
		return

	world._set_debug_rng_seed(424242)
	var rarity_seq_a: Array = []
	for _i in range(10):
		rarity_seq_a.append(str(world._roll_rarity_variant()))
	world._set_debug_rng_seed(424242)
	var rarity_seq_b: Array = []
	for _j in range(10):
		rarity_seq_b.append(str(world._roll_rarity_variant()))
	_check(rarity_seq_a == rarity_seq_b, "Rarity rolls are deterministic when debug seed is fixed")

	if not world.has_method("_start_battle") or not world.has_method("_battle_attempt_catch"):
		_record_failure("World missing battle helpers for collection-meta smoke tests")
		return

	world._start_battle({
		"kind": "wild",
		"opponent_name": "alanine",
		"opponent_level": 4,
		"opponent_rarity_variant": "rare",
		"opponent_trait_id": "bold",
		"opponent_passive_id": "tenacity",
		"classroom": "labfight"
	})
	await process_frame
	var catch_ctx: Dictionary = world.get("battle_context")
	var catch_enemy = _battle_active_mon_from_ctx(catch_ctx, false)
	if catch_enemy == null:
		_record_failure("Collection-meta catch test could not access wild opponent")
		_end_test_battle_if_open(world)
		return

	catch_enemy.health = max(1.0, float(catch_enemy.get_single_stat("MAX_HEALTH")) * 0.3)
	world._battle_attempt_catch()
	_drain_battle_messages(world)
	_check(not bool(world.get("battle_active")), "Metadata catch ends battle")

	var party_after_catch: Dictionary = world.get("player_monsters")
	var storage_after_catch: Dictionary = world.get("player_storage")
	var caught_mon = _find_mon_with_metadata(party_after_catch, "alanine", "rare", "bold")
	if caught_mon == null:
		caught_mon = _find_mon_with_metadata(storage_after_catch, "alanine", "rare", "bold")
	_check(caught_mon != null, "Caught Aminomon preserves rarity + trait metadata")
	if caught_mon != null:
		_check(str(caught_mon.get("passive_id")).strip_edges().to_lower() == "tenacity", "Caught Aminomon preserves passive metadata")

	if bool(world.get("dialog_active")):
		_drain_dialogs(world)

	if not _can_write_user_save():
		_check(true, "Save/load metadata persistence check skipped (user:// write unavailable in this runtime)")
		return

	if world.has_method("save_game"):
		world.save_game()
		await process_frame
	if world.has_method("start_game"):
		world.start_game(false)
		await process_frame
		await physics_frame
		var party_after_reload: Dictionary = world.get("player_monsters")
		var storage_after_reload: Dictionary = world.get("player_storage")
		var persisted_mon = _find_mon_with_metadata(party_after_reload, "alanine", "rare", "bold")
		if persisted_mon == null:
			persisted_mon = _find_mon_with_metadata(storage_after_reload, "alanine", "rare", "bold")
		_check(persisted_mon != null, "Rarity + trait metadata persist through save/load")


func _run_status_accuracy_and_passive_tests(world: Node) -> void:
	if not world.has_method("_start_battle") or not world.has_method("_battle_apply_skill"):
		_record_failure("World missing battle helpers for status/passive smoke tests")
		return

	world._start_battle({
		"kind": "wild",
		"opponent_name": "glycine",
		"opponent_level": 5,
		"classroom": "labfight"
	})
	await process_frame
	var ctx: Dictionary = world.get("battle_context")
	var player_mon = _battle_active_mon_from_ctx(ctx, true)
	var enemy_mon = _battle_active_mon_from_ctx(ctx, false)
	if player_mon == null or enemy_mon == null:
		_record_failure("Status/passive tests could not access active battle mons")
		_end_test_battle_if_open(world)
		return

	player_mon.energy = player_mon.get_single_stat("MAX_ENERGY")
	enemy_mon.health = enemy_mon.get_single_stat("MAX_HEALTH")
	world._set_debug_rng_seed(2026)
	var burn_msgs_a: Array = world._battle_apply_skill("burn", true)
	var miss_a: bool = _messages_include(burn_msgs_a, "missed")

	player_mon.energy = player_mon.get_single_stat("MAX_ENERGY")
	enemy_mon.health = enemy_mon.get_single_stat("MAX_HEALTH")
	world._set_debug_rng_seed(2026)
	var burn_msgs_b: Array = world._battle_apply_skill("burn", true)
	var miss_b: bool = _messages_include(burn_msgs_b, "missed")
	_check(miss_a == miss_b, "Accuracy outcomes are deterministic with fixed seed")

	player_mon.passive_id = "none"
	enemy_mon.passive_id = "none"
	player_mon.set_status("burn", 2)
	enemy_mon.set_status("poison", 2)
	var hp_before_player_dot: float = float(player_mon.health)
	var hp_before_enemy_dot: float = float(enemy_mon.health)
	var dot_messages: Array = []
	world._battle_apply_end_turn_effects(dot_messages)
	_check(float(player_mon.health) < hp_before_player_dot, "Burn damage applies at end of turn")
	_check(float(enemy_mon.health) < hp_before_enemy_dot, "Poison damage applies at end of turn")
	if dot_messages.size() >= 2:
		_check(str(dot_messages[0]).find(str(player_mon.name)) != -1, "End-turn status order resolves player side first")

	var aminomon_script = load("res://scripts/Aminomon.gd")
	if aminomon_script == null:
		_record_failure("Could not load Aminomon.gd for passive hook tests")
	else:
		var switch_mon = aminomon_script.new("glycine", 6, 0.0)
		switch_mon.passive_id = "volt_aura"
		switch_mon.energy = 0.0
		var switch_messages: Array = []
		world._battle_apply_switch_in_passive(switch_mon, switch_messages)
		_check(float(switch_mon.energy) > 0.0, "on_switch_in passive restores energy")

	player_mon.energy = player_mon.get_single_stat("MAX_ENERGY")
	player_mon.health = player_mon.get_single_stat("MAX_HEALTH")
	enemy_mon.energy = enemy_mon.get_single_stat("MAX_ENERGY")
	enemy_mon.health = enemy_mon.get_single_stat("MAX_HEALTH")
	player_mon.clear_status_state()
	enemy_mon.clear_status_state()
	player_mon.passive_id = "none"
	enemy_mon.passive_id = "spike_shell"
	world._set_debug_rng_seed(33)
	var reflect_triggered: bool = false
	for _attempt in range(6):
		player_mon.health = player_mon.get_single_stat("MAX_HEALTH")
		player_mon.energy = player_mon.get_single_stat("MAX_ENERGY")
		var reflect_msgs: Array = world._battle_apply_skill("basic_attack", true)
		if _messages_include(reflect_msgs, "reflected"):
			reflect_triggered = true
			break
	_check(reflect_triggered, "on_hit_taken passive reflects damage")

	player_mon.passive_id = "tenacity"
	enemy_mon.passive_id = "none"
	player_mon.health = max(1.0, float(player_mon.get_single_stat("MAX_HEALTH")) * 0.3)
	player_mon.energy = player_mon.get_single_stat("MAX_ENERGY")
	world._set_debug_rng_seed(3)
	var low_hp_msgs: Array = world._battle_apply_skill("basic_attack", true)
	_check(_messages_include(low_hp_msgs, "boosted attack power"), "on_low_hp passive boosts damage output")

	player_mon.passive_id = "regenerator"
	player_mon.clear_status_state()
	enemy_mon.clear_status_state()
	player_mon.health = max(1.0, float(player_mon.get_single_stat("MAX_HEALTH")) * 0.5)
	var hp_before_regen: float = float(player_mon.health)
	var regen_messages: Array = []
	world._battle_apply_end_turn_effects(regen_messages)
	_check(float(player_mon.health) > hp_before_regen, "on_end_turn passive restores HP")

	_end_test_battle_if_open(world)


func _run_progression_loop_tests(world: Node) -> void:
	if not world.has_method("_load_map") or not world.has_method("_check_transitions"):
		_record_failure("World missing progression/map transition helpers")
		return

	world._load_map("firstlab", "world")
	await process_frame
	await physics_frame

	var player: Node = world.get("player")
	if player == null:
		_record_failure("Progression tests could not access player")
		return

	world.set("classroom_milestones", {})
	world.set("rematch_unlocked", false)
	if world.has_method("_refresh_objective_tracker"):
		world._refresh_objective_tracker()

	var gated_zone_info: Dictionary = _find_any_gated_transition(world)
	if gated_zone_info.is_empty():
		_record_failure("No transition to a gated map was found for progression tests")
	else:
		var required_badge: String = str(gated_zone_info.get("required", ""))
		var target_map: String = str(gated_zone_info.get("target", ""))
		var gate_rect: Rect2 = gated_zone_info.get("rect", Rect2())
		var source_map: String = str(gated_zone_info.get("source_map", ""))
		var source_spawn: String = str(gated_zone_info.get("source_spawn", "world"))
		world._load_map(source_map, source_spawn)
		await process_frame
		await physics_frame
		player.set("global_position", gate_rect.get_center())
		world.set("transition_cooldown_until_msec", 0)
		world._check_transitions()
		_check(str(world.get("current_map_name")) == source_map, "Map gate blocks %s before %s" % [target_map, required_badge])

		if world.has_method("_mark_milestone") and not required_badge.is_empty():
			world._mark_milestone(required_badge)
		world.set("transition_cooldown_until_msec", 0)
		world._check_transitions()
		_check(str(world.get("current_map_name")) == target_map, "%s unlocks transition to %s" % [required_badge, target_map])

	if world.has_method("_mark_milestone"):
		world._mark_milestone("lab_badge")
		world._mark_milestone("chem_badge")
		world._mark_milestone("bio_badge")
	_check(bool(world.get("rematch_unlocked")), "All classroom milestones unlock rematches")

	var objective_tracker: Dictionary = world.get("objective_tracker")
	_check(str(objective_tracker.get("title", "")) == "Post-Lab Loop", "Objective tracker advances to post-boss loop")


func _find_mon_with_metadata(source_dict: Dictionary, mon_name: String, rarity_variant: String, trait_id: String):
	for mon_variant in source_dict.values():
		var mon = mon_variant
		if mon == null:
			continue
		if str(mon.name).strip_edges().to_lower() != mon_name.strip_edges().to_lower():
			continue
		if str(mon.get("rarity_variant")).strip_edges().to_lower() != rarity_variant.strip_edges().to_lower():
			continue
		if str(mon.get("trait_id")).strip_edges().to_lower() != trait_id.strip_edges().to_lower():
			continue
		return mon
	return null


func _messages_include(messages: Array, needle: String) -> bool:
	var normalized_needle: String = needle.strip_edges().to_lower()
	for msg_variant in messages:
		var msg: String = str(msg_variant).to_lower()
		if msg.find(normalized_needle) != -1:
			return true
	return false


func _can_write_user_save() -> bool:
	var user_root: DirAccess = DirAccess.open("user://")
	if user_root == null:
		return false
	if user_root.make_dir_recursive("save") != OK:
		return false
	var probe_path: String = "user://save/.smoke_write_probe"
	var probe_file: FileAccess = FileAccess.open(probe_path, FileAccess.WRITE)
	if probe_file == null:
		return false
	probe_file.store_string("ok")
	probe_file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_path))
	return true


func _find_any_gated_transition(world: Node) -> Dictionary:
	var gated_targets := {
		"biochem2": "lab_badge",
		"biology2": "lab_badge"
	}
	var candidates: Array = [
		{"map": "firstlab", "spawn": "world"},
		{"map": "biochem1", "spawn": "world"},
		{"map": "biology1", "spawn": "world"},
		{"map": "biochem2", "spawn": "world"},
		{"map": "biology2", "spawn": "world"}
	]
	for candidate_variant in candidates:
		var candidate: Dictionary = candidate_variant
		var map_name: String = str(candidate.get("map", "firstlab"))
		var spawn_tag: String = str(candidate.get("spawn", "world"))
		world._load_map(map_name, spawn_tag)
		var transitions: Array = world.get("transition_zones")
		for zone_variant in transitions:
			var zone: Dictionary = zone_variant
			var target_map: String = str(zone.get("target", "")).strip_edges().to_lower()
			if not gated_targets.has(target_map):
				continue
			var result: Dictionary = zone.duplicate(true)
			result["source_map"] = map_name
			result["source_spawn"] = spawn_tag
			result["target"] = target_map
			result["required"] = str(gated_targets.get(target_map, ""))
			return result
	return {}


func _find_transition_zone_for_target(transition_zones: Array, target_map: String) -> Dictionary:
	for zone_variant in transition_zones:
		var zone: Dictionary = zone_variant
		if str(zone.get("target", "")).strip_edges().to_lower() == target_map.strip_edges().to_lower():
			return zone
	return {}


func _shape_overlaps(world: Node, player_collision: CollisionShape2D, at_position: Vector2) -> bool:
	if player_collision == null or player_collision.shape == null:
		return false

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = player_collision.shape
	params.transform = Transform2D.IDENTITY.translated(at_position)
	params.collide_with_bodies = true
	params.collide_with_areas = false

	var state: PhysicsDirectSpaceState2D = world.get_world_2d().direct_space_state
	var hits: Array = state.intersect_shape(params, 16)
	return not hits.is_empty()


func _find_npc(world: Node, npc_id: String) -> Dictionary:
	var npc_records: Array = world.get("npc_records")
	for npc_variant in npc_records:
		var npc: Dictionary = npc_variant
		if str(npc.get("id", "")) == npc_id:
			return npc
	return {}


func _drain_dialogs(world: Node, max_steps: int = 30) -> void:
	var steps: int = 0
	while bool(world.get("dialog_active")) and steps < max_steps:
		if world.has_method("_advance_dialog"):
			world._advance_dialog()
		else:
			break
		steps += 1
	if bool(world.get("dialog_active")):
		_record_failure("Dialog did not close within %d steps" % max_steps)


func _auto_finish_battle(world: Node, max_steps: int = 400) -> void:
	var steps: int = 0
	while bool(world.get("battle_active")) and steps < max_steps:
		var ctx: Dictionary = world.get("battle_context")
		var state: String = str(ctx.get("state", "main_menu"))
		if state == "message":
			if world.has_method("_battle_advance_message"):
				world._battle_advance_message()
			else:
				break
		else:
			if world.has_method("_resolve_battle_action"):
				world._resolve_battle_action("fight")
			else:
				break
		steps += 1
	if bool(world.get("battle_active")):
		_record_failure("Battle did not finish within %d steps" % max_steps)


func _drain_battle_messages(world: Node, max_steps: int = 80) -> void:
	var steps: int = 0
	while bool(world.get("battle_active")) and steps < max_steps:
		var ctx: Dictionary = world.get("battle_context")
		if str(ctx.get("state", "")) != "message":
			break
		if world.has_method("_battle_advance_message"):
			world._battle_advance_message()
		else:
			break
		steps += 1
	if bool(world.get("battle_active")):
		var remaining_ctx: Dictionary = world.get("battle_context")
		if str(remaining_ctx.get("state", "")) == "message":
			_record_failure("Battle messages did not drain within %d steps" % max_steps)


func _run_catch_flow_tests(world: Node) -> void:
	if not world.has_method("_start_battle"):
		_record_failure("World missing _start_battle for catch tests")
		return

	var aminomon_script = load("res://scripts/Aminomon.gd")
	if aminomon_script == null:
		_record_failure("Could not load Aminomon.gd for catch tests")
		return

	# Failed catch should keep battle active and return to main menu after messages.
	world._start_battle({
		"kind": "wild",
		"opponent_name": "alanine",
		"opponent_level": 3,
		"classroom": "labfight"
	})
	await process_frame
	var catch_ctx_fail: Dictionary = world.get("battle_context")
	var fail_options: Array = world._battle_current_menu_options() if world.has_method("_battle_current_menu_options") else []
	_check(fail_options.has("Catch"), "Wild main menu includes Catch option")
	var fail_enemy = _battle_active_mon_from_ctx(catch_ctx_fail, false)
	if fail_enemy != null:
		fail_enemy.health = fail_enemy.get_single_stat("MAX_HEALTH")
	if world.has_method("_battle_attempt_catch"):
		world._battle_attempt_catch()
	_drain_battle_messages(world)
	_check(bool(world.get("battle_active")), "Failed catch does not end battle")
	var ctx_after_fail: Dictionary = world.get("battle_context")
	_check(str(ctx_after_fail.get("state", "")) == "main_menu", "Failed catch returns to battle menu")
	_end_test_battle_if_open(world)

	# Successful catch should add to party when there is room.
	var party_before: Dictionary = world.get("player_monsters")
	var storage_before: Dictionary = world.get("player_storage")
	var party_count_before: int = party_before.size()
	var storage_count_before: int = storage_before.size()
	world._start_battle({
		"kind": "wild",
		"opponent_name": "glycine",
		"opponent_level": 2,
		"classroom": "labfight"
	})
	await process_frame
	var catch_ctx_success: Dictionary = world.get("battle_context")
	var success_enemy = _battle_active_mon_from_ctx(catch_ctx_success, false)
	if success_enemy != null:
		success_enemy.health = max(1.0, float(success_enemy.get_single_stat("MAX_HEALTH")) * 0.4)
	if world.has_method("_battle_attempt_catch"):
		world._battle_attempt_catch()
	_drain_battle_messages(world)
	_check(not bool(world.get("battle_active")), "Successful catch ends battle")
	_check(bool(world.get("dialog_active")), "Successful catch opens result dialog")
	var party_after_success: Dictionary = world.get("player_monsters")
	var storage_after_success: Dictionary = world.get("player_storage")
	_check(party_after_success.size() == party_count_before + 1, "Successful catch adds to party when room exists")
	_check(storage_after_success.size() == storage_count_before, "Successful catch does not use storage when party has room")
	_drain_dialogs(world)

	# Successful catch should route to storage when party is full.
	var party_ref: Dictionary = world.get("player_monsters")
	while party_ref.size() < 6:
		var filler_idx: int = _next_free_index(party_ref)
		party_ref[filler_idx] = aminomon_script.new("alanine", 5, 0.0)

	var party_full_count_before: int = party_ref.size()
	var storage_ref: Dictionary = world.get("player_storage")
	var storage_full_before: int = storage_ref.size()
	world._start_battle({
		"kind": "wild",
		"opponent_name": "serine",
		"opponent_level": 2,
		"classroom": "labfight"
	})
	await process_frame
	var catch_ctx_storage: Dictionary = world.get("battle_context")
	var storage_enemy = _battle_active_mon_from_ctx(catch_ctx_storage, false)
	if storage_enemy != null:
		storage_enemy.health = max(1.0, float(storage_enemy.get_single_stat("MAX_HEALTH")) * 0.4)
	if world.has_method("_battle_attempt_catch"):
		world._battle_attempt_catch()
	_drain_battle_messages(world)
	_check(not bool(world.get("battle_active")), "Successful catch with full party still ends battle")
	_check(bool(world.get("dialog_active")), "Storage-routed catch opens result dialog")
	_check(party_ref.size() == party_full_count_before, "Full-party catch does not increase party size")
	_check(storage_ref.size() == storage_full_before + 1, "Full-party catch adds caught mon to storage")
	_drain_dialogs(world)


func _run_battle_menu_flow_tests(world: Node) -> void:
	var aminomon_script = load("res://scripts/Aminomon.gd")
	if aminomon_script == null:
		_record_failure("Could not load Aminomon.gd for battle-menu tests")
		return

	var party_ref: Dictionary = world.get("player_monsters")
	while party_ref.size() < 2:
		party_ref[_next_free_index(party_ref)] = aminomon_script.new("alanine", 5, 0.0)

	# Wild battle: enter/exit attack menu, open switch menu, switch, then run.
	world._start_battle({
		"kind": "wild",
		"opponent_name": "alanine",
		"opponent_level": 2,
		"classroom": "labfight"
	})
	await process_frame
	var ctx0: Dictionary = world.get("battle_context")
	_check(str(ctx0.get("state", "")) == "main_menu", "Wild battle starts on main menu")

	world.set("battle_context", _set_ctx_cursor(world.get("battle_context"), 0))
	world._battle_confirm_current_selection()
	var ctx_attack: Dictionary = world.get("battle_context")
	_check(str(ctx_attack.get("state", "")) == "attack_menu", "Battle menu enters attack selection")
	world._battle_cancel_menu()
	var ctx_after_back: Dictionary = world.get("battle_context")
	_check(str(ctx_after_back.get("state", "")) == "main_menu", "Battle menu can back out of attack selection")

	var active_before_switch: int = int(ctx_after_back.get("active_player_index", -1))
	world.set("battle_context", _set_ctx_cursor(world.get("battle_context"), 1))
	world._battle_confirm_current_selection()
	var ctx_switch: Dictionary = world.get("battle_context")
	_check(str(ctx_switch.get("state", "")) == "switch_menu", "Battle menu enters switch selection")
	world.set("battle_context", _set_ctx_cursor(world.get("battle_context"), 0))
	world._battle_confirm_current_selection()
	_drain_battle_messages(world)
	var ctx_after_switch: Dictionary = world.get("battle_context")
	_check(int(ctx_after_switch.get("active_player_index", -1)) != active_before_switch, "Battle switch action changes active party member")

	var run_index: int = _find_menu_option_index(world.get("battle_context"), "Run", world)
	if run_index >= 0:
		world.set("battle_context", _set_ctx_cursor(world.get("battle_context"), run_index))
		world._battle_confirm_current_selection()
	else:
		world._resolve_battle_action("run")
	_check(not bool(world.get("battle_active")), "Wild run ends battle")
	_check(bool(world.get("dialog_active")), "Wild run opens result dialog")
	_drain_dialogs(world)

	# Trainer battle: running should be blocked.
	world._start_battle({
		"kind": "trainer",
		"npc_id": "smoketest_trainer",
		"classroom": "labfight",
		"monsters": {0: ["alanine", 2]},
		"npc": {"id": "smoketest_trainer", "record_key": "smoketest_trainer"}
	})
	await process_frame
	world._resolve_battle_action("run")
	_check(bool(world.get("battle_active")), "Trainer run attempt does not end battle")
	var trainer_ctx: Dictionary = world.get("battle_context")
	_check(str(trainer_ctx.get("kind", "")) == "trainer", "Trainer battle remains active after run attempt")
	_end_test_battle_if_open(world)


func _run_wait_and_basic_attack_tests(world: Node) -> void:
	if not world.has_method("_start_battle"):
		_record_failure("World missing _start_battle for wait/basic tests")
		return

	var aminomon_script = load("res://scripts/Aminomon.gd")
	if aminomon_script == null:
		_record_failure("Could not load Aminomon.gd for wait/basic tests")
		return

	var party_ref: Dictionary = world.get("player_monsters")
	if party_ref.is_empty():
		party_ref[0] = aminomon_script.new("alanine", 5, 0.0)

	# Player out-of-energy menu should expose Basic Attack + Wait.
	world._start_battle({
		"kind": "wild",
		"opponent_name": "alanine",
		"opponent_level": 4,
		"classroom": "labfight"
	})
	await process_frame
	var ctx_basic: Dictionary = world.get("battle_context")
	var player_basic = _battle_active_mon_from_ctx(ctx_basic, true)
	var enemy_basic = _battle_active_mon_from_ctx(ctx_basic, false)
	if player_basic == null or enemy_basic == null:
		_record_failure("Wait/basic tests could not access active battle mons")
		_end_test_battle_if_open(world)
		return

	player_basic.energy = 0.0
	enemy_basic.energy = 0.0
	world.set("battle_context", _set_ctx_cursor(world.get("battle_context"), 0)) # Fight
	world._battle_confirm_current_selection()
	var attack_options: Array = world._battle_current_menu_options() if world.has_method("_battle_current_menu_options") else []
	_check(attack_options.has("Basic Attack"), "Attack menu shows Basic Attack when player is out of energy")
	_check(attack_options.has("Wait"), "Attack menu shows Wait option")

	var basic_index: int = _find_menu_option_index(world.get("battle_context"), "Basic Attack", world)
	var enemy_hp_before: float = float(enemy_basic.health)
	if basic_index >= 0:
		world.set("battle_context", _set_ctx_cursor(world.get("battle_context"), basic_index))
		world._battle_confirm_current_selection()
		_drain_battle_messages(world)
		_check(float(enemy_basic.health) < enemy_hp_before, "Basic Attack deals damage without energy")
	else:
		_record_failure("Basic Attack option was not selectable")
	_end_test_battle_if_open(world)

	# Wait should restore energy and still hand turn to enemy, including enemy basic-attack fallback.
	world._start_battle({
		"kind": "wild",
		"opponent_name": "glycine",
		"opponent_level": 4,
		"classroom": "labfight"
	})
	await process_frame
	var ctx_wait: Dictionary = world.get("battle_context")
	var player_wait = _battle_active_mon_from_ctx(ctx_wait, true)
	var enemy_wait = _battle_active_mon_from_ctx(ctx_wait, false)
	if player_wait == null or enemy_wait == null:
		_record_failure("Wait test could not access active battle mons")
		_end_test_battle_if_open(world)
		return

	player_wait.energy = 0.0
	enemy_wait.energy = 0.0
	var energy_before_wait: float = float(player_wait.energy)
	var hp_before_wait: float = float(player_wait.health)
	world.set("battle_context", _set_ctx_cursor(world.get("battle_context"), 0)) # Fight
	world._battle_confirm_current_selection()
	var wait_index: int = _find_menu_option_index(world.get("battle_context"), "Wait", world)
	if wait_index >= 0:
		world.set("battle_context", _set_ctx_cursor(world.get("battle_context"), wait_index))
		world._battle_confirm_current_selection()
		_drain_battle_messages(world)
		_check(float(player_wait.energy) > energy_before_wait, "Wait restores player energy")
		_check(float(player_wait.health) < hp_before_wait, "Enemy still takes a turn after Wait (basic fallback)")
	else:
		_record_failure("Wait option was not selectable")
	_end_test_battle_if_open(world)


func _run_battle_xp_tests(world: Node) -> void:
	if not world.has_method("_start_battle"):
		_record_failure("World missing _start_battle for battle-XP tests")
		return

	world._start_battle({
		"kind": "wild",
		"opponent_name": "alanine",
		"opponent_level": 1,
		"classroom": "labfight"
	})
	await process_frame

	var ctx: Dictionary = world.get("battle_context")
	var player_mon = _battle_active_mon_from_ctx(ctx, true)
	var enemy_mon = _battle_active_mon_from_ctx(ctx, false)
	if player_mon == null or enemy_mon == null:
		_record_failure("Battle-XP test could not access active battle mons")
		_end_test_battle_if_open(world)
		return

	var chosen_skill: String = _first_damaging_skill(world)
	if chosen_skill.is_empty():
		_record_failure("Battle-XP test could not find a damaging usable skill")
		_end_test_battle_if_open(world)
		return

	var xp_before: float = float(player_mon.xp)
	var level_before: int = int(player_mon.level)
	enemy_mon.health = 1.0
	var defeated: bool = false
	for _attempt in range(6):
		if not bool(world.get("battle_active")):
			defeated = true
			break
		if world.has_method("_set_debug_rng_seed"):
			world._set_debug_rng_seed(6000 + _attempt)
		if world.has_method("_battle_execute_player_skill"):
			world._battle_execute_player_skill(chosen_skill)
		var battle_effect: TextureRect = world.get_node_or_null("UILayer/BattleEffect") as TextureRect
		_check(battle_effect != null and battle_effect.texture != null, "Using a skill renders attack effect overlay")
		_drain_battle_messages(world)
		if not bool(world.get("battle_active")):
			defeated = true
			break
		var ongoing_ctx: Dictionary = world.get("battle_context")
		var ongoing_enemy = _battle_active_mon_from_ctx(ongoing_ctx, false)
		if ongoing_enemy != null:
			ongoing_enemy.health = 1.0
	_check(defeated, "XP test defeats a wild opponent within retry budget")
	_check(not bool(world.get("battle_active")), "Defeating wild opponent ends battle in XP test")
	var xp_after: float = float(player_mon.xp)
	var level_after: int = int(player_mon.level)
	_check(level_after > level_before or abs(xp_after - xp_before) > 0.001, "Defeating opponent awards XP to active party member")
	if bool(world.get("dialog_active")):
		_drain_dialogs(world)


func _run_storage_menu_tests(world: Node) -> void:
	var storage_npc: Dictionary = _find_npc(world, "storage")
	if storage_npc.is_empty():
		_record_failure("Could not find storage NPC for storage-menu tests")
		return

	var aminomon_script = load("res://scripts/Aminomon.gd")
	if aminomon_script == null:
		_record_failure("Could not load Aminomon.gd for storage-menu tests")
		return

	var party_ref: Dictionary = world.get("player_monsters")
	var storage_ref: Dictionary = world.get("player_storage")
	if party_ref.size() < 2:
		while party_ref.size() < 2:
			party_ref[_next_free_index(party_ref)] = aminomon_script.new("alanine", 5, 0.0)
	if storage_ref.is_empty():
		storage_ref[_next_free_index(storage_ref)] = aminomon_script.new("glycine", 5, 0.0)

	world._interact_with_npc(storage_npc)
	await process_frame
	_check(bool(world.get("storage_menu_active")), "Storage NPC opens storage modal")
	_check(str(world.get("storage_menu_side")) == "party", "Storage opens focused on party panel")

	if world.has_method("_storage_menu_set_side"):
		world._storage_menu_set_side("storage")
		_check(str(world.get("storage_menu_side")) == "storage", "Right input targets storage panel")
		world._storage_menu_set_side("party")
		_check(str(world.get("storage_menu_side")) == "party", "Left input targets party panel")

	var party_before: int = party_ref.size()
	var storage_before: int = storage_ref.size()
	world.set("storage_menu_side", "party")
	world.set("storage_menu_party_cursor", 0)
	if world.has_method("_storage_menu_confirm"):
		world._storage_menu_confirm()
	_check(party_ref.size() == party_before - 1, "Storage menu can deposit party Aminomon")
	_check(storage_ref.size() == storage_before + 1, "Storage menu deposit increases storage count")

	var party_after_deposit: int = party_ref.size()
	var storage_after_deposit: int = storage_ref.size()
	world.set("storage_menu_side", "storage")
	world.set("storage_menu_storage_cursor", 0)
	if world.has_method("_storage_menu_confirm"):
		world._storage_menu_confirm()
	_check(party_ref.size() == party_after_deposit + 1, "Storage menu can withdraw stored Aminomon")
	_check(storage_ref.size() == storage_after_deposit - 1, "Storage menu withdraw decreases storage count")

	# Min party size rule: cannot deposit when only 1 Aminomon remains.
	party_ref.clear()
	party_ref[0] = aminomon_script.new("alanine", 5, 0.0)
	var storage_count_before_min_rule: int = storage_ref.size()
	world.set("storage_menu_side", "party")
	world.set("storage_menu_party_cursor", 0)
	if world.has_method("_storage_menu_confirm"):
		world._storage_menu_confirm()
	_check(party_ref.size() == 1, "Storage menu enforces minimum party size of 1")
	_check(storage_ref.size() == storage_count_before_min_rule, "Min party rule blocks deposit")

	# Max party size rule: cannot withdraw when party is full.
	while party_ref.size() < 6:
		party_ref[_next_free_index(party_ref)] = aminomon_script.new("glycine", 4, 0.0)
	if storage_ref.is_empty():
		storage_ref[_next_free_index(storage_ref)] = aminomon_script.new("serine", 3, 0.0)
	var storage_count_before_max_rule: int = storage_ref.size()
	world.set("storage_menu_side", "storage")
	world.set("storage_menu_storage_cursor", 0)
	if world.has_method("_storage_menu_confirm"):
		world._storage_menu_confirm()
	_check(party_ref.size() == 6, "Storage menu enforces maximum party size of 6")
	_check(storage_ref.size() == storage_count_before_max_rule, "Max party rule blocks withdraw")

	# Storage ordering contract: alphabetical, then level asc, then slot index asc.
	party_ref.clear()
	party_ref[0] = aminomon_script.new("alanine", 5, 0.0)
	storage_ref.clear()
	storage_ref[9] = aminomon_script.new("glycine", 4, 0.0)
	storage_ref[4] = aminomon_script.new("alanine", 7, 0.0)
	storage_ref[2] = aminomon_script.new("alanine", 3, 0.0)
	storage_ref[8] = aminomon_script.new("alanine", 3, 0.0)
	storage_ref[1] = aminomon_script.new("serine", 2, 0.0)
	var sorted_keys: Array = []
	if world.has_method("_storage_sorted_keys"):
		sorted_keys = world._storage_sorted_keys(storage_ref)
	_check(sorted_keys.size() == 5, "Storage sorting helper returns all storage keys")
	if sorted_keys.size() == 5:
		_check(int(sorted_keys[0]) == 2, "Storage sort orders alphabetically with level tie-break (first alanine Lv3 slot)")
		_check(int(sorted_keys[1]) == 8, "Storage sort uses slot-index tie-break for same name/level")
		_check(int(sorted_keys[2]) == 4, "Storage sort places higher-level same-name entries later")

	# Transfer mapping should use displayed sorted order (cursor 0 withdraws first sorted entry).
	var expected_first_mon = storage_ref.get(2, null)
	var expected_first_id: int = expected_first_mon.get_instance_id() if expected_first_mon != null else -1
	world.set("storage_menu_side", "storage")
	world.set("storage_menu_storage_cursor", 0)
	if world.has_method("_storage_menu_confirm"):
		world._storage_menu_confirm()
	var withdrew_expected_mon: bool = false
	for party_mon_variant in party_ref.values():
		var party_mon = party_mon_variant
		if party_mon != null and party_mon.get_instance_id() == expected_first_id:
			withdrew_expected_mon = true
			break
	_check(withdrew_expected_mon, "Withdraw uses sorted storage cursor mapping")

	if world.has_method("_close_storage_menu"):
		world._close_storage_menu()
	_check(not bool(world.get("storage_menu_active")), "Storage modal closes cleanly")


func _run_team_menu_tests(world: Node) -> void:
	if not world.has_method("_open_team_menu"):
		_record_failure("World missing _open_team_menu for party-manager tests")
		return

	var aminomon_script = load("res://scripts/Aminomon.gd")
	if aminomon_script == null:
		_record_failure("Could not load Aminomon.gd for party-manager tests")
		return

	var party_ref: Dictionary = world.get("player_monsters")
	while party_ref.size() < 2:
		party_ref[_next_free_index(party_ref)] = aminomon_script.new("alanine", 5, 0.0)

	var keys_sorted: Array = party_ref.keys()
	keys_sorted.sort()
	var key_a: int = int(keys_sorted[0])
	var key_b: int = int(keys_sorted[1])
	var mon_a = party_ref.get(key_a)
	var mon_b = party_ref.get(key_b)
	var id_a: int = mon_a.get_instance_id() if mon_a != null else -1
	var id_b: int = mon_b.get_instance_id() if mon_b != null else -1

	world._open_team_menu()
	await process_frame
	_check(bool(world.get("team_menu_active")), "Party manager opens")
	_check(str(world.get("team_menu_state")) == "grid", "Party manager opens in grid state")
	_check(not bool(world.get("peptide_dex_active")), "Party manager does not open Peptide Dex")

	world.set("team_menu_cursor", 0)
	if world.has_method("_team_menu_confirm"):
		world._team_menu_confirm()
	_check(str(world.get("team_menu_state")) == "action_menu", "Selecting a slot opens party action menu")

	# Inspect action opens dedicated inspect state and backs out to action menu.
	world.set("team_menu_action_cursor", 1) # Inspect
	if world.has_method("_team_menu_confirm"):
		world._team_menu_confirm()
	_check(str(world.get("team_menu_state")) == "inspect", "Inspect action opens inspect window")
	if world.has_method("_team_menu_back"):
		world._team_menu_back()
	_check(str(world.get("team_menu_state")) == "action_menu", "Inspect back returns to action menu")

	# Give Item is currently a placeholder and should not mutate party order/content.
	var pre_give_ids: Array = []
	for key_variant in keys_sorted:
		var mon_before = party_ref.get(int(key_variant), null)
		pre_give_ids.append(mon_before.get_instance_id() if mon_before != null else -1)
	world.set("team_menu_action_cursor", 2) # Give Item
	if world.has_method("_team_menu_confirm"):
		world._team_menu_confirm()
	_check(str(world.get("team_menu_state")) == "action_menu", "Give Item placeholder keeps action menu open")
	var post_give_ids: Array = []
	for key_variant in keys_sorted:
		var mon_after = party_ref.get(int(key_variant), null)
		post_give_ids.append(mon_after.get_instance_id() if mon_after != null else -1)
	_check(pre_give_ids == post_give_ids, "Give Item placeholder does not mutate party")

	# Move action should pick source then swap when destination is confirmed.
	world.set("team_menu_action_cursor", 0) # Move
	if world.has_method("_team_menu_confirm"):
		world._team_menu_confirm()
	_check(str(world.get("team_menu_state")) == "move_pick", "Move action enters move-pick state")

	world.set("team_menu_cursor", 1)
	if world.has_method("_team_menu_confirm"):
		world._team_menu_confirm()
	_check(str(world.get("team_menu_state")) == "grid", "Completing move returns to grid state")
	var mon_a_after = party_ref.get(key_a)
	var mon_b_after = party_ref.get(key_b)
	var id_a_after: int = mon_a_after.get_instance_id() if mon_a_after != null else -1
	var id_b_after: int = mon_b_after.get_instance_id() if mon_b_after != null else -1
	_check(id_a_after == id_b and id_b_after == id_a, "Party manager swaps two party rows")

	if world.has_method("_close_team_menu"):
		world._close_team_menu()
	_check(not bool(world.get("team_menu_active")), "Party manager closes cleanly")


func _end_test_battle_if_open(world: Node) -> void:
	if not bool(world.get("battle_active")):
		return
	if world.has_method("_end_battle"):
		world._end_battle("run", false)
	if bool(world.get("dialog_active")):
		_drain_dialogs(world)


func _battle_active_mon_from_ctx(ctx: Dictionary, player_side: bool):
	var party: Dictionary = ctx.get("player_party", {}) if player_side else ctx.get("opponent_party", {})
	var key_name: String = "active_player_index" if player_side else "active_opponent_index"
	var idx: int = int(ctx.get(key_name, -1))
	return party.get(idx, null)


func _next_free_index(target: Dictionary) -> int:
	var idx: int = 0
	while target.has(idx):
		idx += 1
	return idx


func _set_ctx_cursor(ctx: Dictionary, cursor: int) -> Dictionary:
	var next_ctx: Dictionary = ctx
	next_ctx["cursor"] = cursor
	return next_ctx


func _find_menu_option_index(ctx: Dictionary, label: String, world: Node) -> int:
	if not world.has_method("_battle_current_menu_options"):
		return -1
	var options: Array = world._battle_current_menu_options()
	for i in range(options.size()):
		if str(options[i]).to_lower() == label.to_lower():
			return i
	return -1


func _first_damaging_skill(world: Node) -> String:
	if not world.has_method("_battle_usable_skills_for_active_player"):
		return ""
	var skills: Array = world._battle_usable_skills_for_active_player()
	for skill_variant in skills:
		var skill_name: String = str(skill_variant)
		if skill_name.to_lower() != "heal":
			return skill_name
	return ""


func _check(condition: bool, message: String) -> void:
	_checks_run += 1
	if condition:
		print("[PASS] %s" % message)
	else:
		_record_failure(message)


func _record_failure(message: String) -> void:
	print("[FAIL] %s" % message)
	_failures.append(message)


func _approx(a: float, b: float, epsilon: float) -> bool:
	return abs(a - b) <= epsilon


func _finish() -> void:
	print("[SmokeTest] Checks run: %d" % _checks_run)
	if _failures.is_empty():
		print("[SmokeTest] SUCCESS")
		quit(0)
		return

	print("[SmokeTest] FAILURES: %d" % _failures.size())
	for failure in _failures:
		print(" - %s" % str(failure))
	quit(1)
