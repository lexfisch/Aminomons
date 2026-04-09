extends Node2D

const Settings := preload("res://scripts/Settings.gd")
const BigData := preload("res://scripts/BigBigData.gd")
const AminomonRes := preload("res://scripts/Aminomon.gd")
const BattleStateModule := preload("res://scripts/BattleState.gd")

const TEAM_SAVE_FILE: String = "player_aminos.csv"
const STORAGE_SAVE_FILE: String = "player_storage.csv"
const WORLD_STATE_FILE: String = "world_state.json"
const MAPS_DIR: String = "res://data/mapfile"
const MAP_EXTENSION: String = ".tmx"
const TILED_FLIP_H: int = 0x80000000
const TILED_FLIP_V: int = 0x40000000
const TILED_FLIP_D: int = 0x20000000
const TILED_GID_MASK: int = 0x1FFFFFFF
const INDOOR_TILESET_FIRST_GID: int = 1
const INDOOR_TILESET_COLUMNS: int = 10
const INDOOR_TILESET_IMAGE: String = "res://images/tilesets/indoor.png"
const LIQUID_TILESET_FIRST_GID: int = 91
const LIQUID_TILESET_COLUMNS: int = 16
const LIQUID_TILESET_TILE_SIZE: Vector2i = Vector2i(32, 32)
const LIQUID_TILESET_IMAGE: String = "res://images/tilesets/spriteSheet_tiledLiquids_32x32.png"
const CHARACTER_SHEETS_DIR: String = "res://images/characters"
const CHARACTER_SHEET_COLS: int = 4
const CHARACTER_SHEET_ROWS: int = 4
const BATTLE_BACKGROUNDS_DIR: String = "res://images/backgrounds"
const MONSTER_BATTLE_SHEETS_DIR: String = "res://images/monsAminos"
const MONSTER_BATTLE_SHEET_COLS: int = 4
const MONSTER_BATTLE_SHEET_ROWS: int = 2
const BATTLE_MONSTER_IDLE_FRAME_MS: int = 180
const ATTACK_SHEETS_DIR: String = "res://images/attacks"
const ATTACK_SHEET_COLS: int = 4
const ATTACK_EFFECT_FRAME_MS: int = 90
const UI_ICONS_DIR: String = "res://images/ui"
const AMINO_ICONS_DIR: String = "res://images/iconsAminos"
const PAUSE_MENU_OPTIONS := ["Peptide Dex", "Party Peptides", "Save", "Quit"]
const BASIC_ATTACK_SKILL: String = "basic_attack"
const WAIT_ENERGY_RECOVERY_RATIO: float = 0.10
const UI_LIST_LINE_HEIGHT: float = 24.0
const UI_ICON_TEXT_X_OFFSET: float = 6.0
const MENU_ICON_SIZE: Vector2 = Vector2(24, 24)
const MENU_PORTRAIT_SIZE: Vector2 = Vector2(176, 176)
const MENU_LARGE_ICON_SIZE: Vector2 = Vector2(56, 56)
const TEAM_GRID_ORIGIN: Vector2 = Vector2(210.0, 208.0)
const TEAM_GRID_SPACING: Vector2 = Vector2(214.0, 112.0)
const STORAGE_PARTY_ORIGIN: Vector2 = Vector2(168.0, 232.0)
const STORAGE_STORAGE_ORIGIN: Vector2 = Vector2(712.0, 196.0)
const STORAGE_PARTY_COLUMNS: int = 2
const STORAGE_STORAGE_COLUMNS: int = 3
const STORAGE_STORAGE_VISIBLE_SLOTS: int = 12
const TEAM_MENU_STATE_GRID: String = "grid"
const TEAM_MENU_STATE_ACTION_MENU: String = "action_menu"
const TEAM_MENU_STATE_MOVE_PICK: String = "move_pick"
const TEAM_MENU_STATE_INSPECT: String = "inspect"
const TEAM_MENU_ACTION_OPTIONS := ["Move", "Inspect", "Give Item", "Cancel"]
const TEAM_MENU_GRID_COLS: int = 2
const TEAM_MENU_GRID_ROWS: int = 3
const TEAM_MENU_GRID_SLOTS: int = TEAM_MENU_GRID_COLS * TEAM_MENU_GRID_ROWS
const INTERACTION_NOTICE_ICON: String = "res://images/ui/notice.png"
const TRANSITION_FADE_DURATION: float = 0.24
const UI_PANEL_COLOR_MAIN: Color = Color(0.05, 0.08, 0.11, 0.94)
const UI_PANEL_COLOR_DEX_BASE: Color = Color(0.08, 0.1, 0.16, 0.95)
const UI_TEXT_COLOR_PRIMARY: Color = Color(0.93, 0.96, 1.0, 1.0)
const UI_TEXT_COLOR_SUBTLE: Color = Color(0.76, 0.83, 0.94, 1.0)
const MENU_TRANSITION_DURATION: float = 0.14
const MAP_MILESTONE_REQUIREMENTS := {
	"biochem2": "lab_badge",
	"biology2": "lab_badge"
}
const TRAINER_MILESTONE_REWARDS := {
	"boss": {"milestone": "lab_badge", "points": 220},
	"bc5": {"milestone": "chem_badge", "points": 150},
	"b5": {"milestone": "bio_badge", "points": 150}
}
const TRAINER_STANDARD_REWARD_POINTS: int = 45
const CATCH_REWARD_POINTS: int = 12
const POST_BOSS_WILD_LEVEL_BONUS: int = 2

@onready var player := $Player
@onready var fusion_cinematic := $FusionCinematic

@export var debug_overlays_enabled: bool = false

var game_active: bool = false
var new_game: bool = false

# Player party and storage mirror Main.Game.player_monsters / player_storage
var player_monsters: Dictionary = {}
var player_storage: Dictionary = {}

# Lightweight world-state port
var current_map_name: String = "firstlab"
var current_spawn_tag: String = "world"
var current_map_pixel_size: Vector2 = Vector2(640, 1280)
var transition_zones: Array = []
var npc_records: Array = []
var chemical_spill_zones: Array = []
var trainer_battle_state: Dictionary = {}
var classroom_milestones: Dictionary = {}
var currency_points: int = 0
var objective_tracker: Dictionary = {}
var dex_species_caught: Dictionary = {}
var dex_variant_caught: Dictionary = {}
var dex_rewards_claimed: Dictionary = {}
var rematch_unlocked: bool = false
var transition_cooldown_until_msec: int = 0
var interaction_cooldown_until_msec: int = 0
var wild_encounter_cooldown_until_msec: int = 0
var pending_spill_index: int = -1
var pending_spill_encounter_at_msec: int = 0
var dialog_active: bool = false
var dialog_lines: Array = []
var dialog_index: int = 0
var dialog_on_close: Callable = Callable()
var team_menu_active: bool = false
var team_menu_cursor: int = 0
var team_menu_move_source_row: int = -1
var team_menu_action_cursor: int = 0
var team_menu_state: String = TEAM_MENU_STATE_GRID
var team_menu_return_to_pause: bool = false
var storage_menu_active: bool = false
var storage_menu_side: String = "party"
var storage_menu_party_cursor: int = 0
var storage_menu_storage_cursor: int = 0
var pause_menu_active: bool = false
var pause_menu_cursor: int = 0
var peptide_dex_active: bool = false
var peptide_dex_cursor: int = 0
var peptide_dex_entries: Array = []
var peptide_dex_return_to_pause: bool = false
var battle_active: bool = false
var battle_context: Dictionary = {}
var fusion_sequence_active: bool = false
var fusion_sequence_queue: Array = []
var fusion_sequence_result_lines: Array = []
var transition_fade_timer: float = 0.0

var map_root: Node2D
var map_floor_root: Node2D
var map_actor_root: Node2D
var map_collision_root: Node2D
var map_debug_root: Node2D
var map_marker_root: Node2D
var interaction_notice_sprite: Sprite2D
var indoor_tiles_texture: Texture2D
var liquid_tiles_texture: Texture2D
var character_frame_cache: Dictionary = {}
var battle_background_cache: Dictionary = {}
var battle_monster_frame_cache: Dictionary = {}
var battle_attack_frame_cache: Dictionary = {}
var ui_icon_cache: Dictionary = {}
var aminomon_icon_cache: Dictionary = {}
var fallback_mon_texture: Texture2D
var ui_runtime_root: Control
var _battle_state := BattleStateModule.new()
var _battle_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _debug_rng_seed: int = 0
var _menu_open_state: Dictionary = {}
var _objective_label: Label


func _ready() -> void:
	randomize()
	_battle_rng.randomize()
	_ensure_map_roots()
	_validate_ui_layer()
	_ensure_runtime_ui_nodes()
	_ensure_objective_label()
	_set_fade_overlay_alpha(0.0)
	_ensure_interaction_notice_sprite()
	if fusion_cinematic and fusion_cinematic.has_signal("sequence_finished"):
		fusion_cinematic.connect("sequence_finished", Callable(self, "_on_fusion_sequence_finished"))

	if player:
		player.global_position = Vector2(640, 360)

	# Load the first map immediately so parsing/runtime issues surface early.
	_load_map(current_map_name, current_spawn_tag)
	_set_status("Enter/Space = new game, L = load. F5 saves in world.")


func start_game(is_new_game: bool) -> void:
	new_game = is_new_game
	game_active = true
	if _debug_rng_seed > 0:
		_battle_rng.seed = int(_debug_rng_seed)
	else:
		_battle_rng.randomize()
	transition_cooldown_until_msec = 0
	pause_menu_active = false
	peptide_dex_active = false
	peptide_dex_return_to_pause = false
	team_menu_active = false
	team_menu_return_to_pause = false
	storage_menu_active = false
	dialog_active = false
	battle_active = false
	fusion_sequence_active = false
	fusion_sequence_queue.clear()
	fusion_sequence_result_lines.clear()
	transition_fade_timer = 0.0
	_set_fade_overlay_alpha(0.0)
	_render_pause_menu()
	_render_peptide_dex()
	if new_game:
		trainer_battle_state.clear()
		classroom_milestones = {}
		currency_points = 0
		objective_tracker = {}
		dex_species_caught = {}
		dex_variant_caught = {}
		dex_rewards_claimed = {}
		rematch_unlocked = false
		current_map_name = "firstlab"
		current_spawn_tag = "world"

	var loaded_team: bool = _create_team()
	var loaded_storage_count: int = _create_storage()
	if not new_game:
		_load_world_state()

	_load_map(current_map_name, current_spawn_tag)
	_register_collection_from_party_and_storage()
	_refresh_objective_tracker()
	_update_objective_label()

	if loaded_team:
		_set_status("Loaded save on %s: %d party, %d storage, %d pts. F5 saves." % [current_map_name, player_monsters.size(), loaded_storage_count, currency_points])
	else:
		_set_status("Started new game on %s: %d party, %d storage, %d pts. F5 saves." % [current_map_name, player_monsters.size(), loaded_storage_count, currency_points])


func update_world(delta: float) -> void:
	if not game_active:
		return

	_update_objective_label()
	_handle_input(delta)
	_update_transition_fade(delta)
	if battle_active:
		_update_battle_effect()
		_update_interaction_hint()
		return
	if fusion_sequence_active:
		_update_interaction_hint()
		return
	if pause_menu_active:
		_update_interaction_hint()
		return
	if peptide_dex_active:
		_update_interaction_hint()
		return
	if team_menu_active:
		_update_interaction_hint()
		return
	if storage_menu_active:
		_update_interaction_hint()
		return
	if dialog_active:
		_update_interaction_hint()
		return
	_check_transitions()
	_check_chemical_spills()
	_update_interaction_hint()


func _handle_input(delta: float) -> void:
	if player and player.has_method("handle_input"):
		player.handle_input(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not game_active:
		return

	if event is InputEventKey:
		var key_event: InputEventKey = event
		if key_event.pressed and not key_event.echo:
			if fusion_sequence_active:
				if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_E:
					if fusion_cinematic and fusion_cinematic.has_method("skip"):
						fusion_cinematic.skip()
				return
			if pause_menu_active:
				if key_event.keycode == KEY_UP:
					_pause_menu_move_cursor(-1)
					return
				if key_event.keycode == KEY_DOWN:
					_pause_menu_move_cursor(1)
					return
				if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_E:
					_pause_menu_confirm()
					return
				if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
					_close_pause_menu()
					return
				return
			if peptide_dex_active:
				if key_event.keycode == KEY_UP:
					_peptide_dex_move_cursor(-1)
					return
				if key_event.keycode == KEY_DOWN:
					_peptide_dex_move_cursor(1)
					return
				if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P or key_event.keycode == KEY_D:
					_close_peptide_dex()
					return
				return
			if team_menu_active:
				if key_event.keycode == KEY_UP:
					_team_menu_move_cursor(-1)
					return
				if key_event.keycode == KEY_DOWN:
					_team_menu_move_cursor(1)
					return
				if key_event.keycode == KEY_LEFT:
					_team_menu_move_cursor(-1, true)
					return
				if key_event.keycode == KEY_RIGHT:
					_team_menu_move_cursor(1, true)
					return
				if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_E:
					_team_menu_confirm()
					return
				if key_event.keycode == KEY_ESCAPE:
					_team_menu_back()
					return
				return
			if storage_menu_active:
				if key_event.keycode == KEY_UP:
					_storage_menu_move_cursor(-1)
					return
				if key_event.keycode == KEY_DOWN:
					_storage_menu_move_cursor(1)
					return
				if key_event.keycode == KEY_LEFT:
					_storage_menu_set_side("party")
					return
				if key_event.keycode == KEY_RIGHT:
					_storage_menu_set_side("storage")
					return
				if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_E:
					_storage_menu_confirm()
					return
				if key_event.keycode == KEY_ESCAPE:
					_close_storage_menu()
					return
				return
			if battle_active:
				if key_event.keycode == KEY_UP:
					_battle_move_cursor(-1)
					return
				if key_event.keycode == KEY_DOWN:
					_battle_move_cursor(1)
					return
				if key_event.keycode == KEY_F or key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER:
					_battle_confirm_current_selection()
					return
				if key_event.keycode == KEY_R:
					_resolve_battle_action("run")
					return
				if key_event.keycode == KEY_ESCAPE:
					_battle_cancel_menu()
					return
				if key_event.keycode == KEY_S:
					if str(battle_context.get("state", "main_menu")) == "main_menu":
						_battle_set_state("switch_menu")
					return
			if dialog_active:
				if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_E:
					_advance_dialog()
					return
				if key_event.keycode == KEY_ESCAPE:
					_close_dialog()
					return
			if key_event.keycode == KEY_P:
				_open_pause_menu()
				return
			if key_event.keycode == KEY_D:
				_open_peptide_dex()
				return
			if key_event.keycode == KEY_H:
				_show_pause_help_dialog()
				return
			if key_event.keycode == KEY_T:
				_open_team_menu()
				return
			if key_event.keycode == KEY_S:
				_open_storage_menu()
				return
			if key_event.keycode == KEY_F5:
				save_game()
				return
			if key_event.keycode == KEY_SPACE or key_event.keycode == KEY_E:
				_try_interact()
				return


func _create_team() -> bool:
	player_monsters.clear()

	var starters: Array = []
	for name in BigData.PEPTIDE_DEX.keys():
		var info: Dictionary = BigData.PEPTIDE_DEX[name]
		if int(info.get("id", 0)) % 3 == 1:
			starters.append(name)

	if not new_game:
		var transfer: Array = _load_saved_mons(TEAM_SAVE_FILE)
		if not transfer.is_empty():
			for row_variant in transfer:
				var row: PackedStringArray = row_variant
				if row.size() < 4:
					continue
				var index_value: int = int(str(row[0]).strip_edges())
				var amino_name: String = str(row[1]).strip_edges()
				var level_value: int = int(str(row[2]).strip_edges())
				var xp_amount: float = float(str(row[3]).strip_edges())
				var rarity_variant: String = str(row[4]).strip_edges() if row.size() >= 5 else "normal"
				var trait_id: String = str(row[5]).strip_edges() if row.size() >= 6 else "neutral"
				var status_type: String = str(row[6]).strip_edges() if row.size() >= 7 else "none"
				var status_turns: int = int(str(row[7]).strip_edges()) if row.size() >= 8 and not str(row[7]).strip_edges().is_empty() else 0
				var passive_id: String = str(row[8]).strip_edges() if row.size() >= 9 else ""
				var mon = AminomonRes.new(amino_name, level_value, xp_amount)
				if mon != null and mon.has_method("set_mon_metadata"):
					mon.set_mon_metadata(rarity_variant, trait_id, {"type": status_type, "turns": status_turns}, passive_id)
				player_monsters[index_value] = mon
			return true

	var count: int = randi_range(2, 4)
	for i in range(count):
		var chosen: String = _pick_random_starter(starters)
		var starter = AminomonRes.new(chosen, 5, 0)
		if starter != null and starter.has_method("set_mon_metadata"):
			starter.set_mon_metadata(_roll_rarity_variant(), _roll_trait_id(), {"type": "none", "turns": 0}, "")
		player_monsters[i] = starter
	return false


func _create_storage() -> int:
	player_storage.clear()
	var transfer_box: Array = _load_saved_mons(STORAGE_SAVE_FILE)

	for row_variant in transfer_box:
		var row: PackedStringArray = row_variant
		if row.size() < 4:
			continue
		var index_value: int = int(str(row[0]).strip_edges())
		var amino_name: String = str(row[1]).strip_edges()
		var level_value: int = int(str(row[2]).strip_edges())
		var xp_amount: float = float(str(row[3]).strip_edges())
		var rarity_variant: String = str(row[4]).strip_edges() if row.size() >= 5 else "normal"
		var trait_id: String = str(row[5]).strip_edges() if row.size() >= 6 else "neutral"
		var status_type: String = str(row[6]).strip_edges() if row.size() >= 7 else "none"
		var status_turns: int = int(str(row[7]).strip_edges()) if row.size() >= 8 and not str(row[7]).strip_edges().is_empty() else 0
		var passive_id: String = str(row[8]).strip_edges() if row.size() >= 9 else ""
		var mon = AminomonRes.new(amino_name, level_value, xp_amount)
		if mon != null and mon.has_method("set_mon_metadata"):
			mon.set_mon_metadata(rarity_variant, trait_id, {"type": status_type, "turns": status_turns}, passive_id)
		player_storage[index_value] = mon

	return player_storage.size()


func save_game() -> void:
	var save_dir: String = _save_directory_path()
	var mk_err: int = DirAccess.make_dir_recursive_absolute(save_dir)
	if mk_err != OK:
		push_error("Failed to create save directory: %s (err=%d)" % [save_dir, mk_err])
		_set_status("Save failed: could not create %s" % save_dir)
		return

	var team_saved: bool = _write_saved_mons(TEAM_SAVE_FILE, player_monsters)
	var storage_saved: bool = _write_saved_mons(STORAGE_SAVE_FILE, player_storage)
	var world_saved: bool = _write_world_state()

	if team_saved and storage_saved and world_saved:
		_set_status("Saved %d party and %d storage on %s" % [player_monsters.size(), player_storage.size(), current_map_name])
	else:
		_set_status("Save failed (see debugger output).")


func _pick_random_starter(starters: Array) -> String:
	if not starters.is_empty():
		return str(starters.pick_random())
	if BigData.PEPTIDE_DEX.has("alanine"):
		return "alanine"
	var keys: Array = BigData.PEPTIDE_DEX.keys()
	if keys.is_empty():
		return "alanine"
	return str(keys[0])


func _set_debug_rng_seed(seed_value: int) -> void:
	_debug_rng_seed = max(0, seed_value)
	if _debug_rng_seed > 0:
		_battle_rng.seed = int(_debug_rng_seed)
	else:
		_battle_rng.randomize()


func _battle_randf() -> float:
	return _battle_rng.randf()


func _battle_randi_range(min_value: int, max_value: int) -> int:
	return _battle_rng.randi_range(min_value, max_value)


func _roll_rarity_variant() -> String:
	var weights: Dictionary = {}
	var total_weight: int = 0
	for variant_key in BigData.RARITY_VARIANTS.keys():
		var rarity_key: String = str(variant_key)
		var variant_data: Dictionary = BigData.RARITY_VARIANTS.get(rarity_key, {})
		var weight_value: int = max(0, int(variant_data.get("roll_weight", 0)))
		if rarity_key != "normal" and _has_milestone("lab_badge"):
			weight_value *= 2
		if weight_value <= 0:
			continue
		weights[rarity_key] = weight_value
		total_weight += weight_value
	if total_weight <= 0:
		return "normal"
	var roll: int = _battle_randi_range(1, total_weight)
	var running: int = 0
	for rarity_key_variant in weights.keys():
		var rarity_key: String = str(rarity_key_variant)
		running += int(weights[rarity_key])
		if roll <= running:
			return rarity_key
	return "normal"


func _roll_trait_id() -> String:
	var roll: int = _battle_randi_range(1, 100)
	if roll <= 40:
		return "neutral"
	var trait_keys: Array = BigData.TRAIT_DATA.keys()
	trait_keys.sort()
	var non_neutral: Array = []
	for trait_variant in trait_keys:
		var trait_key: String = str(trait_variant)
		if trait_key == "neutral":
			continue
		non_neutral.append(trait_key)
	if non_neutral.is_empty():
		return "neutral"
	return str(non_neutral[_battle_randi_range(0, non_neutral.size() - 1)])


func _rarity_badge(rarity_variant: String) -> String:
	var rarity_key: String = rarity_variant.strip_edges().to_lower()
	if not BigData.RARITY_VARIANTS.has(rarity_key):
		rarity_key = "normal"
	var rarity_data: Dictionary = BigData.RARITY_VARIANTS.get(rarity_key, {})
	return str(rarity_data.get("badge", "NRM"))


func _trait_display_name(trait_value: String) -> String:
	var trait_key: String = trait_value.strip_edges().to_lower()
	var trait_data: Dictionary = BigData.TRAIT_DATA.get(trait_key, BigData.TRAIT_DATA.get("neutral", {}))
	return str(trait_data.get("display_name", "Neutral"))


func _format_mon_badges(mon) -> String:
	if mon == null:
		return "[NRM|Neutral]"
	var rarity_value: String = str(mon.get("rarity_variant")).strip_edges().to_lower()
	if rarity_value.is_empty():
		rarity_value = "normal"
	var trait_value: String = str(mon.get("trait_id")).strip_edges().to_lower()
	if trait_value.is_empty():
		trait_value = "neutral"
	return "[%s|%s]" % [_rarity_badge(rarity_value), _trait_display_name(trait_value)]


func _status_display(mon) -> String:
	if mon == null:
		return "None"
	if mon.has_method("status_type"):
		var status_type: String = str(mon.status_type()).strip_edges().to_lower()
		if status_type == "none" or status_type.is_empty():
			return "None"
		var status_label: String = str(BigData.STATUS_RULES.get(status_type, {}).get("display_name", status_type.capitalize()))
		var turns_left: int = 0
		if mon.has_method("status_turns_remaining"):
			turns_left = int(mon.status_turns_remaining())
		return "%s(%d)" % [status_label, turns_left]
	return "None"


func _register_mon_collection(mon) -> void:
	if mon == null:
		return
	var mon_name: String = str(mon.name).strip_edges().to_lower()
	if mon_name.is_empty():
		return
	dex_species_caught[mon_name] = true
	var rarity_value: String = str(mon.get("rarity_variant")).strip_edges().to_lower()
	if rarity_value.is_empty():
		rarity_value = "normal"
	var variant_key: String = "%s|%s" % [mon_name, rarity_value]
	dex_variant_caught[variant_key] = true


func _register_collection_from_party_and_storage() -> void:
	for mon_variant in player_monsters.values():
		_register_mon_collection(mon_variant)
	for mon_variant in player_storage.values():
		_register_mon_collection(mon_variant)
	_check_and_grant_dex_rewards([])


func _check_and_grant_dex_rewards(messages: Array) -> void:
	var species_count: int = dex_species_caught.size()
	var variant_count: int = dex_variant_caught.size()
	var species_thresholds: Dictionary = BigData.DEX_REWARD_THRESHOLDS.get("species", {})
	for threshold_variant in species_thresholds.keys():
		var threshold: int = int(threshold_variant)
		var reward_key: String = "species_%d" % threshold
		if species_count < threshold or bool(dex_rewards_claimed.get(reward_key, false)):
			continue
		var reward_amount: int = int(species_thresholds.get(threshold_variant, 0))
		dex_rewards_claimed[reward_key] = true
		_add_currency_points(reward_amount)
		messages.append("Dex Reward: %d species captured (+%d pts)." % [threshold, reward_amount])
	var variant_thresholds: Dictionary = BigData.DEX_REWARD_THRESHOLDS.get("variants", {})
	for threshold_variant in variant_thresholds.keys():
		var threshold: int = int(threshold_variant)
		var reward_key: String = "variant_%d" % threshold
		if variant_count < threshold or bool(dex_rewards_claimed.get(reward_key, false)):
			continue
		var reward_amount: int = int(variant_thresholds.get(threshold_variant, 0))
		dex_rewards_claimed[reward_key] = true
		_add_currency_points(reward_amount)
		messages.append("Dex Reward: %d rarity forms registered (+%d pts)." % [threshold, reward_amount])


func _add_currency_points(amount: int) -> void:
	currency_points = max(0, currency_points + amount)
	_update_objective_label()


func _has_milestone(milestone_key: String) -> bool:
	return bool(classroom_milestones.get(milestone_key, false))


func _mark_milestone(milestone_key: String) -> void:
	if milestone_key.strip_edges().is_empty():
		return
	classroom_milestones[milestone_key] = true
	if _has_milestone("lab_badge") and _has_milestone("chem_badge") and _has_milestone("bio_badge"):
		rematch_unlocked = true
	_refresh_objective_tracker()
	_update_objective_label()


func _refresh_objective_tracker() -> void:
	if not _has_milestone("lab_badge"):
		objective_tracker = {
			"title": "Lab Starter Goal",
			"next": "Defeat the boss in firstlab.",
			"progress": "Milestones: 0 / 3"
		}
	elif not _has_milestone("chem_badge"):
		objective_tracker = {
			"title": "Chemistry Track",
			"next": "Defeat trainer bc5 in biochem2.",
			"progress": "Milestones: 1 / 3"
		}
	elif not _has_milestone("bio_badge"):
		objective_tracker = {
			"title": "Biology Track",
			"next": "Defeat trainer b5 in biology2.",
			"progress": "Milestones: 2 / 3"
		}
	else:
		objective_tracker = {
			"title": "Post-Lab Loop",
			"next": "Hunt rarity forms and farm rematches.",
			"progress": "Milestones: 3 / 3"
		}


func _objective_text() -> String:
	var title: String = str(objective_tracker.get("title", "Objective"))
	var next_text: String = str(objective_tracker.get("next", ""))
	var progress_text: String = str(objective_tracker.get("progress", ""))
	return "%s | %s | %s | Pts %d" % [title, next_text, progress_text, currency_points]


func _ensure_objective_label() -> void:
	var ui_layer: CanvasLayer = get_node_or_null("UILayer") as CanvasLayer
	if ui_layer == null:
		return
	_objective_label = ui_layer.get_node_or_null("Objective") as Label
	if _objective_label == null:
		_objective_label = Label.new()
		_objective_label.name = "Objective"
		_objective_label.offset_left = 16.0
		_objective_label.offset_top = 74.0
		_objective_label.offset_right = 1260.0
		_objective_label.offset_bottom = 94.0
		_objective_label.theme_override_font_sizes.font_size = 12
		_objective_label.modulate = UI_TEXT_COLOR_SUBTLE
		ui_layer.add_child(_objective_label)


func _update_objective_label() -> void:
	if _objective_label == null or not is_instance_valid(_objective_label):
		_ensure_objective_label()
	if _objective_label == null or not is_instance_valid(_objective_label):
		return
	_objective_label.text = _objective_text()


func _animate_overlay_open(box: ColorRect, label: CanvasItem) -> void:
	if box == null:
		return
	var key: String = str(box.get_instance_id())
	if bool(_menu_open_state.get(key, false)):
		return
	_menu_open_state[key] = true
	box.modulate = Color(1.0, 1.0, 1.0, 0.0)
	var base_y: float = box.offset_top
	box.offset_top = base_y - 8.0
	box.offset_bottom -= 8.0
	var tween_box: Tween = create_tween()
	tween_box.set_ease(Tween.EASE_OUT)
	tween_box.set_trans(Tween.TRANS_CUBIC)
	tween_box.tween_property(box, "modulate:a", 1.0, MENU_TRANSITION_DURATION)
	tween_box.parallel().tween_property(box, "offset_top", base_y, MENU_TRANSITION_DURATION)
	tween_box.parallel().tween_property(box, "offset_bottom", box.offset_bottom + 8.0, MENU_TRANSITION_DURATION)
	if label != null:
		label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		var tween_label: Tween = create_tween()
		tween_label.set_ease(Tween.EASE_OUT)
		tween_label.set_trans(Tween.TRANS_CUBIC)
		tween_label.tween_property(label, "modulate:a", 1.0, MENU_TRANSITION_DURATION + 0.04)


func _mark_overlay_closed(box: ColorRect) -> void:
	if box == null:
		return
	var key: String = str(box.get_instance_id())
	_menu_open_state[key] = false


func _save_directory_path() -> String:
	return "user://save"


func _save_file_path(file_name: String) -> String:
	return _save_directory_path().path_join(file_name)


func _world_state_file_path() -> String:
	return _save_file_path(WORLD_STATE_FILE)


func _map_file_path(map_name: String) -> String:
	return "%s/%s%s" % [MAPS_DIR, map_name, MAP_EXTENSION]


func _load_saved_mons(file_name: String) -> Array:
	var file_path: String = _save_file_path(file_name)
	var saved_aminos: Array = []

	if not FileAccess.file_exists(file_path):
		return saved_aminos

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for read: %s" % file_path)
		return saved_aminos

	if not file.eof_reached():
		file.get_csv_line()

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 4:
			continue
		if row[0].strip_edges().is_empty():
			continue
		saved_aminos.append(row)

	return saved_aminos


func _write_saved_mons(file_name: String, mons: Dictionary) -> bool:
	var file_path: String = _save_file_path(file_name)
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for write: %s" % file_path)
		return false

	file.store_csv_line(PackedStringArray([
		"index", "name", "level", "xp_amount", "rarity_variant", "trait_id", "status_type", "status_turns", "passive_id"
	]))

	var indexes: Array = mons.keys()
	indexes.sort()

	for index_variant in indexes:
		var index_value: int = int(index_variant)
		var monster = mons.get(index_value)
		if monster == null:
			continue
		var status_type: String = "none"
		var status_turns: int = 0
		if monster.has_method("status_type"):
			status_type = str(monster.status_type())
		if monster.has_method("status_turns_remaining"):
			status_turns = int(monster.status_turns_remaining())
		var rarity_variant_value: String = str(monster.get("rarity_variant"))
		if rarity_variant_value.is_empty():
			rarity_variant_value = "normal"
		var trait_id_value: String = str(monster.get("trait_id"))
		if trait_id_value.is_empty():
			trait_id_value = "neutral"
		var passive_id_value: String = str(monster.get("passive_id"))
		file.store_csv_line(PackedStringArray([
			str(index_value),
			str(monster.name),
			str(monster.level),
			str(monster.xp),
			rarity_variant_value,
			trait_id_value,
			status_type,
			str(status_turns),
			passive_id_value,
		]))

	return true


func _write_world_state() -> bool:
	var file_path: String = _world_state_file_path()
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open world state file for write: %s" % file_path)
		return false

	var payload: Dictionary = {
		"current_map_name": current_map_name,
		"current_spawn_tag": current_spawn_tag,
		"trainer_battle_state": trainer_battle_state,
		"classroom_milestones": classroom_milestones,
		"currency_points": currency_points,
		"objective_tracker": objective_tracker,
		"dex_species_caught": dex_species_caught,
		"dex_variant_caught": dex_variant_caught,
		"dex_rewards_claimed": dex_rewards_claimed,
		"rematch_unlocked": rematch_unlocked,
	}
	file.store_string(JSON.stringify(payload))
	return true


func _load_world_state() -> void:
	var file_path: String = _world_state_file_path()
	if not FileAccess.file_exists(file_path):
		return

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open world state file for read: %s" % file_path)
		return

	var raw_text: String = file.get_as_text()
	if raw_text.strip_edges().is_empty():
		return

	var parsed = JSON.parse_string(raw_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var data: Dictionary = parsed
	current_map_name = str(data.get("current_map_name", current_map_name))
	current_spawn_tag = str(data.get("current_spawn_tag", current_spawn_tag))
	if current_map_name.is_empty():
		current_map_name = "firstlab"
	if current_spawn_tag.is_empty():
		current_spawn_tag = "world"

	var loaded_trainer_state = data.get("trainer_battle_state", {})
	if typeof(loaded_trainer_state) == TYPE_DICTIONARY:
		trainer_battle_state = loaded_trainer_state
	var loaded_milestones = data.get("classroom_milestones", {})
	if typeof(loaded_milestones) == TYPE_DICTIONARY:
		classroom_milestones = loaded_milestones
	currency_points = int(data.get("currency_points", 0))
	var loaded_objective = data.get("objective_tracker", {})
	if typeof(loaded_objective) == TYPE_DICTIONARY:
		objective_tracker = loaded_objective
	var loaded_species = data.get("dex_species_caught", {})
	if typeof(loaded_species) == TYPE_DICTIONARY:
		dex_species_caught = loaded_species
	var loaded_variants = data.get("dex_variant_caught", {})
	if typeof(loaded_variants) == TYPE_DICTIONARY:
		dex_variant_caught = loaded_variants
	var loaded_rewards = data.get("dex_rewards_claimed", {})
	if typeof(loaded_rewards) == TYPE_DICTIONARY:
		dex_rewards_claimed = loaded_rewards
	rematch_unlocked = bool(data.get("rematch_unlocked", false))


func _ensure_map_roots() -> void:
	if map_root != null:
		return

	map_root = Node2D.new()
	map_root.name = "MapRuntime"
	add_child(map_root)
	move_child(map_root, 0)

	map_floor_root = Node2D.new()
	map_floor_root.name = "Floor"
	map_root.add_child(map_floor_root)

	map_actor_root = Node2D.new()
	map_actor_root.name = "Actors"
	map_actor_root.y_sort_enabled = true
	map_root.add_child(map_actor_root)

	if player != null and player.get_parent() != map_actor_root:
		var original_pos: Vector2 = player.global_position
		var original_parent: Node = player.get_parent()
		if original_parent != null:
			original_parent.remove_child(player)
		map_actor_root.add_child(player)
		player.global_position = original_pos

	map_collision_root = Node2D.new()
	map_collision_root.name = "Collisions"
	map_root.add_child(map_collision_root)

	map_debug_root = Node2D.new()
	map_debug_root.name = "Debug"
	map_debug_root.visible = debug_overlays_enabled
	map_root.add_child(map_debug_root)

	map_marker_root = Node2D.new()
	map_marker_root.name = "Markers"
	map_root.add_child(map_marker_root)


func _clear_map_runtime() -> void:
	transition_zones.clear()
	npc_records.clear()
	chemical_spill_zones.clear()
	pending_spill_index = -1
	pending_spill_encounter_at_msec = 0

	if map_floor_root:
		for child in map_floor_root.get_children():
			child.queue_free()
	if map_actor_root:
		for child in map_actor_root.get_children():
			if child == player:
				continue
			child.queue_free()
		interaction_notice_sprite = null
	if map_collision_root:
		for child in map_collision_root.get_children():
			child.queue_free()
	if map_debug_root:
		for child in map_debug_root.get_children():
			child.queue_free()
	if map_marker_root:
		for child in map_marker_root.get_children():
			child.queue_free()


func _load_map(map_name: String, spawn_tag: String) -> bool:
	var parsed_map: Dictionary = _parse_tmx_map(map_name)
	if parsed_map.is_empty():
		_set_status("Failed to load map: %s" % map_name)
		return false
	if not _validate_parsed_map(parsed_map):
		_set_status("Failed validation for map: %s" % map_name)
		return false

	current_map_name = map_name
	current_spawn_tag = spawn_tag
	current_map_pixel_size = Vector2(
		float(parsed_map.get("width", 10)) * float(parsed_map.get("tilewidth", 64)),
		float(parsed_map.get("height", 10)) * float(parsed_map.get("tileheight", 64))
	)

	_clear_map_runtime()
	_build_floor_visual(parsed_map)
	_build_collision_bodies(parsed_map)
	_build_transition_debug(parsed_map)
	_build_npc_runtime(parsed_map)
	_build_chemical_spill_runtime(parsed_map)
	if debug_overlays_enabled:
		_build_marker_debug(parsed_map)
	_place_player_from_map(parsed_map, spawn_tag)
	_update_camera_limits()
	_update_map_labels()
	return true


func _parse_tmx_map(map_name: String) -> Dictionary:
	var file_path: String = _map_file_path(map_name)
	if not FileAccess.file_exists(file_path):
		push_error("TMX file not found: %s" % file_path)
		return {}

	var parser := XMLParser.new()
	var open_err: int = parser.open(file_path)
	if open_err != OK:
		push_error("Failed to open TMX: %s (err=%d)" % [file_path, open_err])
		return {}

	var result: Dictionary = {
		"name": map_name,
		"width": 0,
		"height": 0,
		"tilewidth": 64,
		"tileheight": 64,
		"layers": {},
		"objectgroups": {},
	}

	var current_layer_name: String = ""
	var current_layer_is_csv: bool = false
	var current_layer_text: String = ""
	var current_objectgroup_name: String = ""
	var current_object: Dictionary = {}

	while true:
		var read_err: int = parser.read()
		if read_err == ERR_FILE_EOF:
			break
		if read_err != OK:
			push_error("TMX parse error in %s (err=%d)" % [file_path, read_err])
			return {}

		var node_type: int = parser.get_node_type()

		if node_type == XMLParser.NODE_ELEMENT:
			var node_name: String = parser.get_node_name()
			var attrs: Dictionary = _xml_attrs(parser)

			match node_name:
				"map":
					result["width"] = int(attrs.get("width", 0))
					result["height"] = int(attrs.get("height", 0))
					result["tilewidth"] = int(attrs.get("tilewidth", 64))
					result["tileheight"] = int(attrs.get("tileheight", 64))
				"layer":
					current_layer_name = str(attrs.get("name", ""))
					current_layer_is_csv = false
					current_layer_text = ""
				"data":
					if not current_layer_name.is_empty():
						current_layer_is_csv = str(attrs.get("encoding", "")) == "csv"
						current_layer_text = ""
				"objectgroup":
					current_objectgroup_name = str(attrs.get("name", ""))
					if not current_objectgroup_name.is_empty():
						var groups: Dictionary = result["objectgroups"]
						if not groups.has(current_objectgroup_name):
							groups[current_objectgroup_name] = []
				"object":
					current_object = {
						"id": int(attrs.get("id", 0)),
						"name": str(attrs.get("name", "")),
						"x": float(attrs.get("x", 0.0)),
						"y": float(attrs.get("y", 0.0)),
						"width": float(attrs.get("width", 0.0)),
						"height": float(attrs.get("height", 0.0)),
						"gid": int(attrs.get("gid", 0)),
						"properties": {},
					}
					if int(current_object.get("gid", 0)) != 0:
						if float(current_object.get("width", 0.0)) <= 0.0:
							current_object["width"] = float(result.get("tilewidth", 64))
						if float(current_object.get("height", 0.0)) <= 0.0:
							current_object["height"] = float(result.get("tileheight", 64))
					if not current_objectgroup_name.is_empty():
						var groups_for_object: Dictionary = result["objectgroups"]
						var group_objects: Array = groups_for_object.get(current_objectgroup_name, [])
						group_objects.append(current_object)
						groups_for_object[current_objectgroup_name] = group_objects
				"property":
					if not current_object.is_empty():
						var property_name: String = str(attrs.get("name", ""))
						var property_type: String = str(attrs.get("type", "string"))
						var property_value_raw: String = str(attrs.get("value", ""))
						if not property_name.is_empty():
							var props: Dictionary = current_object.get("properties", {})
							props[property_name] = _parse_tmx_property_value(property_type, property_value_raw)
							current_object["properties"] = props

		elif node_type == XMLParser.NODE_TEXT:
			if current_layer_is_csv:
				current_layer_text += parser.get_node_data()

		elif node_type == XMLParser.NODE_ELEMENT_END:
			var end_name: String = parser.get_node_name()
			if end_name == "data":
				if current_layer_is_csv and not current_layer_name.is_empty():
					var layers: Dictionary = result["layers"]
					layers[current_layer_name] = current_layer_text
				current_layer_is_csv = false
				current_layer_text = ""
			elif end_name == "layer":
				current_layer_name = ""
				current_layer_is_csv = false
				current_layer_text = ""
			elif end_name == "objectgroup":
				current_objectgroup_name = ""
			elif end_name == "object":
				current_object = {}

	return result


func _parse_tmx_property_value(property_type: String, raw_value: String):
	var normalized: String = property_type.strip_edges().to_lower()
	match normalized:
		"bool", "boolean":
			var lower: String = raw_value.strip_edges().to_lower()
			return lower == "true" or lower == "1" or lower == "yes"
		"int", "integer":
			return int(raw_value)
		"float":
			return float(raw_value)
		_:
			return raw_value


func _validate_parsed_map(parsed_map: Dictionary) -> bool:
	var map_name: String = str(parsed_map.get("name", "unknown"))
	var map_w: int = int(parsed_map.get("width", 0))
	var map_h: int = int(parsed_map.get("height", 0))
	var tile_w: int = int(parsed_map.get("tilewidth", 0))
	var tile_h: int = int(parsed_map.get("tileheight", 0))
	if map_w <= 0 or map_h <= 0 or tile_w <= 0 or tile_h <= 0:
		push_error("Invalid map dimensions in %s" % map_name)
		return false

	var layers: Dictionary = parsed_map.get("layers", {})
	if not layers.has("Terrain"):
		push_warning("%s missing Terrain layer" % map_name)
	if not layers.has("Terrain Top"):
		push_warning("%s missing Terrain Top layer" % map_name)
	for layer_name in ["Terrain", "Terrain Top"]:
		if not layers.has(layer_name):
			continue
		var gids: Array = _parse_csv_gids(str(layers.get(layer_name, "")))
		if gids.size() < map_w * map_h:
			push_warning("%s layer %s has %d gids; expected at least %d" % [map_name, layer_name, gids.size(), map_w * map_h])

	var objectgroups: Dictionary = parsed_map.get("objectgroups", {})
	for required_group in ["Collisions", "Transition", "GameObjects", "ChemicalSpills"]:
		if not objectgroups.has(required_group):
			push_warning("%s missing %s object group" % [map_name, required_group])

	var player_spawn_found: bool = false
	var game_objects: Array = objectgroups.get("GameObjects", [])
	for obj_variant in game_objects:
		var obj: Dictionary = obj_variant
		if str(obj.get("name", "")) == "Player":
			player_spawn_found = true
			break
	if not player_spawn_found:
		push_error("%s missing Player spawn in GameObjects" % map_name)
		return false

	var transitions: Array = objectgroups.get("Transition", [])
	for transition_variant in transitions:
		var transition: Dictionary = transition_variant
		var props: Dictionary = transition.get("properties", {})
		if str(props.get("target", "")).strip_edges().is_empty():
			push_warning("%s has Transition object without target property" % map_name)

	var spills: Array = objectgroups.get("ChemicalSpills", [])
	for spill_variant in spills:
		var spill: Dictionary = spill_variant
		var props_spill: Dictionary = spill.get("properties", {})
		if str(props_spill.get("aminos", "")).strip_edges().is_empty():
			push_warning("%s has ChemicalSpill with empty aminos list" % map_name)

	return true


func _xml_attrs(parser: XMLParser) -> Dictionary:
	var attrs: Dictionary = {}
	var count: int = parser.get_attribute_count()
	for i in range(count):
		attrs[parser.get_attribute_name(i)] = parser.get_attribute_value(i)
	return attrs


func _build_floor_visual(parsed_map: Dictionary) -> void:
	var width_px: float = float(parsed_map.get("width", 10)) * float(parsed_map.get("tilewidth", 64))
	var height_px: float = float(parsed_map.get("height", 10)) * float(parsed_map.get("tileheight", 64))

	var floor_poly := Polygon2D.new()
	floor_poly.name = "FloorFill"
	floor_poly.color = Color(0.14, 0.16, 0.19, 1.0)
	floor_poly.polygon = PackedVector2Array([
		Vector2(0, 0),
		Vector2(width_px, 0),
		Vector2(width_px, height_px),
		Vector2(0, height_px),
	])
	map_floor_root.add_child(floor_poly)

	var border := Line2D.new()
	border.name = "Border"
	border.width = 4.0
	border.default_color = Color(0.78, 0.84, 0.92, 0.65)
	border.closed = true
	border.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(width_px, 0),
		Vector2(width_px, height_px),
		Vector2(0, height_px),
	])
	map_floor_root.add_child(border)

	_build_terrain_layer(parsed_map, "Terrain")
	_build_terrain_layer(parsed_map, "Terrain Top")


func _build_terrain_layer(parsed_map: Dictionary, layer_name: String) -> void:
	var layers: Dictionary = parsed_map.get("layers", {})
	if not layers.has(layer_name):
		return

	var csv_text: String = str(layers.get(layer_name, ""))
	var gids: Array = _parse_csv_gids(csv_text)
	if gids.is_empty():
		return

	var tile_texture: Texture2D = _get_indoor_tiles_texture()
	if tile_texture == null:
		return

	var map_width: int = int(parsed_map.get("width", 0))
	var map_height: int = int(parsed_map.get("height", 0))
	var tile_width: int = int(parsed_map.get("tilewidth", 64))
	var tile_height: int = int(parsed_map.get("tileheight", 64))
	var index: int = 0

	var layer_root := Node2D.new()
	layer_root.name = layer_name
	map_floor_root.add_child(layer_root)

	for row in range(map_height):
		for col in range(map_width):
			if index >= gids.size():
				return
			var raw_gid: int = int(gids[index])
			index += 1
			if raw_gid == 0:
				continue

			var gid: int = raw_gid & TILED_GID_MASK
			if gid < INDOOR_TILESET_FIRST_GID:
				continue
			if gid >= 91:
				continue

			var local_id: int = gid - INDOOR_TILESET_FIRST_GID
			var atlas_col: int = local_id % INDOOR_TILESET_COLUMNS
			var atlas_row: int = int(local_id / INDOOR_TILESET_COLUMNS)

			var atlas := AtlasTexture.new()
			atlas.atlas = tile_texture
			atlas.region = Rect2(atlas_col * tile_width, atlas_row * tile_height, tile_width, tile_height)

			var sprite := Sprite2D.new()
			sprite.texture = atlas
			sprite.centered = false
			sprite.position = Vector2(col * tile_width, row * tile_height)
			sprite.flip_h = (raw_gid & TILED_FLIP_H) != 0
			sprite.flip_v = (raw_gid & TILED_FLIP_V) != 0
			layer_root.add_child(sprite)


func _parse_csv_gids(csv_text: String) -> Array:
	var result: Array = []
	for line in csv_text.split("\n", false):
		var trimmed_line: String = line.strip_edges()
		if trimmed_line.is_empty():
			continue
		for token in trimmed_line.split(",", false):
			var trimmed_token: String = token.strip_edges()
			if trimmed_token.is_empty():
				continue
			result.append(int(trimmed_token))
	return result


func _get_indoor_tiles_texture() -> Texture2D:
	if indoor_tiles_texture != null:
		return indoor_tiles_texture

	var image_path: String = INDOOR_TILESET_IMAGE
	if not FileAccess.file_exists(image_path):
		push_warning("Indoor tileset image not found: %s" % image_path)
		return null

	var texture: Texture2D = load(image_path)
	if texture == null:
		push_error("Failed to load indoor tileset texture: %s" % image_path)
		return null

	indoor_tiles_texture = texture
	return indoor_tiles_texture


func _get_liquid_tiles_texture() -> Texture2D:
	if liquid_tiles_texture != null:
		return liquid_tiles_texture

	var image_path: String = LIQUID_TILESET_IMAGE
	if not FileAccess.file_exists(image_path):
		push_warning("Liquid tileset image not found: %s" % image_path)
		return null

	var texture: Texture2D = load(image_path)
	if texture == null:
		push_error("Failed to load liquid tileset texture: %s" % image_path)
		return null

	liquid_tiles_texture = texture
	return liquid_tiles_texture


func _get_tileset_texture_for_gid(raw_gid: int) -> Texture2D:
	var gid: int = raw_gid & TILED_GID_MASK
	if gid >= LIQUID_TILESET_FIRST_GID:
		return _get_liquid_tiles_texture()
	if gid >= INDOOR_TILESET_FIRST_GID:
		return _get_indoor_tiles_texture()
	return null


func _build_atlas_for_gid(raw_gid: int, source_texture: Texture2D) -> AtlasTexture:
	if source_texture == null:
		return null

	var gid: int = raw_gid & TILED_GID_MASK
	var first_gid: int = INDOOR_TILESET_FIRST_GID
	var columns: int = INDOOR_TILESET_COLUMNS
	var tile_size: Vector2i = Vector2i(64, 64)

	if gid >= LIQUID_TILESET_FIRST_GID:
		first_gid = LIQUID_TILESET_FIRST_GID
		columns = LIQUID_TILESET_COLUMNS
		tile_size = LIQUID_TILESET_TILE_SIZE
	elif gid >= INDOOR_TILESET_FIRST_GID:
		first_gid = INDOOR_TILESET_FIRST_GID
		columns = INDOOR_TILESET_COLUMNS
		tile_size = Vector2i(64, 64)
	else:
		return null

	var local_id: int = gid - first_gid
	if local_id < 0:
		return null
	var atlas_col: int = local_id % columns
	var atlas_row: int = int(local_id / columns)

	var atlas := AtlasTexture.new()
	atlas.atlas = source_texture
	atlas.region = Rect2(
		atlas_col * tile_size.x,
		atlas_row * tile_size.y,
		tile_size.x,
		tile_size.y
	)
	return atlas


func _build_collision_bodies(parsed_map: Dictionary) -> void:
	var collisions: Array = _get_object_group(parsed_map, "Collisions")
	for object_variant in collisions:
		var object_data: Dictionary = object_variant
		var width_value: float = max(float(object_data.get("width", 0.0)), 1.0)
		var height_value: float = max(float(object_data.get("height", 0.0)), 1.0)
		var x_value: float = float(object_data.get("x", 0.0))
		var y_value: float = float(object_data.get("y", 0.0))

		var body := StaticBody2D.new()
		body.position = Vector2(x_value + width_value * 0.5, y_value + height_value * 0.5)

		var collision_shape := CollisionShape2D.new()
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(width_value, height_value)
		collision_shape.shape = rect_shape
		body.add_child(collision_shape)
		map_collision_root.add_child(body)

		if debug_overlays_enabled:
			_add_debug_rect(Rect2(x_value, y_value, width_value, height_value), Color(0.95, 0.2, 0.2, 0.22), map_debug_root, "Collision")


func _build_transition_debug(parsed_map: Dictionary) -> void:
	var transitions: Array = _get_object_group(parsed_map, "Transition")
	for object_variant in transitions:
		var object_data: Dictionary = object_variant
		var props: Dictionary = object_data.get("properties", {})

		var rect := Rect2(
			float(object_data.get("x", 0.0)),
			float(object_data.get("y", 0.0)),
			max(float(object_data.get("width", 0.0)), 1.0),
			max(float(object_data.get("height", 0.0)), 1.0)
		)
		var target_map: String = str(props.get("target", ""))
		var target_spawn: String = str(props.get("pos", "world"))

		transition_zones.append({
			"rect": rect,
			"target": target_map,
			"pos": target_spawn,
		})

		if debug_overlays_enabled:
			_add_debug_rect(rect, Color(0.2, 0.55, 1.0, 0.24), map_debug_root, "Transition")
			_add_debug_label("-> %s (%s)" % [target_map, target_spawn], rect.position + Vector2(2, -6))


func _build_npc_runtime(parsed_map: Dictionary) -> void:
	var objects: Array = _get_object_group(parsed_map, "GameObjects")
	for object_variant in objects:
		var object_data: Dictionary = object_variant
		if str(object_data.get("name", "")) != "Character":
			continue

		var props: Dictionary = object_data.get("properties", {})
		var char_id: String = str(props.get("character_id", "npc"))
		var npc_pos: Vector2 = Vector2(
			float(object_data.get("x", 0.0)),
			float(object_data.get("y", 0.0))
		)
		var base_radius: float = float(props.get("radius", "30"))
		var trainer_info: Dictionary = {}
		if BigData.TRAINER_INFO.has(char_id):
			trainer_info = BigData.TRAINER_INFO[char_id]
		var record_key: String = _npc_record_key(char_id, npc_pos)
		if not trainer_battle_state.has(record_key):
			var initial_defeated: bool = false
			if not trainer_info.is_empty():
				initial_defeated = bool(trainer_info.get("defeated", false))
			trainer_battle_state[record_key] = initial_defeated

		var visual_node: Node2D = _create_npc_visual(npc_pos, str(props.get("graphic", char_id)), str(props.get("direction", "down")), char_id)
		_create_npc_collision_body(npc_pos, char_id)
		var is_defeated: bool = bool(trainer_battle_state.get(record_key, false))
		npc_records.append({
			"id": char_id,
			"record_key": record_key,
			"position": npc_pos,
			"direction": str(props.get("direction", "down")),
			"graphic": str(props.get("graphic", char_id)),
			"interact_radius": max(100.0, base_radius + 70.0),
			"trainer_info": trainer_info,
			"defeated": is_defeated,
			"visual_node": visual_node,
		})
		if is_defeated:
			_apply_npc_defeated_visual(visual_node)


func _build_chemical_spill_runtime(parsed_map: Dictionary) -> void:
	var spills: Array = _get_object_group(parsed_map, "ChemicalSpills")
	for spill_variant in spills:
		var spill: Dictionary = spill_variant
		var props: Dictionary = spill.get("properties", {})
		var gid_value: int = int(spill.get("gid", 0))
		var rect: Rect2 = _tmx_object_rect(spill, true)

		var aminos_text: String = str(props.get("aminos", ""))
		var amino_names: Array = []
		for token in aminos_text.split(",", false):
			var trimmed: String = token.strip_edges()
			if not trimmed.is_empty():
				amino_names.append(trimmed)

		chemical_spill_zones.append({
			"rect": rect,
			"gid": gid_value,
			"aminos": amino_names,
			"classroom": str(props.get("classroom", "labfight")),
			"level": int(props.get("level", "1")),
		})

		_create_chemical_spill_visual(spill)


func _create_npc_visual(position_value: Vector2, graphic_name: String, facing: String, npc_id: String) -> Node2D:
	if map_actor_root == null:
		return null

	var container := Node2D.new()
	container.name = "NPCContainer_%s" % npc_id
	map_actor_root.add_child(container)

	var sprite_frames: SpriteFrames = _get_character_sprite_frames(graphic_name, facing)
	if sprite_frames != null:
		var sprite := AnimatedSprite2D.new()
		sprite.name = "NPC_%s" % npc_id
		sprite.sprite_frames = sprite_frames
		sprite.animation = "idle"
		sprite.centered = true
		sprite.position = position_value
		sprite.play()
		container.add_child(sprite)
	else:
		var texture: Texture2D = _get_character_idle_texture(graphic_name, facing)
		if texture != null:
			var fallback_sprite := Sprite2D.new()
			fallback_sprite.name = "NPC_%s" % npc_id
			fallback_sprite.texture = texture
			fallback_sprite.centered = true
			fallback_sprite.position = position_value
			container.add_child(fallback_sprite)

	var shadow := Polygon2D.new()
	shadow.name = "NPCShadow_%s" % npc_id
	shadow.color = Color(0, 0, 0, 0.25)
	shadow.z_index = -1
	shadow.polygon = PackedVector2Array([
		position_value + Vector2(-10, -2),
		position_value + Vector2(10, -2),
		position_value + Vector2(14, 4),
		position_value + Vector2(-14, 4),
	])
	container.add_child(shadow)
	return container


func _create_npc_collision_body(position_value: Vector2, npc_id: String) -> void:
	if map_collision_root == null:
		return

	var body := StaticBody2D.new()
	body.name = "NPCCollision_%s" % npc_id
	body.position = position_value

	var collision_shape := CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(24, 8)
	collision_shape.shape = rect_shape
	body.add_child(collision_shape)
	map_collision_root.add_child(body)


func _create_chemical_spill_visual(spill: Dictionary) -> void:
	if map_floor_root == null:
		return

	var raw_gid: int = int(spill.get("gid", 0))
	if raw_gid == 0:
		return

	var texture: Texture2D = _get_tileset_texture_for_gid(raw_gid)
	var atlas: AtlasTexture = _build_atlas_for_gid(raw_gid, texture)
	if atlas == null:
		return

	var object_rect: Rect2 = _tmx_object_rect(spill, true)

	var sprite := Sprite2D.new()
	sprite.name = "SpillTile"
	sprite.texture = atlas
	sprite.centered = false
	sprite.position = object_rect.position
	sprite.scale = Vector2(
		object_rect.size.x / float(atlas.region.size.x),
		object_rect.size.y / float(atlas.region.size.y)
	)
	sprite.flip_h = (raw_gid & TILED_FLIP_H) != 0
	sprite.flip_v = (raw_gid & TILED_FLIP_V) != 0
	map_floor_root.add_child(sprite)


func _apply_npc_defeated_visual(visual_node: Node2D) -> void:
	if visual_node == null:
		return
	for child in visual_node.get_children():
		if child is CanvasItem:
			var canvas_item: CanvasItem = child
			canvas_item.modulate = Color(0.7, 0.72, 0.78, 0.9)


func _get_character_sprite_frames(graphic_name: String, facing: String) -> SpriteFrames:
	var row_lookup := {"down": 0, "left": 1, "right": 2, "up": 3}
	var row_index: int = int(row_lookup.get(facing, 0))
	var cache_key: String = "%s:%d:frames" % [graphic_name, row_index]
	if character_frame_cache.has(cache_key):
		return character_frame_cache[cache_key]

	var image_path: String = "%s/%s.png" % [CHARACTER_SHEETS_DIR, graphic_name]
	if not FileAccess.file_exists(image_path):
		return null

	var source_tex: Texture2D = load(image_path)
	if source_tex == null:
		push_warning("Failed to load NPC sheet: %s" % image_path)
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
	frames.set_animation_speed("idle", 3.0)
	for col in range(CHARACTER_SHEET_COLS):
		var frame_image: Image = Image.create(frame_width, frame_height, false, image.get_format())
		frame_image.blit_rect(
			image,
			Rect2i(col * frame_width, row_index * frame_height, frame_width, frame_height),
			Vector2i.ZERO
		)
		frames.add_frame("idle", ImageTexture.create_from_image(frame_image))

	character_frame_cache[cache_key] = frames
	return frames


func _get_character_idle_texture(graphic_name: String, facing: String) -> Texture2D:
	var frames: SpriteFrames = _get_character_sprite_frames(graphic_name, facing)
	if frames == null:
		return null
	return frames.get_frame_texture("idle", 0)


func _get_battle_background_texture(background_name: String) -> Texture2D:
	var normalized: String = background_name.strip_edges()
	if normalized.is_empty():
		normalized = "labfight"
	if battle_background_cache.has(normalized):
		return battle_background_cache[normalized]

	var image_path: String = "%s/%s.png" % [BATTLE_BACKGROUNDS_DIR, normalized]
	if not FileAccess.file_exists(image_path):
		if normalized != "labfight":
			return _get_battle_background_texture("labfight")
		return null

	var texture: Texture2D = load(image_path)
	if texture == null:
		push_warning("Failed to load battle background: %s" % image_path)
		return null

	battle_background_cache[normalized] = texture
	return texture


func _get_aminomon_battle_frame(mon_name: String, row: int = 0, col: int = 0) -> Texture2D:
	var safe_name: String = mon_name.strip_edges().to_lower()
	if safe_name.is_empty():
		return null
	var safe_row: int = clamp(row, 0, MONSTER_BATTLE_SHEET_ROWS - 1)
	var safe_col: int = clamp(col, 0, MONSTER_BATTLE_SHEET_COLS - 1)
	var cache_key: String = "%s:%d:%d" % [safe_name, safe_row, safe_col]
	if battle_monster_frame_cache.has(cache_key):
		return battle_monster_frame_cache[cache_key]

	var image_path: String = "%s/%s.png" % [MONSTER_BATTLE_SHEETS_DIR, safe_name]
	if not FileAccess.file_exists(image_path):
		return null

	var source_tex: Texture2D = load(image_path)
	if source_tex == null:
		push_warning("Failed to load Aminomon battle sheet: %s" % image_path)
		return null
	var image: Image = source_tex.get_image()
	if image == null:
		return null

	var frame_w: int = int(image.get_width() / MONSTER_BATTLE_SHEET_COLS)
	var frame_h: int = int(image.get_height() / MONSTER_BATTLE_SHEET_ROWS)
	if frame_w <= 0 or frame_h <= 0:
		return null

	var frame_image: Image = Image.create(frame_w, frame_h, false, image.get_format())
	frame_image.blit_rect(
		image,
		Rect2i(safe_col * frame_w, safe_row * frame_h, frame_w, frame_h),
		Vector2i.ZERO
	)
	var texture: Texture2D = ImageTexture.create_from_image(frame_image)
	battle_monster_frame_cache[cache_key] = texture
	return texture


func _get_attack_effect_frame(animation_name: String, col: int) -> Texture2D:
	var anim: String = animation_name.strip_edges().to_lower()
	if anim.is_empty():
		return null
	var safe_col: int = clamp(col, 0, ATTACK_SHEET_COLS - 1)
	var cache_key: String = "%s:%d" % [anim, safe_col]
	if battle_attack_frame_cache.has(cache_key):
		return battle_attack_frame_cache[cache_key]

	var image_path: String = "%s/%s.png" % [ATTACK_SHEETS_DIR, anim]
	if not FileAccess.file_exists(image_path):
		return null

	var source_tex: Texture2D = load(image_path)
	if source_tex == null:
		push_warning("Failed to load attack sheet: %s" % image_path)
		return null
	var image: Image = source_tex.get_image()
	if image == null:
		return null

	var frame_w: int = int(image.get_width() / ATTACK_SHEET_COLS)
	var frame_h: int = int(image.get_height())
	if frame_w <= 0 or frame_h <= 0:
		return null

	var frame_image: Image = Image.create(frame_w, frame_h, false, image.get_format())
	frame_image.blit_rect(
		image,
		Rect2i(safe_col * frame_w, 0, frame_w, frame_h),
		Vector2i.ZERO
	)
	var texture: Texture2D = ImageTexture.create_from_image(frame_image)
	battle_attack_frame_cache[cache_key] = texture
	return texture


func _get_ui_icon_texture(icon_name: String, highlighted: bool = false) -> Texture2D:
	var base_name: String = icon_name.strip_edges().to_lower()
	if base_name.is_empty():
		return null
	var file_stem: String = "%s_highlight" % base_name if highlighted else base_name
	if ui_icon_cache.has(file_stem):
		return ui_icon_cache[file_stem]

	var image_path: String = "%s/%s.png" % [UI_ICONS_DIR, file_stem]
	if not FileAccess.file_exists(image_path):
		if highlighted:
			return _get_ui_icon_texture(base_name, false)
		return null

	var texture: Texture2D = load(image_path)
	if texture == null:
		push_warning("Failed to load UI icon: %s" % image_path)
		return null

	ui_icon_cache[file_stem] = texture
	return texture


func _get_aminomon_icon_texture(mon_name: String) -> Texture2D:
	var safe_name: String = mon_name.strip_edges().to_lower()
	if safe_name.is_empty():
		return _get_fallback_mon_texture()
	if aminomon_icon_cache.has(safe_name):
		return aminomon_icon_cache[safe_name]

	var image_path: String = "%s/%s.png" % [AMINO_ICONS_DIR, safe_name]
	if not FileAccess.file_exists(image_path):
		var fallback_tex: Texture2D = _get_fallback_mon_texture()
		aminomon_icon_cache[safe_name] = fallback_tex
		return fallback_tex

	var texture: Texture2D = load(image_path)
	if texture == null:
		push_warning("Failed to load Aminomon icon: %s" % image_path)
		texture = _get_fallback_mon_texture()
	aminomon_icon_cache[safe_name] = texture
	return texture


func _get_aminomon_portrait_texture(mon_name: String) -> Texture2D:
	var battle_tex: Texture2D = _get_aminomon_battle_frame(mon_name, 0, 0)
	if battle_tex != null:
		return battle_tex
	return _get_aminomon_icon_texture(mon_name)


func _get_fallback_mon_texture() -> Texture2D:
	if fallback_mon_texture != null:
		return fallback_mon_texture
	fallback_mon_texture = _build_fallback_mon_texture()
	return fallback_mon_texture


func _build_fallback_mon_texture() -> Texture2D:
	var image := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.19, 0.22, 0.3, 1.0))
	for i in range(64):
		image.set_pixel(i, i, Color(0.84, 0.87, 0.93, 1.0))
		image.set_pixel(63 - i, i, Color(0.84, 0.87, 0.93, 1.0))
	return ImageTexture.create_from_image(image)


func _ensure_runtime_ui_nodes() -> void:
	var ui_layer: CanvasLayer = get_node_or_null("UILayer") as CanvasLayer
	if ui_layer == null:
		return

	if ui_runtime_root == null or not is_instance_valid(ui_runtime_root):
		ui_runtime_root = ui_layer.get_node_or_null("RuntimeSprites") as Control
	if ui_runtime_root == null:
		ui_runtime_root = Control.new()
		ui_runtime_root.name = "RuntimeSprites"
		ui_runtime_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_runtime_root.z_index = 50
		ui_layer.add_child(ui_runtime_root)

	_ensure_runtime_icon_layer("DexIcons")
	_ensure_runtime_icon_layer("TeamIcons")
	_ensure_runtime_icon_layer("StoragePartyIcons")
	_ensure_runtime_icon_layer("StorageStorageIcons")
	_ensure_runtime_portrait("DexPortrait", Vector2(1012.0, 132.0))
	_ensure_runtime_portrait("TeamPortrait", Vector2(984.0, 132.0))
	_ensure_runtime_portrait("StoragePortrait", Vector2(1012.0, 132.0))


func _ensure_runtime_icon_layer(node_name: String) -> Control:
	if ui_runtime_root == null or not is_instance_valid(ui_runtime_root):
		return null
	var layer: Control = ui_runtime_root.get_node_or_null(node_name) as Control
	if layer == null:
		layer = Control.new()
		layer.name = node_name
		layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui_runtime_root.add_child(layer)
	layer.visible = false
	return layer


func _ensure_runtime_portrait(node_name: String, position_value: Vector2) -> TextureRect:
	if ui_runtime_root == null or not is_instance_valid(ui_runtime_root):
		return null
	var portrait: TextureRect = ui_runtime_root.get_node_or_null(node_name) as TextureRect
	if portrait == null:
		portrait = TextureRect.new()
		portrait.name = node_name
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size = MENU_PORTRAIT_SIZE
		portrait.size = MENU_PORTRAIT_SIZE
		ui_runtime_root.add_child(portrait)
	portrait.position = position_value
	portrait.visible = false
	return portrait


func _clear_runtime_icon_layer(node_name: String) -> void:
	var layer: Control = _ensure_runtime_icon_layer(node_name)
	if layer == null:
		return
	for child in layer.get_children():
		child.queue_free()
	layer.visible = false


func _ui_text_line_height(label: Control) -> float:
	if label == null:
		return UI_LIST_LINE_HEIGHT
	var font: Font = label.get_theme_font("normal_font")
	var font_size: int = label.get_theme_font_size("normal_font_size")
	if font_size <= 0:
		font_size = int(UI_LIST_LINE_HEIGHT)
	if font == null:
		return UI_LIST_LINE_HEIGHT
	return max(UI_LIST_LINE_HEIGHT, float(ceil(font.get_height(font_size))))


func _ui_text_line_position(label: Control, line_number: int, x_offset: float = UI_ICON_TEXT_X_OFFSET) -> Vector2:
	if label == null:
		return Vector2(0.0, 0.0)
	var safe_line: int = max(1, line_number)
	var line_height: float = _ui_text_line_height(label)
	return Vector2(label.offset_left + x_offset, label.offset_top + float(safe_line - 1) * line_height)


func _render_runtime_icon_column(
	node_name: String,
	names: Array,
	selected_row: int,
	position_value: Vector2,
	row_height: float = UI_LIST_LINE_HEIGHT,
	icon_size: Vector2 = MENU_ICON_SIZE
) -> void:
	if names.is_empty():
		_clear_runtime_icon_layer(node_name)
		return
	var layer: Control = _ensure_runtime_icon_layer(node_name)
	if layer == null:
		return
	var safe_icon_size: Vector2 = Vector2(max(8.0, icon_size.x), max(8.0, icon_size.y))
	var clamped_row_height: float = max(1.0, row_height)
	var row_center_offset: float = max(0.0, (clamped_row_height - safe_icon_size.y) * 0.5)
	for child in layer.get_children():
		child.queue_free()
	layer.position = position_value
	for row in range(names.size()):
		var entry_name: String = str(names[row])
		var icon_rect := TextureRect.new()
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = safe_icon_size
		icon_rect.size = safe_icon_size
		icon_rect.position = Vector2(0.0, row_center_offset + float(row) * clamped_row_height)
		icon_rect.texture = _get_aminomon_icon_texture(entry_name)
		icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0) if row == selected_row else Color(0.74, 0.78, 0.86, 0.95)
		layer.add_child(icon_rect)
	layer.visible = true


func _render_runtime_icon_grid(
	node_name: String,
	names: Array,
	selected_index: int,
	position_value: Vector2,
	columns: int = 2,
	cell_spacing: Vector2 = Vector2(220.0, 78.0),
	column_stagger: float = 10.0,
	source_index: int = -1,
	icon_size: Vector2 = MENU_ICON_SIZE
) -> void:
	if names.is_empty():
		_clear_runtime_icon_layer(node_name)
		return
	var layer: Control = _ensure_runtime_icon_layer(node_name)
	if layer == null:
		return
	var safe_icon_size: Vector2 = Vector2(max(8.0, icon_size.x), max(8.0, icon_size.y))
	var safe_columns: int = max(1, columns)
	for child in layer.get_children():
		child.queue_free()
	layer.position = position_value
	for index in range(names.size()):
		var col: int = int(posmod(index, safe_columns))
		var row: int = int(index / safe_columns)
		var slot_pos := Vector2(
			float(col) * cell_spacing.x,
			float(row) * cell_spacing.y + (column_stagger if col % 2 == 1 else 0.0)
		)
		var backdrop := ColorRect.new()
		backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		backdrop.custom_minimum_size = safe_icon_size + Vector2(12.0, 12.0)
		backdrop.size = backdrop.custom_minimum_size
		backdrop.position = slot_pos - Vector2(6.0, 6.0)
		if index == selected_index:
			backdrop.color = Color(0.95, 0.84, 0.38, 0.45)
		elif index == source_index:
			backdrop.color = Color(0.56, 0.92, 0.56, 0.38)
		else:
			backdrop.color = Color(0.16, 0.2, 0.27, 0.24)
		layer.add_child(backdrop)

		var icon_rect := TextureRect.new()
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = safe_icon_size
		icon_rect.size = safe_icon_size
		icon_rect.position = slot_pos
		var entry_name: String = str(names[index]).strip_edges()
		var is_empty: bool = entry_name.is_empty()
		icon_rect.texture = _get_fallback_mon_texture() if is_empty else _get_aminomon_icon_texture(entry_name)
		if is_empty:
			icon_rect.modulate = Color(0.6, 0.64, 0.72, 0.35)
		elif index == selected_index:
			icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
		elif index == source_index:
			icon_rect.modulate = Color(0.82, 1.0, 0.82, 0.95)
		else:
			icon_rect.modulate = Color(0.76, 0.8, 0.88, 0.95)
		layer.add_child(icon_rect)
	layer.visible = true


func _render_runtime_portrait(node_name: String, position_value: Vector2, mon_name: String, visible: bool) -> void:
	var portrait: TextureRect = _ensure_runtime_portrait(node_name, position_value)
	if portrait == null:
		return
	if not visible:
		portrait.visible = false
		portrait.texture = null
		return
	portrait.position = position_value
	portrait.texture = _get_aminomon_portrait_texture(mon_name)
	portrait.visible = portrait.texture != null


func _render_runtime_mon_sprite(
	node_name: String,
	position_value: Vector2,
	mon_name: String,
	visible: bool,
	size_value: Vector2 = MENU_PORTRAIT_SIZE
) -> void:
	var portrait: TextureRect = _ensure_runtime_portrait(node_name, position_value)
	if portrait == null:
		return
	if not visible:
		portrait.visible = false
		portrait.texture = null
		return
	var safe_size: Vector2 = Vector2(max(32.0, size_value.x), max(32.0, size_value.y))
	portrait.custom_minimum_size = safe_size
	portrait.size = safe_size
	portrait.position = position_value
	var battle_tex: Texture2D = _get_aminomon_battle_frame(mon_name, 0, 0)
	if battle_tex == null:
		battle_tex = _get_aminomon_portrait_texture(mon_name)
	portrait.texture = battle_tex
	portrait.visible = portrait.texture != null


func _ensure_interaction_notice_sprite() -> void:
	if map_actor_root == null:
		return
	if interaction_notice_sprite != null and is_instance_valid(interaction_notice_sprite):
		return
	var texture: Texture2D = load(INTERACTION_NOTICE_ICON)
	if texture == null:
		return
	interaction_notice_sprite = Sprite2D.new()
	interaction_notice_sprite.name = "InteractionNotice"
	interaction_notice_sprite.texture = texture
	interaction_notice_sprite.visible = false
	interaction_notice_sprite.centered = true
	interaction_notice_sprite.z_as_relative = false
	interaction_notice_sprite.z_index = 500
	map_actor_root.add_child(interaction_notice_sprite)


func _set_interaction_notice(visible_value: bool) -> void:
	_ensure_interaction_notice_sprite()
	if interaction_notice_sprite == null or not is_instance_valid(interaction_notice_sprite):
		return
	if not visible_value or player == null:
		interaction_notice_sprite.visible = false
		return
	interaction_notice_sprite.global_position = player.global_position + Vector2(0.0, -32.0)
	interaction_notice_sprite.visible = true


func _set_fade_overlay_alpha(alpha_value: float) -> void:
	var overlay: ColorRect = get_node_or_null("UILayer/FadeOverlay") as ColorRect
	if overlay == null:
		return
	var clamped_alpha: float = clamp(alpha_value, 0.0, 1.0)
	overlay.visible = clamped_alpha > 0.001
	overlay.color = Color(0.0, 0.0, 0.0, clamped_alpha)


func _trigger_transition_fade() -> void:
	transition_fade_timer = TRANSITION_FADE_DURATION
	_set_fade_overlay_alpha(1.0)


func _update_transition_fade(delta: float) -> void:
	if transition_fade_timer <= 0.0:
		return
	transition_fade_timer = max(0.0, transition_fade_timer - max(0.0, delta))
	var alpha_value: float = transition_fade_timer / TRANSITION_FADE_DURATION if TRANSITION_FADE_DURATION > 0.0 else 0.0
	_set_fade_overlay_alpha(alpha_value)


func _battle_menu_icon_name_for_option(option_label: String) -> String:
	var lower: String = option_label.strip_edges().to_lower()
	match lower:
		"fight":
			return "sword"
		"switch":
			return "arrows"
		"catch":
			return "hand"
		"run":
			return "cross"
		"back":
			return "cross"
		_:
			return ""


func _try_interact() -> void:
	if battle_active or dialog_active or storage_menu_active or team_menu_active:
		return
	var now_msec: int = Time.get_ticks_msec()
	if now_msec < interaction_cooldown_until_msec:
		return

	var npc: Dictionary = _get_nearby_npc_for_interaction()
	if npc.is_empty():
		_show_dialog(["No one to interact with. Face an NPC and press Space."])
		interaction_cooldown_until_msec = now_msec + 150
		return

	interaction_cooldown_until_msec = now_msec + 150
	_interact_with_npc(npc)


func _get_nearby_npc_for_interaction() -> Dictionary:
	if player == null or npc_records.is_empty():
		return {}

	var player_pos: Vector2 = player.global_position
	var facing: String = str(player.get("facing_direction"))
	if facing.is_empty():
		facing = "down"

	var best_npc: Dictionary = {}
	var best_distance: float = INF

	for npc_variant in npc_records:
		var npc: Dictionary = npc_variant
		var npc_pos: Vector2 = npc.get("position", Vector2.ZERO)
		var rel: Vector2 = npc_pos - player_pos
		var dist: float = rel.length()
		var radius_value: float = float(npc.get("interact_radius", 100.0))
		if dist > radius_value:
			continue
		if not _facing_allows_interaction(rel, facing):
			continue
		if dist < best_distance:
			best_distance = dist
			best_npc = npc

	return best_npc


func _facing_allows_interaction(relative_pos: Vector2, facing: String) -> bool:
	var tolerance: float = 42.0
	match facing:
		"left":
			return relative_pos.x < 0.0 and abs(relative_pos.y) < tolerance
		"right":
			return relative_pos.x > 0.0 and abs(relative_pos.y) < tolerance
		"up":
			return relative_pos.y < 0.0 and abs(relative_pos.x) < tolerance
		_:
			return relative_pos.y > 0.0 and abs(relative_pos.x) < tolerance


func _interact_with_npc(npc: Dictionary) -> void:
	if fusion_sequence_active:
		return
	var npc_id: String = str(npc.get("id", "npc"))
	var lines: Array = []

	if not _is_special_npc(npc_id):
		_interact_with_trainer_npc(npc)
		return

	match npc_id:
		"healer":
			var healed_count: int = _apply_healer()
			lines = ["BY THE POWER OF SCIENCE", "Healed %d Aminomons." % healed_count, _team_summary()]
		"fuser":
			var fusion_events: Array = _apply_fusions_with_events()
			var fused_count: int = fusion_events.size()
			if fused_count > 0:
				_start_fusion_sequence(
					fusion_events,
					["Let's try fusions!", "Fused %d Aminomons." % fused_count, _team_summary()]
				)
				return
			else:
				lines = ["Let's try fusions!", "No party members meet fusion requirements yet."]
		"unfuser":
			var unfusion_events: Array = _apply_unfusions_with_events()
			var unfused_count: int = unfusion_events.size()
			if unfused_count > 0:
				_start_fusion_sequence(
					unfusion_events,
					["You don't want a fusion?", "Unfused %d Aminomons." % unfused_count, _team_summary()]
				)
				return
			else:
				lines = ["You don't want a fusion?", "No fused Aminomons are in the party."]
		"storage":
			_open_storage_menu()
			return
	_show_dialog(lines)


func _trainer_lines_for_npc(npc: Dictionary) -> Array:
	var npc_id: String = str(npc.get("id", "trainer"))
	var trainer_info: Dictionary = npc.get("trainer_info", {})
	var result: Array = []
	var use_defeated_lines: bool = _npc_is_defeated(npc)

	if not trainer_info.is_empty():
		var dialog_block: Dictionary = trainer_info.get("dialog", {})
		var key_name: String = "defeated" if use_defeated_lines else "default"
		var chosen_lines: Array = dialog_block.get(key_name, [])
		if chosen_lines.is_empty() and key_name == "defeated":
			chosen_lines = dialog_block.get("default", [])
		for line_variant in chosen_lines:
			result.append(str(line_variant))

	if result.is_empty():
		result.append("Trainer %s" % npc_id)
	return result


func _interact_with_trainer_npc(npc: Dictionary) -> void:
	if _npc_is_defeated(npc):
		var repeat_lines: Array = _trainer_lines_for_npc(npc)
		if repeat_lines.is_empty():
			repeat_lines = ["We already battled."]
		_show_dialog(repeat_lines)
		return

	var intro_lines: Array = _trainer_lines_for_npc(npc)
	if intro_lines.is_empty():
		intro_lines = ["Trainer challenge incoming."]
	_start_dialog(intro_lines, Callable(self, "_start_trainer_battle_from_dialog").bind(npc))


func _start_trainer_battle_from_dialog(npc: Dictionary) -> void:
	var trainer_info: Dictionary = npc.get("trainer_info", {})
	var npc_id: String = str(npc.get("id", "trainer"))
	var monsters: Dictionary = trainer_info.get("monsters", {})
	var opponent_summary: String = _format_opponent_team_summary(monsters)
	_start_battle({
		"kind": "trainer",
		"npc": npc,
		"npc_id": npc_id,
		"classroom": str(trainer_info.get("classroom", "labfight")),
		"monsters": monsters,
		"opponent_summary": opponent_summary,
	})


func _finish_trainer_battle(npc: Dictionary) -> void:
	var reward_points: int = TRAINER_STANDARD_REWARD_POINTS
	var milestone_messages: Array = []
	var npc_id: String = str(npc.get("id", "trainer"))
	if TRAINER_MILESTONE_REWARDS.has(npc_id):
		var reward_payload: Dictionary = TRAINER_MILESTONE_REWARDS.get(npc_id, {})
		var milestone_key: String = str(reward_payload.get("milestone", ""))
		if not milestone_key.is_empty() and not _has_milestone(milestone_key):
			_mark_milestone(milestone_key)
			milestone_messages.append("Milestone unlocked: %s" % milestone_key)
		reward_points += int(reward_payload.get("points", 0))
	_add_currency_points(reward_points)
	var record_key: String = str(npc.get("record_key", ""))
	if not record_key.is_empty():
		trainer_battle_state[record_key] = true
		_mark_npc_record_defeated(record_key)

	var post_lines: Array = _trainer_lines_for_npc(npc)
	if post_lines.is_empty():
		post_lines = ["Battle complete."]
	post_lines.append_array(milestone_messages)
	post_lines.append("Earned %d pts. Total: %d" % [reward_points, currency_points])
	post_lines.append(_team_summary())
	_show_dialog(post_lines)


func _format_opponent_team_summary(monsters: Dictionary) -> String:
	if monsters.is_empty():
		return "Unknown team"
	var indexes: Array = monsters.keys()
	indexes.sort()
	var parts: Array = []
	for index_variant in indexes:
		var duo_variant = monsters.get(index_variant)
		if duo_variant is Array and (duo_variant as Array).size() >= 2:
			var duo: Array = duo_variant
			parts.append("%s Lv%d" % [str(duo[0]), int(duo[1])])
	return ", ".join(PackedStringArray(parts))


func _start_battle(context: Dictionary) -> void:
	if battle_active:
		return

	var runtime_context: Dictionary = _build_battle_runtime_context(context)
	if runtime_context.is_empty():
		_show_dialog(["Could not start battle.", "No available Aminomons."])
		return

	_trigger_transition_fade()
	battle_active = true
	battle_context = runtime_context
	_set_player_blocked(true)
	_battle_set_state("main_menu")
	_render_battle()


func _resolve_battle_action(action: String) -> void:
	if not battle_active:
		return

	match action:
		"run":
			if str(battle_context.get("kind", "")) == "wild":
				_end_battle(action, false)
			else:
				_set_status("Cannot run from trainer battle.")
				_render_battle()
		"fight":
			var usable_skills: Array = _battle_usable_skills_for_active_player()
			if usable_skills.is_empty():
				_battle_execute_player_skill(BASIC_ATTACK_SKILL)
			else:
				_battle_execute_player_skill(str(usable_skills[0]))
		_:
			_render_battle()


func _end_battle(action: String, victory: bool) -> void:
	var context: Dictionary = battle_context.duplicate(true)
	var kind: String = str(context.get("kind", ""))

	_trigger_transition_fade()
	battle_active = false
	battle_context.clear()
	_render_battle()
	_set_player_blocked(false)

	if kind == "trainer":
		var npc: Dictionary = context.get("npc", {})
		if victory:
			_finish_trainer_battle(npc)
		else:
			_heal_party_to_full()
			_show_dialog(["You lost the trainer battle.", "Your party was restored.", _team_summary()])
		return

	if kind == "wild":
		if victory:
			if action == "catch":
				# Catch success already updates party/storage before ending battle.
				_show_dialog([
					"Capture complete.",
					"Party: %d | Storage: %d" % [player_monsters.size(), player_storage.size()],
					"Use F5 to save."
				])
			else:
				_show_dialog([
					"Wild %s was defeated." % str(context.get("opponent_name", "Aminomon")),
					"Battle XP was awarded.",
					_team_summary()
				])
		else:
			_show_dialog(["You got away safely."])
		return

	_show_dialog(["Battle ended."])


func _render_battle() -> void:
	var box: ColorRect = get_node_or_null("UILayer/BattleBox") as ColorRect
	var label: Label = get_node_or_null("UILayer/BattleText") as Label

	var message: String = ""
	if battle_active:
		message = _battle_render_text()

	if box:
		box.visible = not message.is_empty()
	if label:
		label.text = message
		label.visible = not message.is_empty()
	_render_battle_visuals()


func _render_battle_visuals() -> void:
	var backdrop: TextureRect = get_node_or_null("UILayer/BattleBackdrop") as TextureRect
	var opp_sprite: TextureRect = get_node_or_null("UILayer/BattleOppSprite") as TextureRect
	var player_sprite: TextureRect = get_node_or_null("UILayer/BattlePlayerSprite") as TextureRect
	var effect_sprite: TextureRect = get_node_or_null("UILayer/BattleEffect") as TextureRect
	var opp_hud: Label = get_node_or_null("UILayer/BattleOppHud") as Label
	var player_hud: Label = get_node_or_null("UILayer/BattlePlayerHud") as Label
	var opp_hp_bar: ProgressBar = get_node_or_null("UILayer/BattleOppHP") as ProgressBar
	var opp_en_bar: ProgressBar = get_node_or_null("UILayer/BattleOppEN") as ProgressBar
	var player_hp_bar: ProgressBar = get_node_or_null("UILayer/BattlePlayerHP") as ProgressBar
	var player_en_bar: ProgressBar = get_node_or_null("UILayer/BattlePlayerEN") as ProgressBar
	var action_icons: Array = [
		get_node_or_null("UILayer/BattleActionIcon0"),
		get_node_or_null("UILayer/BattleActionIcon1"),
		get_node_or_null("UILayer/BattleActionIcon2"),
		get_node_or_null("UILayer/BattleActionIcon3")
	]
	var action_labels: Array = [
		get_node_or_null("UILayer/BattleActionLabel0"),
		get_node_or_null("UILayer/BattleActionLabel1"),
		get_node_or_null("UILayer/BattleActionLabel2"),
		get_node_or_null("UILayer/BattleActionLabel3")
	]
	var battle_meta: Label = get_node_or_null("UILayer/BattleMenuMeta") as Label

	if not battle_active:
		for node_variant in [backdrop, opp_sprite, player_sprite, effect_sprite]:
			var texture_node: TextureRect = node_variant as TextureRect
			if texture_node:
				texture_node.visible = false
				texture_node.texture = null
		for hud_variant in [opp_hud, player_hud]:
			var hud_label: Label = hud_variant as Label
			if hud_label:
				hud_label.visible = false
				hud_label.text = ""
		for bar_variant in [opp_hp_bar, opp_en_bar, player_hp_bar, player_en_bar]:
			var bar: ProgressBar = bar_variant as ProgressBar
			if bar:
				bar.visible = false
				bar.value = 0.0
		for icon_variant in action_icons:
			var icon_rect: TextureRect = icon_variant as TextureRect
			if icon_rect:
				icon_rect.visible = false
				icon_rect.texture = null
		for label_variant in action_labels:
			var action_label: Label = label_variant as Label
			if action_label:
				action_label.visible = false
				action_label.text = ""
		if battle_meta:
			battle_meta.visible = false
			battle_meta.text = ""
		return

	var classroom: String = str(battle_context.get("classroom", "labfight"))
	var bg_texture: Texture2D = _get_battle_background_texture(classroom)
	if backdrop:
		backdrop.texture = bg_texture
		backdrop.visible = bg_texture != null

	var opp_mon = _battle_active_mon(false)
	var player_mon = _battle_active_mon(true)
	var idle_col: int = int((Time.get_ticks_msec() / BATTLE_MONSTER_IDLE_FRAME_MS) % MONSTER_BATTLE_SHEET_COLS)
	var opp_texture: Texture2D = _get_aminomon_battle_frame(str(opp_mon.name), 0, idle_col) if opp_mon != null else null
	var player_texture: Texture2D = _get_aminomon_battle_frame(str(player_mon.name), 0, idle_col) if player_mon != null else null

	if opp_sprite:
		opp_sprite.texture = opp_texture
		opp_sprite.visible = opp_texture != null
	if player_sprite:
		player_sprite.texture = player_texture
		player_sprite.visible = player_texture != null

	if effect_sprite:
		var effect: Dictionary = battle_context.get("effect", {})
		if effect.is_empty():
			effect_sprite.visible = false
			effect_sprite.texture = null
		else:
			var started_msec: int = int(effect.get("started_msec", 0))
			var frame_index: int = clamp(int((Time.get_ticks_msec() - started_msec) / ATTACK_EFFECT_FRAME_MS), 0, ATTACK_SHEET_COLS - 1)
			var effect_tex: Texture2D = _get_attack_effect_frame(str(effect.get("animation", "")), frame_index)
			var target_player: bool = bool(effect.get("target_player", false))
			var target_rect_node: TextureRect = player_sprite if target_player else opp_sprite
			effect_sprite.texture = effect_tex
			if target_rect_node != null:
				effect_sprite.position = target_rect_node.position + (target_rect_node.size * 0.5) - (effect_sprite.size * 0.5)
			effect_sprite.visible = effect_tex != null

	if opp_hud:
		opp_hud.text = _battle_side_status_line("Foe", false)
		opp_hud.visible = true
	if player_hud:
		player_hud.text = _battle_side_status_line("You", true)
		player_hud.visible = true
	_battle_update_bar(opp_hp_bar, float(opp_mon.health) if opp_mon != null else 0.0, float(opp_mon.get_single_stat("MAX_HEALTH")) if opp_mon != null else 1.0)
	_battle_update_bar(opp_en_bar, float(opp_mon.energy) if opp_mon != null else 0.0, float(opp_mon.get_single_stat("MAX_ENERGY")) if opp_mon != null else 1.0)
	_battle_update_bar(player_hp_bar, float(player_mon.health) if player_mon != null else 0.0, float(player_mon.get_single_stat("MAX_HEALTH")) if player_mon != null else 1.0)
	_battle_update_bar(player_en_bar, float(player_mon.energy) if player_mon != null else 0.0, float(player_mon.get_single_stat("MAX_ENERGY")) if player_mon != null else 1.0)

	var state: String = str(battle_context.get("state", "main_menu"))
	var options: Array = _battle_current_menu_options()
	var cursor: int = int(battle_context.get("cursor", 0))
	for i in range(action_icons.size()):
		var icon_rect: TextureRect = action_icons[i] as TextureRect
		var action_label: Label = action_labels[i] as Label
		if icon_rect == null or action_label == null:
			continue
		if state != "main_menu" or i >= options.size():
			icon_rect.visible = false
			icon_rect.texture = null
			action_label.visible = false
			action_label.text = ""
			continue
		var option_text: String = str(options[i])
		var icon_name: String = _battle_menu_icon_name_for_option(option_text)
		var selected: bool = i == cursor
		icon_rect.texture = _get_ui_icon_texture(icon_name, selected)
		icon_rect.visible = icon_rect.texture != null
		action_label.text = option_text
		action_label.modulate = Color(1.0, 0.92, 0.55, 1.0) if selected else Color(0.88, 0.9, 0.94, 0.92)
		action_label.visible = true

	if battle_meta:
		battle_meta.text = _battle_menu_meta_text()
		battle_meta.visible = not battle_meta.text.is_empty()


func _battle_update_bar(bar: ProgressBar, current_value: float, max_value: float) -> void:
	if bar == null:
		return
	bar.min_value = 0.0
	bar.max_value = max(max_value, 1.0)
	bar.value = clamp(current_value, 0.0, bar.max_value)
	bar.visible = true


func _battle_menu_meta_text() -> String:
	if not battle_active:
		return ""
	var state: String = str(battle_context.get("state", "main_menu"))
	var cursor: int = int(battle_context.get("cursor", 0))
	if state == "attack_menu":
		var options: Array = _battle_current_menu_options()
		if cursor >= 0 and cursor < options.size():
			var selected_option: String = str(options[cursor])
			var option_lower: String = selected_option.strip_edges().to_lower()
			if option_lower == "wait":
				return "Wait: skip turn and restore 10% max energy (min 1)."
			if option_lower == "back":
				return "Back: return to the main battle menu."
			var skill_name: String = _battle_attack_option_to_skill_name(selected_option)
			var skill_data: Dictionary = BigData.SKILLS_DATA.get(skill_name, {})
			if not skill_data.is_empty():
				return "Attack: %s | Cost %s | Elem %s | Target %s" % [
					selected_option,
					str(skill_data.get("cost", 0)),
					str(skill_data.get("element", "normal")),
					str(skill_data.get("target", "opponent"))
				]
		return "Choose an attack, wait, or go back."
	if state == "switch_menu":
		var switchable: Array = _battle_switchable_player_indices()
		if cursor >= 0 and cursor < switchable.size():
			var idx: int = int(switchable[cursor])
			var mon = player_monsters.get(idx)
			if mon != null:
				return "Switch target: #%d %s Lv%d | HP %d/%d | EN %d/%d" % [
					idx,
					str(mon.name),
					int(mon.level),
					int(round(float(mon.health))),
					int(round(mon.get_single_stat("MAX_HEALTH"))),
					int(round(float(mon.energy))),
					int(round(mon.get_single_stat("MAX_ENERGY")))
				]
		return "Choose a party member to switch in."
	if state == "message":
		return ""
	return "Action menu icons mirror the original pygame battle choices."


func _build_battle_runtime_context(input_context: Dictionary) -> Dictionary:
	var opponent_party: Dictionary = _build_opponent_party_for_battle(input_context)
	return _battle_state.build_runtime_context(input_context, player_monsters, opponent_party)


func _battle_start_effect(animation_name: String, target_player_side: bool) -> void:
	if not battle_active:
		return
	var anim: String = animation_name.strip_edges().to_lower()
	if anim.is_empty():
		return
	battle_context["effect"] = {
		"animation": anim,
		"target_player": target_player_side,
		"started_msec": Time.get_ticks_msec()
	}
	_render_battle_visuals()


func _update_battle_effect() -> void:
	if not battle_active:
		return
	var effect: Dictionary = battle_context.get("effect", {})
	if effect.is_empty():
		return
	var started_msec: int = int(effect.get("started_msec", 0))
	if started_msec <= 0:
		battle_context["effect"] = {}
		_render_battle_visuals()
		return
	var frame_index: int = int((Time.get_ticks_msec() - started_msec) / ATTACK_EFFECT_FRAME_MS)
	if frame_index >= ATTACK_SHEET_COLS:
		battle_context["effect"] = {}
		_render_battle_visuals()
		return
	_render_battle_visuals()


func _build_opponent_party_for_battle(ctx: Dictionary) -> Dictionary:
	var party: Dictionary = _battle_state.build_opponent_party(ctx, AminomonRes)
	var kind: String = str(ctx.get("kind", ""))
	if kind == "wild":
		var wild_mon = party.get(0, null)
		if wild_mon != null and wild_mon.has_method("set_mon_metadata"):
			wild_mon.set_mon_metadata(
				str(ctx.get("opponent_rarity_variant", "normal")),
				str(ctx.get("opponent_trait_id", "neutral")),
				{"type": "none", "turns": 0},
				str(ctx.get("opponent_passive_id", ""))
			)
	else:
		for idx_variant in party.keys():
			var mon = party.get(int(idx_variant), null)
			if mon == null or not mon.has_method("set_mon_metadata"):
				continue
			var passive_id: String = str(mon.get("passive_id")).strip_edges()
			if passive_id.is_empty():
				passive_id = BigData.get_species_passive(str(mon.name), str(mon.element))
			mon.set_mon_metadata("normal", _roll_trait_id(), {"type": "none", "turns": 0}, passive_id)
	return party


func _battle_render_text() -> String:
	var lines: Array = []
	var kind: String = str(battle_context.get("kind", "battle"))
	var title: String = "Trainer Battle" if kind == "trainer" else "Wild Encounter"
	lines.append(title)
	lines.append("Area: %s" % str(battle_context.get("classroom", "labfight")))
	lines.append("")
	lines.append(_battle_side_status_line("You", true))
	lines.append(_battle_side_status_line("Foe", false))
	var player_mon = _battle_active_mon(true)
	var foe_mon = _battle_active_mon(false)
	if player_mon != null:
		lines.append("You Tags: %s | Passive: %s | Status: %s" % [
			_format_mon_badges(player_mon),
			str(BigData.PASSIVE_DATA.get(str(player_mon.get("passive_id")).strip_edges(), {}).get("display_name", "None")),
			_status_display(player_mon)
		])
	if foe_mon != null:
		lines.append("Foe Tags: %s | Passive: %s | Status: %s" % [
			_format_mon_badges(foe_mon),
			str(BigData.PASSIVE_DATA.get(str(foe_mon.get("passive_id")).strip_edges(), {}).get("display_name", "None")),
			_status_display(foe_mon)
		])
	lines.append("")

	var state: String = str(battle_context.get("state", "main_menu"))
	if state == "message":
		var queue: Array = battle_context.get("message_queue", [])
		var message_index: int = int(battle_context.get("message_index", 0))
		if message_index >= 0 and message_index < queue.size():
			lines.append(str(queue[message_index]))
		lines.append("")
		lines.append("[Space / Enter] Continue")
	else:
		var options: Array = _battle_current_menu_options()
		var cursor: int = int(battle_context.get("cursor", 0))
		var prompt: String = _battle_menu_prompt(state)
		lines.append(prompt)
		for i in range(options.size()):
			var prefix: String = ">" if i == cursor else " "
			lines.append("%s %s" % [prefix, str(options[i])])
		lines.append("")
		lines.append("[Up/Down] Select  [Enter/Space] Confirm  [Esc] Back")
		if kind == "wild":
			lines.append("[R] Run  |  Catch is available in the main menu")

	return "\n".join(PackedStringArray(lines))


func _battle_side_status_line(label_prefix: String, player_side: bool) -> String:
	return _battle_state.side_status_line(battle_context, label_prefix, player_side)


func _battle_menu_prompt(state: String) -> String:
	return _battle_state.menu_prompt(state)


func _battle_current_menu_options() -> Array:
	return _battle_state.current_menu_options(battle_context, player_monsters)


func _battle_set_state(state: String) -> void:
	_battle_state.set_state(battle_context, state)
	_render_battle()


func _battle_move_cursor(delta: int) -> void:
	var state: String = str(battle_context.get("state", "main_menu"))
	if state == "message":
		return
	var options: Array = _battle_current_menu_options()
	_battle_state.move_cursor(battle_context, delta, options)
	_render_battle()


func _battle_confirm_current_selection() -> void:
	var state: String = str(battle_context.get("state", "main_menu"))
	if state == "message":
		_battle_advance_message()
		return

	var options: Array = _battle_current_menu_options()
	if options.is_empty():
		return
	var cursor: int = clamp(int(battle_context.get("cursor", 0)), 0, options.size() - 1)

	if state == "main_menu":
		var choice: String = str(options[cursor]).to_lower()
		match choice:
			"fight":
				_battle_set_state("attack_menu")
			"switch":
				_battle_set_state("switch_menu")
			"catch":
				_battle_attempt_catch()
			"run":
				_resolve_battle_action("run")
		return

	if state == "attack_menu":
		var selected_attack_option: String = str(options[cursor])
		var selected_attack_lower: String = selected_attack_option.strip_edges().to_lower()
		if selected_attack_lower == "back":
			_battle_set_state("main_menu")
			return
		if selected_attack_lower == "wait":
			_battle_execute_player_wait()
			return
		var selected_skill_name: String = _battle_attack_option_to_skill_name(selected_attack_option)
		if selected_skill_name.is_empty():
			_battle_queue_messages(["Invalid attack selection."], "main_menu")
			return
		_battle_execute_player_skill(selected_skill_name)
		return

	if state == "switch_menu":
		var switchable: Array = _battle_switchable_player_indices()
		if cursor >= switchable.size():
			_battle_set_state("main_menu")
			return
		_battle_execute_player_switch(int(switchable[cursor]))
		return


func _battle_cancel_menu() -> void:
	var state: String = str(battle_context.get("state", "main_menu"))
	if state == "message":
		_battle_advance_message()
		return
	if state == "attack_menu" or state == "switch_menu":
		_battle_set_state("main_menu")
		return
	var kind: String = str(battle_context.get("kind", ""))
	if kind == "wild":
		_resolve_battle_action("run")
	else:
		_render_battle()


func _battle_active_mon(player_side: bool):
	return _battle_state.active_mon(battle_context, player_side)


func _battle_active_player_name() -> String:
	var mon = _battle_active_mon(true)
	return str(mon.name) if mon != null else "Your Aminomon"


func _battle_usable_skills_for_active_player() -> Array:
	return _battle_state.usable_skills_for_active_player(battle_context)


func _battle_attack_option_to_skill_name(option_label: String) -> String:
	var normalized: String = option_label.strip_edges().to_lower()
	if normalized == "basic attack":
		return BASIC_ATTACK_SKILL
	if BigData.SKILLS_DATA.has(normalized):
		return normalized
	return ""


func _battle_mon_has_passive_hook(mon, hook_name: String) -> bool:
	if mon == null:
		return false
	var passive_id: String = str(mon.get("passive_id")).strip_edges().to_lower()
	if passive_id.is_empty():
		passive_id = BigData.get_species_passive(str(mon.name), str(mon.element))
	var passive_data: Dictionary = BigData.PASSIVE_DATA.get(passive_id, {})
	var hooks: Array = passive_data.get("hooks", [])
	for hook_variant in hooks:
		if str(hook_variant).strip_edges().to_lower() == hook_name:
			return true
	return false


func _battle_pre_action_status_block(attacker, messages: Array) -> bool:
	if attacker == null or not attacker.has_method("status_type"):
		return false
	var status_type: String = str(attacker.status_type()).strip_edges().to_lower()
	if status_type.is_empty() or status_type == "none":
		return false
	var label: String = str(BigData.STATUS_RULES.get(status_type, {}).get("display_name", status_type.capitalize()))
	if status_type == "sleep":
		messages.append("%s is asleep and cannot move." % str(attacker.name))
		if attacker.has_method("decrement_status_turn"):
			var turns_left: int = int(attacker.decrement_status_turn())
			if turns_left <= 0:
				messages.append("%s woke up." % str(attacker.name))
		return true
	if status_type == "paralyze":
		var skip_chance: float = float(BigData.STATUS_RULES.get("paralyze", {}).get("skip_action_chance", 0.35))
		var skipped: bool = _battle_randf() < skip_chance
		if attacker.has_method("decrement_status_turn"):
			attacker.decrement_status_turn()
		if skipped:
			messages.append("%s is paralyzed and cannot act." % str(attacker.name))
			return true
		messages.append("%s fights through %s." % [str(attacker.name), label])
		return false
	return false


func _battle_apply_skill_status_effect(skill_data: Dictionary, target, messages: Array) -> void:
	if target == null or not target.has_method("set_status"):
		return
	var status_type: String = str(skill_data.get("status_type", "none")).strip_edges().to_lower()
	if status_type.is_empty() or status_type == "none":
		return
	if target.has_method("has_status") and bool(target.has_status()):
		return
	var apply_chance: float = clamp(float(skill_data.get("status_chance", 0.0)), 0.0, 1.0)
	if apply_chance <= 0.0:
		return
	if _battle_randf() > apply_chance:
		return
	var status_turns: int = int(skill_data.get("status_turns", 0))
	target.set_status(status_type, status_turns)
	var status_label: String = str(BigData.STATUS_RULES.get(status_type, {}).get("display_name", status_type.capitalize()))
	messages.append("%s is now %s." % [str(target.name), status_label])


func _battle_apply_skill_cleanse(skill_data: Dictionary, actual_target, messages: Array) -> void:
	if actual_target == null or not actual_target.has_method("status_type") or not actual_target.has_method("clear_status_state"):
		return
	var cleanse_raw = skill_data.get("cleanse", [])
	if typeof(cleanse_raw) != TYPE_ARRAY:
		return
	var cleanse_list: Array = cleanse_raw
	if cleanse_list.is_empty():
		return
	var current_status: String = str(actual_target.status_type()).strip_edges().to_lower()
	if current_status == "none" or current_status.is_empty():
		return
	for cleanse_variant in cleanse_list:
		if str(cleanse_variant).strip_edges().to_lower() != current_status:
			continue
		actual_target.clear_status_state()
		messages.append("%s's %s was cured." % [str(actual_target.name), current_status.capitalize()])
		return


func _battle_apply_end_turn_effects(messages: Array) -> void:
	var ordered_targets: Array = [_battle_active_mon(true), _battle_active_mon(false)]
	for mon_variant in ordered_targets:
		var mon = mon_variant
		if mon == null:
			continue
		if float(mon.health) <= 0.0:
			continue
		if mon.has_method("status_type"):
			var status_type: String = str(mon.status_type()).strip_edges().to_lower()
			if status_type == "burn" or status_type == "poison":
				var rule: Dictionary = BigData.STATUS_RULES.get(status_type, {})
				var ratio: float = max(0.0, float(rule.get("end_turn_damage_ratio", 0.0)))
				if ratio > 0.0:
					var max_hp: float = float(mon.get_single_stat("MAX_HEALTH"))
					var dot_damage: float = max(1.0, floor(max_hp * ratio))
					mon.health -= dot_damage
					if mon.has_method("_health_energy_limiter"):
						mon._health_energy_limiter()
					var status_label: String = str(rule.get("display_name", status_type.capitalize()))
					messages.append("%s takes %d damage from %s." % [str(mon.name), int(dot_damage), status_label])
					if mon.has_method("decrement_status_turn"):
						var turns_left: int = int(mon.decrement_status_turn())
						if turns_left <= 0:
							messages.append("%s recovered from %s." % [str(mon.name), status_label])
		var passive_id: String = str(mon.get("passive_id")).strip_edges().to_lower()
		if passive_id.is_empty():
			passive_id = BigData.get_species_passive(str(mon.name), str(mon.element))
		var passive_data: Dictionary = BigData.PASSIVE_DATA.get(passive_id, {})
		if _battle_mon_has_passive_hook(mon, "on_end_turn"):
			var heal_ratio: float = max(0.0, float(passive_data.get("heal_ratio", 0.0)))
			if heal_ratio > 0.0:
				var max_hp_passive: float = float(mon.get_single_stat("MAX_HEALTH"))
				var heal_amount: float = max(1.0, floor(max_hp_passive * heal_ratio))
				var hp_before: float = float(mon.health)
				mon.health += heal_amount
				if mon.has_method("_health_energy_limiter"):
					mon._health_energy_limiter()
				var hp_gained: int = int(round(float(mon.health) - hp_before))
				if hp_gained > 0:
					messages.append("%s's %s restored %d HP." % [
						str(mon.name),
						str(passive_data.get("display_name", "passive")),
						hp_gained
					])


func _battle_apply_switch_in_passive(mon, messages: Array) -> void:
	if mon == null or not _battle_mon_has_passive_hook(mon, "on_switch_in"):
		return
	var passive_id: String = str(mon.get("passive_id")).strip_edges().to_lower()
	if passive_id.is_empty():
		passive_id = BigData.get_species_passive(str(mon.name), str(mon.element))
	var passive_data: Dictionary = BigData.PASSIVE_DATA.get(passive_id, {})
	var ratio: float = max(0.0, float(passive_data.get("energy_restore_ratio", 0.0)))
	if ratio <= 0.0:
		return
	var max_energy: float = float(mon.get_single_stat("MAX_ENERGY"))
	var before_energy: float = float(mon.energy)
	mon.energy = min(max_energy, before_energy + floor(max_energy * ratio))
	if mon.has_method("_health_energy_limiter"):
		mon._health_energy_limiter()
	var gained: int = int(round(float(mon.energy) - before_energy))
	if gained > 0:
		messages.append("%s's %s restored %d energy." % [str(mon.name), str(passive_data.get("display_name", "passive")), gained])


func _battle_execute_player_wait() -> void:
	var player_mon = _battle_active_mon(true)
	if player_mon == null:
		_battle_queue_messages(["No active Aminomon is available."], "main_menu")
		return

	var max_energy: float = float(player_mon.get_single_stat("MAX_ENERGY"))
	var restore_amount: float = max(1.0, floor(max_energy * WAIT_ENERGY_RECOVERY_RATIO))
	var before_energy: float = float(player_mon.energy)
	player_mon.energy = min(max_energy, before_energy + restore_amount)
	if player_mon.has_method("_health_energy_limiter"):
		player_mon._health_energy_limiter()

	var gained: int = int(round(max(0.0, float(player_mon.energy) - before_energy)))
	var messages: Array = []
	if gained > 0:
		messages.append("%s waits and restores %d energy." % [str(player_mon.name), gained])
	else:
		messages.append("%s waits. Energy is already full." % str(player_mon.name))
	_battle_run_enemy_turn(messages)


func _battle_switchable_player_indices() -> Array:
	return _battle_state.switchable_player_indices(battle_context, player_monsters)


func _battle_first_alive_index(party: Dictionary) -> int:
	return _battle_state.first_alive_index(party)


func _battle_next_alive_index(party: Dictionary, exclude_index: int = -1) -> int:
	return _battle_state.next_alive_index(party, exclude_index)


func _battle_queue_messages(lines: Array, next_state_after: String = "main_menu", pending_end: Dictionary = {}) -> void:
	battle_context["message_queue"] = lines.duplicate()
	battle_context["message_index"] = 0
	battle_context["next_state_after_messages"] = next_state_after
	battle_context["pending_end"] = pending_end.duplicate(true)
	battle_context["state"] = "message"
	battle_context["cursor"] = 0
	_render_battle()


func _battle_advance_message() -> void:
	if not battle_active:
		return
	var queue: Array = battle_context.get("message_queue", [])
	var idx: int = int(battle_context.get("message_index", 0)) + 1
	if idx < queue.size():
		battle_context["message_index"] = idx
		_render_battle()
		return

	var pending_end: Dictionary = battle_context.get("pending_end", {})
	if not pending_end.is_empty():
		_end_battle(str(pending_end.get("action", "fight")), bool(pending_end.get("victory", false)))
		return

	var next_state: String = str(battle_context.get("next_state_after_messages", "main_menu"))
	_battle_set_state(next_state)


func _battle_execute_player_switch(new_index: int) -> void:
	var current_idx: int = int(battle_context.get("active_player_index", -1))
	if new_index == current_idx:
		_battle_set_state("main_menu")
		return

	battle_context["active_player_index"] = new_index
	var messages: Array = ["Go, %s!" % str(player_monsters[new_index].name)]
	_battle_apply_switch_in_passive(player_monsters[new_index], messages)
	_battle_run_enemy_turn(messages)


func _battle_execute_player_skill(skill_name: String) -> void:
	var messages: Array = []
	var player_mon = _battle_active_mon(true)
	var opp_mon = _battle_active_mon(false)
	if player_mon == null or opp_mon == null:
		_battle_queue_messages(["Battle state invalid."], "main_menu")
		return

	messages.append_array(_battle_apply_skill(skill_name, true))

	var pending_end: Dictionary = _battle_check_faints_and_progress(messages)
	if not pending_end.is_empty():
		_battle_queue_messages(messages, "main_menu", pending_end)
		return

	_battle_run_enemy_turn(messages)


func _battle_attempt_catch() -> void:
	var kind: String = str(battle_context.get("kind", ""))
	if kind != "wild":
		_battle_queue_messages(["You can only catch wild Aminomons."], "main_menu")
		return

	var wild_mon = _battle_active_mon(false)
	if wild_mon == null:
		_battle_queue_messages(["There is nothing to catch."], "main_menu")
		return

	var max_health: float = float(wild_mon.get_single_stat("MAX_HEALTH"))
	var catchable: bool = float(wild_mon.health) < max_health * 0.5
	if catchable:
		var catch_messages: Array = []
		var new_index: int = _next_party_slot_index(player_monsters) if player_monsters.size() < 6 else _next_party_slot_index(player_storage)
		if player_monsters.size() < 6:
			player_monsters[new_index] = wild_mon
			catch_messages = ["Caught %s %s!" % [_format_mon_badges(wild_mon), str(wild_mon.name)], "Added to your party.", _team_summary()]
		else:
			player_storage[new_index] = wild_mon
			catch_messages = ["Caught %s %s!" % [_format_mon_badges(wild_mon), str(wild_mon.name)], "Party full; sent to storage.", "Storage now has %d Aminomons." % player_storage.size()]
		_register_mon_collection(wild_mon)
		_add_currency_points(CATCH_REWARD_POINTS)
		catch_messages.append("Capture reward: +%d pts (Total %d)." % [CATCH_REWARD_POINTS, currency_points])
		_check_and_grant_dex_rewards(catch_messages)
		_battle_queue_messages(catch_messages, "main_menu", {"action": "catch", "victory": true})
		return

	var messages: Array = ["%s resisted capture." % str(wild_mon.name), "Lower its HP below 50%% first."]
	_battle_run_enemy_turn(messages)


func _battle_run_enemy_turn(existing_messages: Array) -> void:
	var messages: Array = existing_messages
	var enemy_mon = _battle_active_mon(false)
	var player_mon = _battle_active_mon(true)
	if enemy_mon == null or player_mon == null:
		var pending_immediate: Dictionary = _battle_check_faints_and_progress(messages)
		_battle_queue_messages(messages, "main_menu", pending_immediate)
		return

	var usable_skills: Array = enemy_mon.get_skills(false)
	var chosen_skill: String = BASIC_ATTACK_SKILL if usable_skills.is_empty() else str(usable_skills.pick_random())
	messages.append_array(_battle_apply_skill(chosen_skill, false))
	_battle_apply_end_turn_effects(messages)

	var pending_end: Dictionary = _battle_check_faints_and_progress(messages)
	_battle_queue_messages(messages, "main_menu", pending_end)


func _battle_apply_skill(skill_name: String, player_attacker: bool) -> Array:
	var messages: Array = []
	var attacker = _battle_active_mon(player_attacker)
	var target = _battle_active_mon(not player_attacker)
	var normalized_skill: String = skill_name.strip_edges().to_lower()
	if attacker == null:
		return ["No attacker available."]
	if target == null:
		return ["No target available."]
	if not BigData.SKILLS_DATA.has(normalized_skill):
		return ["Unknown skill: %s" % skill_name]
	if _battle_pre_action_status_block(attacker, messages):
		return messages

	var skill_data: Dictionary = BigData.SKILLS_DATA[normalized_skill]
	var target_side: String = str(skill_data.get("target", "opponent"))
	var actual_target = attacker if (target_side == "player") else target
	var display_skill_name: String = "Basic Attack" if normalized_skill == BASIC_ATTACK_SKILL else normalized_skill
	var effect_anim: String = str(skill_data.get("animation", ""))
	var effect_target_player_side: bool = player_attacker if (target_side == "player") else (not player_attacker)
	if not effect_anim.is_empty():
		_battle_start_effect(effect_anim, effect_target_player_side)

	var cost_value: float = float(skill_data.get("cost", 0))
	if cost_value > 0.0 and float(attacker.energy) < cost_value:
		return ["%s does not have enough energy for %s." % [str(attacker.name), display_skill_name]]

	if cost_value > 0.0 and attacker.has_method("subtract_cost"):
		attacker.subtract_cost(normalized_skill)
	var accuracy_value: float = clamp(float(skill_data.get("accuracy", 1.0)), 0.0, 1.0)
	if accuracy_value < 1.0 and _battle_randf() > accuracy_value:
		messages.append("%s used %s, but it missed." % [str(attacker.name), display_skill_name])
		return messages

	var raw_amount: float = float(attacker.get_attack_value(normalized_skill))
	var final_amount: float = raw_amount
	var attack_element: String = str(skill_data.get("element", "normal"))
	var target_element: String = str(actual_target.element)
	if _battle_mon_has_passive_hook(attacker, "on_low_hp"):
		var attacker_passive_id: String = str(attacker.get("passive_id")).strip_edges().to_lower()
		if attacker_passive_id.is_empty():
			attacker_passive_id = BigData.get_species_passive(str(attacker.name), str(attacker.element))
		var attacker_passive_data: Dictionary = BigData.PASSIVE_DATA.get(attacker_passive_id, {})
		var attacker_hp_ratio: float = float(attacker.health) / max(1.0, float(attacker.get_single_stat("MAX_HEALTH")))
		if attacker_hp_ratio <= 0.35:
			var attack_multiplier: float = max(1.0, float(attacker_passive_data.get("attack_multiplier", 1.0)))
			final_amount *= attack_multiplier
			messages.append("%s's %s boosted attack power." % [str(attacker.name), str(attacker_passive_data.get("display_name", "passive"))])

	if normalized_skill != "heal":
		if (attack_element == "fire" and target_element == "earth") or \
		   (attack_element == "water" and target_element == "fire") or \
		   (attack_element == "electric" and target_element == "water") or \
		   (attack_element == "earth" and target_element == "electric"):
			final_amount *= 2.0
			messages.append("It's super effective!")

		if (attack_element == "fire" and target_element == "water") or \
		   (attack_element == "water" and target_element == "electric") or \
		   (attack_element == "electric" and target_element == "earth") or \
		   (attack_element == "earth" and target_element == "fire"):
			final_amount *= 0.5
			messages.append("It's not very effective.")

	var actor_label: String = str(attacker.name)
	if normalized_skill == "heal":
		actual_target.health += final_amount
		if actual_target.has_method("_health_energy_limiter"):
			actual_target._health_energy_limiter()
		messages.insert(0, "%s used %s and restored %d HP." % [actor_label, display_skill_name, int(round(final_amount))])
		_battle_apply_skill_cleanse(skill_data, actual_target, messages)
	else:
		var target_defense: float = 1.0 - float(actual_target.get_single_stat("defense")) / 1000.0
		target_defense = clamp(target_defense, 0.0, 1.0)
		var damage_value: float = final_amount * target_defense
		actual_target.health -= damage_value
		if actual_target.has_method("_health_energy_limiter"):
			actual_target._health_energy_limiter()
		messages.insert(0, "%s used %s on %s for %d damage." % [
			actor_label,
			display_skill_name,
			str(actual_target.name),
			int(round(damage_value))
		])
		if _battle_mon_has_passive_hook(actual_target, "on_hit_taken"):
			var target_passive_id: String = str(actual_target.get("passive_id")).strip_edges().to_lower()
			if target_passive_id.is_empty():
				target_passive_id = BigData.get_species_passive(str(actual_target.name), str(actual_target.element))
			var target_passive_data: Dictionary = BigData.PASSIVE_DATA.get(target_passive_id, {})
			var reflect_ratio: float = max(0.0, float(target_passive_data.get("reflect_ratio", 0.0)))
			if reflect_ratio > 0.0 and attacker != actual_target and float(attacker.health) > 0.0:
				var reflect_damage: float = max(1.0, floor(damage_value * reflect_ratio))
				attacker.health -= reflect_damage
				if attacker.has_method("_health_energy_limiter"):
					attacker._health_energy_limiter()
				messages.append("%s's %s reflected %d damage." % [
					str(actual_target.name),
					str(target_passive_data.get("display_name", "passive")),
					int(reflect_damage)
				])
		_battle_apply_skill_status_effect(skill_data, actual_target, messages)

	return messages


func _battle_check_faints_and_progress(messages: Array) -> Dictionary:
	var opponent_party: Dictionary = battle_context.get("opponent_party", {})
	var player_party_ref: Dictionary = battle_context.get("player_party", {})

	var opp_active_idx: int = int(battle_context.get("active_opponent_index", -1))
	var player_active_idx: int = int(battle_context.get("active_player_index", -1))

	var opp_mon = opponent_party.get(opp_active_idx)
	if opp_mon != null and float(opp_mon.health) <= 0.0:
		messages.append("%s fainted!" % str(opp_mon.name))
		var awarded_xp: int = _award_battle_xp_for_opponent_faint(opp_mon)
		if awarded_xp > 0:
			var xp_target = _battle_active_mon(true)
			if xp_target != null:
				messages.append("%s gained %d XP." % [str(xp_target.name), awarded_xp])
		var next_opp_idx: int = _battle_next_alive_index(opponent_party, opp_active_idx)
		if next_opp_idx == -1:
			return {"action": "fight", "victory": true}
		battle_context["active_opponent_index"] = next_opp_idx
		var next_opp = opponent_party.get(next_opp_idx)
		if next_opp != null:
			messages.append("Foe sent out %s!" % str(next_opp.name))
			_battle_apply_switch_in_passive(next_opp, messages)

	var player_mon = player_party_ref.get(player_active_idx)
	if player_mon != null and float(player_mon.health) <= 0.0:
		messages.append("%s fainted!" % str(player_mon.name))
		var next_player_idx: int = _battle_next_alive_index(player_party_ref, player_active_idx)
		if next_player_idx == -1:
			return {"action": "fight", "victory": false}
		battle_context["active_player_index"] = next_player_idx
		var next_player = player_party_ref.get(next_player_idx)
		if next_player != null:
			messages.append("Go, %s!" % str(next_player.name))
			_battle_apply_switch_in_passive(next_player, messages)

	return {}


func _award_battle_xp_for_opponent_faint(defeated_mon) -> int:
	if defeated_mon == null:
		return 0
	var recipient = _battle_active_mon(true)
	if recipient == null:
		return 0
	if float(recipient.health) <= 0.0:
		return 0
	var amount: int = max(1, int(round(float(defeated_mon.level) * 100.0)))
	if recipient.has_method("add_xp"):
		recipient.add_xp(float(amount))
	return amount


func _next_party_slot_index(target_dict: Dictionary) -> int:
	var idx: int = 0
	while target_dict.has(idx):
		idx += 1
	return idx


func _reindex_monster_dict(target_dict: Dictionary) -> void:
	var keys_sorted: Array = target_dict.keys()
	keys_sorted.sort()
	var values: Array = []
	for key_variant in keys_sorted:
		values.append(target_dict.get(int(key_variant)))
	target_dict.clear()
	for i in range(values.size()):
		target_dict[i] = values[i]


func _heal_party_to_full() -> void:
	for monster_variant in player_monsters.values():
		var monster = monster_variant
		if monster == null:
			continue
		monster.health = monster.get_single_stat("MAX_HEALTH")
		monster.energy = monster.get_single_stat("MAX_ENERGY")


func _mark_npc_record_defeated(record_key: String) -> void:
	for i in range(npc_records.size()):
		var npc: Dictionary = npc_records[i]
		if str(npc.get("record_key", "")) != record_key:
			continue
		npc["defeated"] = true
		npc_records[i] = npc
		var visual_node: Node2D = npc.get("visual_node", null)
		_apply_npc_defeated_visual(visual_node)
		return


func _apply_healer() -> int:
	var count: int = 0
	for monster_variant in player_monsters.values():
		var monster = monster_variant
		if monster == null:
			continue
		monster.health = monster.get_single_stat("MAX_HEALTH")
		monster.energy = monster.get_single_stat("MAX_ENERGY")
		count += 1
	return count


func _start_fusion_sequence(events: Array, result_lines: Array) -> void:
	if events.is_empty():
		_show_dialog(result_lines)
		return
	if OS.has_feature("server") or DisplayServer.get_name() == "headless":
		_show_dialog(result_lines)
		return
	fusion_sequence_active = true
	fusion_sequence_queue = events.duplicate(true)
	fusion_sequence_result_lines = result_lines.duplicate()
	_set_player_blocked(true)
	_play_next_fusion_sequence()


func _play_next_fusion_sequence() -> void:
	if fusion_sequence_queue.is_empty():
		fusion_sequence_active = false
		_set_player_blocked(false)
		_show_dialog(fusion_sequence_result_lines)
		fusion_sequence_result_lines.clear()
		return

	var sequence_data: Dictionary = fusion_sequence_queue.pop_front()
	var start_name: String = str(sequence_data.get("from", ""))
	var end_name: String = str(sequence_data.get("to", ""))
	var is_unfusion: bool = bool(sequence_data.get("is_unfusion", false))
	var start_tex: Texture2D = _get_aminomon_battle_frame(start_name, 0, 0)
	var end_tex: Texture2D = _get_aminomon_battle_frame(end_name, 0, 0)

	if fusion_cinematic and fusion_cinematic.has_method("play_sequence"):
		fusion_cinematic.play_sequence(start_tex, end_tex, start_name, end_name, is_unfusion)
	else:
		_play_next_fusion_sequence()


func _on_fusion_sequence_finished() -> void:
	if not fusion_sequence_active:
		return
	_play_next_fusion_sequence()


func _apply_fusions() -> int:
	return _apply_fusions_with_events().size()


func _apply_fusions_with_events() -> Array:
	var indexes: Array = player_monsters.keys()
	indexes.sort()
	var events: Array = []

	for index_variant in indexes:
		var index_value: int = int(index_variant)
		var monster = player_monsters.get(index_value)
		if monster == null:
			continue
		if monster.fusion == null:
			continue
		var fusion_data: Array = monster.fusion
		if fusion_data.size() < 2:
			continue
		var target_name: String = str(fusion_data[0])
		var required_level: int = int(fusion_data[1])
		if monster.level >= required_level:
			var source_name: String = str(monster.name)
			player_monsters[index_value] = AminomonRes.new(target_name, int(monster.level), 0.0)
			events.append({
				"slot": index_value,
				"from": source_name,
				"to": target_name,
				"is_unfusion": false,
			})

	return events


func _apply_unfusions() -> int:
	return _apply_unfusions_with_events().size()


func _apply_unfusions_with_events() -> Array:
	var indexes: Array = player_monsters.keys()
	indexes.sort()
	var events: Array = []

	for index_variant in indexes:
		var index_value: int = int(index_variant)
		var monster = player_monsters.get(index_value)
		if monster == null:
			continue
		if monster.unfusion == null:
			continue
		var target_name: String = str(monster.unfusion)
		if target_name.is_empty():
			continue
		var source_name: String = str(monster.name)
		player_monsters[index_value] = AminomonRes.new(target_name, int(monster.level), 0.0)
		events.append({
			"slot": index_value,
			"from": source_name,
			"to": target_name,
			"is_unfusion": true,
		})

	return events


func _team_summary() -> String:
	var names: Array = []
	var indexes: Array = player_monsters.keys()
	indexes.sort()
	for index_variant in indexes:
		var monster = player_monsters.get(int(index_variant))
		if monster == null:
			continue
		names.append("%s Lv%d" % [str(monster.name), int(monster.level)])
	return "Party: %s" % ", ".join(PackedStringArray(names))


func _show_pause_help_dialog() -> void:
	_show_dialog([
		"Pause / Help",
		"Arrows: move | Space/E: interact | Enter/Space: advance dialog",
		"P: pause menu | D: Peptide Dex | T: Party Peptides | S: storage PC",
		"H: help dialog | F5: save | Esc: close current overlay"
	])


func _open_pause_menu() -> void:
	if battle_active or fusion_sequence_active or dialog_active or team_menu_active or storage_menu_active or peptide_dex_active:
		return
	pause_menu_active = true
	pause_menu_cursor = clamp(pause_menu_cursor, 0, PAUSE_MENU_OPTIONS.size() - 1)
	_set_player_blocked(true)
	_render_pause_menu()
	_set_status("Pause menu opened.")


func _close_pause_menu() -> void:
	pause_menu_active = false
	_render_pause_menu()
	_set_player_blocked(false)
	_set_status("Pause menu closed.")


func _pause_menu_move_cursor(delta: int) -> void:
	if not pause_menu_active:
		return
	pause_menu_cursor = posmod(pause_menu_cursor + delta, PAUSE_MENU_OPTIONS.size())
	_render_pause_menu()


func _pause_menu_confirm() -> void:
	if not pause_menu_active:
		return
	var selected: String = str(PAUSE_MENU_OPTIONS[pause_menu_cursor])
	match selected:
		"Peptide Dex":
			_close_pause_menu()
			_open_peptide_dex(true)
		"Party Peptides":
			_close_pause_menu()
			_open_team_menu(true)
		"Save":
			save_game()
			_render_pause_menu()
		"Quit":
			get_tree().quit()
		_:
			_render_pause_menu()


func _render_pause_menu() -> void:
	var box: ColorRect = get_node_or_null("UILayer/PauseBox") as ColorRect
	var label := get_node_or_null("UILayer/PauseText")
	if box == null or label == null:
		return

	if not pause_menu_active:
		box.visible = false
		_set_ui_visible(label, false)
		_set_ui_text(label, "")
		return

	var lines: Array = []
	lines.append("PAUSE MENU")
	lines.append("Up/Down: Select | Enter: Confirm | Esc: Back")
	lines.append("")
	for i in range(PAUSE_MENU_OPTIONS.size()):
		var prefix: String = ">> " if i == pause_menu_cursor else "   "
		lines.append("%s%s" % [prefix, str(PAUSE_MENU_OPTIONS[i])])
	lines.append("")
	lines.append("Tip: T opens Party Peptides, D opens Dex from world.")

	box.visible = true
	_set_ui_visible(label, true)
	_set_ui_text(label, "\n".join(PackedStringArray(lines)))


func _open_peptide_dex(from_pause: bool = false) -> void:
	if battle_active or fusion_sequence_active or dialog_active or team_menu_active or storage_menu_active or pause_menu_active:
		return
	_refresh_peptide_dex_entries()
	if peptide_dex_entries.is_empty():
		_set_status("Peptide Dex data is unavailable.")
		return
	peptide_dex_active = true
	peptide_dex_return_to_pause = from_pause
	peptide_dex_cursor = clamp(peptide_dex_cursor, 0, peptide_dex_entries.size() - 1)
	_set_player_blocked(true)
	_render_peptide_dex()
	if peptide_dex_return_to_pause:
		_set_status("Peptide Dex opened from pause.")
	else:
		_set_status("Peptide Dex opened.")


func _close_peptide_dex() -> void:
	var return_to_pause: bool = peptide_dex_return_to_pause
	peptide_dex_return_to_pause = false
	peptide_dex_active = false
	_render_peptide_dex()
	if return_to_pause:
		_open_pause_menu()
		_set_status("Returned to pause menu.")
		return
	_set_player_blocked(false)
	_set_status("Peptide Dex closed.")


func _peptide_dex_move_cursor(delta: int) -> void:
	if not peptide_dex_active or peptide_dex_entries.is_empty():
		return
	peptide_dex_cursor = posmod(peptide_dex_cursor + delta, peptide_dex_entries.size())
	_render_peptide_dex()


func _refresh_peptide_dex_entries() -> void:
	peptide_dex_entries = BigData.PEPTIDE_DEX.keys()
	peptide_dex_entries.sort_custom(Callable(self, "_peptide_dex_sorter"))


func _peptide_dex_sorter(a, b) -> bool:
	var a_name: String = str(a)
	var b_name: String = str(b)
	var a_info: Dictionary = BigData.PEPTIDE_DEX.get(a_name, {})
	var b_info: Dictionary = BigData.PEPTIDE_DEX.get(b_name, {})
	var a_id: int = int(a_info.get("id", 0))
	var b_id: int = int(b_info.get("id", 0))
	if a_id == b_id:
		return a_name < b_name
	return a_id < b_id


func _element_accent_color(element_name: String) -> Color:
	match element_name.strip_edges().to_lower():
		"fire":
			return Color(0.96, 0.39, 0.24, 1.0)
		"water":
			return Color(0.26, 0.58, 0.96, 1.0)
		"electric":
			return Color(0.99, 0.83, 0.25, 1.0)
		"earth":
			return Color(0.52, 0.76, 0.33, 1.0)
		_:
			return Color(0.76, 0.78, 0.86, 1.0)


func _color_to_hex(color_value: Color) -> String:
	var rr: int = int(round(clamp(color_value.r, 0.0, 1.0) * 255.0))
	var gg: int = int(round(clamp(color_value.g, 0.0, 1.0) * 255.0))
	var bb: int = int(round(clamp(color_value.b, 0.0, 1.0) * 255.0))
	return "#%02x%02x%02x" % [rr, gg, bb]


func _render_peptide_dex() -> void:
	var box: ColorRect = get_node_or_null("UILayer/DexBox") as ColorRect
	var label: RichTextLabel = get_node_or_null("UILayer/DexText") as RichTextLabel
	if box == null or label == null:
		return

	if not peptide_dex_active:
		box.visible = false
		_set_ui_visible(label, false)
		_set_ui_text(label, "")
		_clear_runtime_icon_layer("DexIcons")
		_render_runtime_portrait("DexPortrait", Vector2(1012.0, 132.0), "", false)
		return

	label.bbcode_enabled = true

	if peptide_dex_entries.is_empty():
		_refresh_peptide_dex_entries()

	var lines: Array = []

	if peptide_dex_entries.is_empty():
		lines.append("[center][color=#c9d5f5][b]PEPTIDE DEX[/b][/color][/center]")
		lines.append("")
		lines.append("[center][color=#f2f5ff]No entries available.[/color][/center]")
		box.color = Color(0.08, 0.1, 0.16, 0.95)
		box.visible = true
		_set_ui_visible(label, true)
		_set_ui_text(label, "\n".join(PackedStringArray(lines)))
		_clear_runtime_icon_layer("DexIcons")
		_render_runtime_portrait("DexPortrait", Vector2(1012.0, 132.0), "", false)
		return

	peptide_dex_cursor = clamp(peptide_dex_cursor, 0, peptide_dex_entries.size() - 1)
	var selected_name: String = str(peptide_dex_entries[peptide_dex_cursor])
	var selected_data: Dictionary = BigData.PEPTIDE_DEX.get(selected_name, {})
	var stats: Dictionary = selected_data.get("stats", {})
	var sci: Dictionary = selected_data.get("sci", {})
	var element: String = str(stats.get("element", "normal"))
	var accent_color: Color = _element_accent_color(element)
	var accent_hex: String = _color_to_hex(accent_color)
	var fusion_value = selected_data.get("fusion", null)
	var fusion_text: String = "None"
	if fusion_value is Array and (fusion_value as Array).size() >= 2:
		var fusion_array: Array = fusion_value as Array
		fusion_text = "%s @ Lv%d" % [str(fusion_array[0]), int(fusion_array[1])]
	var unfusion_value = selected_data.get("unfusion", null)
	var unfusion_text: String = "None" if unfusion_value == null else str(unfusion_value)

	var abilities: Dictionary = selected_data.get("ability", {})
	var ability_keys: Array = abilities.keys()
	ability_keys.sort()
	lines.append("[center][color=%s][b]PEPTIDE DEX[/b][/color][/center]" % accent_hex)
	lines.append("[center][color=#d8e4ff]Entry %d / %d   |   Up/Down browse   |   Esc close[/color][/center]" % [peptide_dex_cursor + 1, peptide_dex_entries.size()])
	lines.append("")
	lines.append("[color=%s][b]#%03d  %s[/b][/color]" % [accent_hex, int(selected_data.get("id", 0)), selected_name])
	lines.append("[color=#dbe5ff]Element:[/color] [color=%s]%s[/color]" % [accent_hex, element])
	lines.append("[color=#dbe5ff]Base Stats[/color]")
	lines.append("[color=#f3f7ff]HP %d   EN %d   ATK %d   DEF %d   SPD %d   REC %d[/color]" % [
		int(stats.get("MAX_HEALTH", 0)),
		int(stats.get("MAX_ENERGY", 0)),
		int(stats.get("attack", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("speed", 0)),
		int(stats.get("recovery", 0))
	])
	lines.append("[color=#dbe5ff]Bio:[/color] [color=#f3f7ff]%s / %s   Charged: %s   Polar: %s[/color]" % [
		str(sci.get("three_letter", "-")),
		str(sci.get("single_letter", "-")),
		"Yes" if bool(sci.get("charged", false)) else "No",
		"Yes" if bool(sci.get("polar", false)) else "No"
	])
	lines.append("[color=#dbe5ff]Fusion:[/color] [color=#f3f7ff]%s[/color]" % fusion_text)
	lines.append("[color=#dbe5ff]Unfusion:[/color] [color=#f3f7ff]%s[/color]" % unfusion_text)
	var desc_text: String = str(sci.get("desc", "")).strip_edges()
	if not desc_text.is_empty():
		lines.append("[color=#dbe5ff]Notes:[/color] [color=#f3f7ff]%s[/color]" % desc_text)
	lines.append("")
	lines.append("[color=#dbe5ff]Abilities[/color]")
	if ability_keys.is_empty():
		lines.append("[color=#f3f7ff]None[/color]")
	else:
		for ability_key in ability_keys:
			var ability_name: String = str(abilities.get(ability_key, "")).strip_edges()
			if ability_name.is_empty():
				continue
			lines.append("[color=#f3f7ff]Lv%-2s  %s[/color]" % [str(ability_key), ability_name])

	box.color = Color(
		clamp(0.06 + accent_color.r * 0.14, 0.0, 1.0),
		clamp(0.08 + accent_color.g * 0.14, 0.0, 1.0),
		clamp(0.1 + accent_color.b * 0.14, 0.0, 1.0),
		0.95
	)
	box.visible = true
	_set_ui_visible(label, true)
	_set_ui_text(label, "\n".join(PackedStringArray(lines)))
	_clear_runtime_icon_layer("DexIcons")
	_render_runtime_mon_sprite(
		"DexPortrait",
		Vector2(866.0, 166.0),
		selected_name,
		true,
		Vector2(304.0, 304.0)
	)


func _open_team_menu(from_pause: bool = false) -> void:
	if battle_active or fusion_sequence_active or dialog_active or storage_menu_active or pause_menu_active or peptide_dex_active:
		return
	team_menu_active = true
	team_menu_return_to_pause = from_pause
	team_menu_state = TEAM_MENU_STATE_GRID
	team_menu_move_source_row = -1
	team_menu_action_cursor = 0
	team_menu_cursor = clamp(team_menu_cursor, 0, TEAM_MENU_GRID_SLOTS - 1)
	_set_player_blocked(true)
	_render_team_menu()
	if team_menu_return_to_pause:
		_set_status("Party manager opened from pause. Select a slot and press Enter.")
	else:
		_set_status("Party manager opened. Select a slot and press Enter.")


func _close_team_menu() -> void:
	var return_to_pause: bool = team_menu_return_to_pause
	team_menu_return_to_pause = false
	team_menu_active = false
	team_menu_state = TEAM_MENU_STATE_GRID
	team_menu_move_source_row = -1
	team_menu_action_cursor = 0
	_render_team_menu()
	if return_to_pause:
		_open_pause_menu()
		_set_status("Returned to pause menu.")
		return
	_set_player_blocked(false)
	_set_status("Closed party manager.")


func _team_menu_back() -> void:
	if not team_menu_active:
		return
	match team_menu_state:
		TEAM_MENU_STATE_GRID:
			_close_team_menu()
			return
		TEAM_MENU_STATE_ACTION_MENU:
			team_menu_state = TEAM_MENU_STATE_GRID
			team_menu_action_cursor = 0
			_set_status("Returned to party grid.")
		TEAM_MENU_STATE_MOVE_PICK:
			team_menu_state = TEAM_MENU_STATE_GRID
			team_menu_move_source_row = -1
			_set_status("Move cancelled.")
		TEAM_MENU_STATE_INSPECT:
			team_menu_state = TEAM_MENU_STATE_ACTION_MENU
			_set_status("Returned to action menu.")
		_:
			team_menu_state = TEAM_MENU_STATE_GRID
	_render_team_menu()


func _team_menu_move_cursor(delta: int, horizontal: bool = false) -> void:
	if not team_menu_active:
		return
	if team_menu_state == TEAM_MENU_STATE_ACTION_MENU:
		if TEAM_MENU_ACTION_OPTIONS.is_empty():
			return
		team_menu_action_cursor = posmod(team_menu_action_cursor + delta, TEAM_MENU_ACTION_OPTIONS.size())
		_render_team_menu()
		return
	var row: int = int(team_menu_cursor / TEAM_MENU_GRID_COLS)
	var col: int = int(posmod(team_menu_cursor, TEAM_MENU_GRID_COLS))
	if horizontal:
		col = posmod(col + delta, TEAM_MENU_GRID_COLS)
	else:
		row = posmod(row + delta, TEAM_MENU_GRID_ROWS)
	team_menu_cursor = clamp(row * TEAM_MENU_GRID_COLS + col, 0, TEAM_MENU_GRID_SLOTS - 1)
	_render_team_menu()


func _team_menu_toggle_mode() -> void:
	if not team_menu_active:
		return
	if team_menu_state == TEAM_MENU_STATE_MOVE_PICK:
		team_menu_state = TEAM_MENU_STATE_GRID
		team_menu_move_source_row = -1
		_set_status("Move mode disabled.")
	else:
		var keys_sorted_toggle: Array = _team_menu_sorted_keys()
		if keys_sorted_toggle.is_empty():
			_set_status("No party Aminomons available.")
			_render_team_menu()
			return
		if team_menu_cursor >= keys_sorted_toggle.size():
			team_menu_cursor = clamp(keys_sorted_toggle.size() - 1, 0, TEAM_MENU_GRID_SLOTS - 1)
		team_menu_state = TEAM_MENU_STATE_MOVE_PICK
		team_menu_move_source_row = team_menu_cursor
		_set_status("Move mode enabled. Select destination and press Enter.")
	_render_team_menu()


func _team_menu_sorted_keys() -> Array:
	var keys_sorted: Array = player_monsters.keys()
	keys_sorted.sort()
	return keys_sorted


func _team_menu_mon_for_slot(slot_index: int, keys_sorted: Array):
	if slot_index < 0 or slot_index >= keys_sorted.size():
		return null
	return player_monsters.get(int(keys_sorted[slot_index]), null)


func _team_menu_slot_summary(slot_index: int, keys_sorted: Array) -> String:
	var mon = _team_menu_mon_for_slot(slot_index, keys_sorted)
	if mon == null:
		return "(empty)"
	return "#%d %s Lv%d" % [int(keys_sorted[slot_index]), str(mon.name), int(mon.level)]


func _team_menu_confirm() -> void:
	if not team_menu_active:
		return
	var keys_sorted: Array = _team_menu_sorted_keys()
	if keys_sorted.is_empty():
		_set_status("No party Aminomons available.")
		_render_team_menu()
		return
	team_menu_cursor = clamp(team_menu_cursor, 0, TEAM_MENU_GRID_SLOTS - 1)
	match team_menu_state:
		TEAM_MENU_STATE_GRID:
			if team_menu_cursor >= keys_sorted.size():
				_set_status("That grid slot is empty.")
				_render_team_menu()
				return
			team_menu_state = TEAM_MENU_STATE_ACTION_MENU
			team_menu_action_cursor = 0
			var selected_mon = _team_menu_mon_for_slot(team_menu_cursor, keys_sorted)
			_set_status("Actions for %s." % str(selected_mon.name))
		TEAM_MENU_STATE_ACTION_MENU:
			if team_menu_cursor >= keys_sorted.size():
				team_menu_state = TEAM_MENU_STATE_GRID
				_set_status("Selected slot is empty.")
				_render_team_menu()
				return
			var action: String = str(TEAM_MENU_ACTION_OPTIONS[clamp(team_menu_action_cursor, 0, TEAM_MENU_ACTION_OPTIONS.size() - 1)])
			match action:
				"Move":
					team_menu_state = TEAM_MENU_STATE_MOVE_PICK
					team_menu_move_source_row = team_menu_cursor
					_set_status("Move started. Choose destination slot and press Enter.")
				"Inspect":
					team_menu_state = TEAM_MENU_STATE_INSPECT
					_set_status("Inspect window opened.")
				"Give Item":
					_set_status("Give Item is not implemented yet.")
				_:
					team_menu_state = TEAM_MENU_STATE_GRID
					team_menu_action_cursor = 0
					_set_status("Cancelled action menu.")
		TEAM_MENU_STATE_MOVE_PICK:
			if team_menu_move_source_row < 0 or team_menu_move_source_row >= keys_sorted.size():
				team_menu_move_source_row = -1
				team_menu_state = TEAM_MENU_STATE_GRID
				_set_status("Move source is invalid. Move cancelled.")
				_render_team_menu()
				return
			if team_menu_cursor >= keys_sorted.size():
				_set_status("Choose a filled destination slot.")
				_render_team_menu()
				return
			if team_menu_cursor == team_menu_move_source_row:
				_set_status("Choose a different destination slot.")
				_render_team_menu()
				return
			var key_a: int = int(keys_sorted[team_menu_move_source_row])
			var key_b: int = int(keys_sorted[team_menu_cursor])
			var mon_a = player_monsters.get(key_a)
			var mon_b = player_monsters.get(key_b)
			player_monsters[key_a] = mon_b
			player_monsters[key_b] = mon_a
			team_menu_move_source_row = -1
			team_menu_state = TEAM_MENU_STATE_GRID
			_set_status("Swapped party slots %d and %d." % [key_a, key_b])
		TEAM_MENU_STATE_INSPECT:
			team_menu_state = TEAM_MENU_STATE_ACTION_MENU
			_set_status("Returned to action menu.")
		_:
			team_menu_state = TEAM_MENU_STATE_GRID
	_render_team_menu()


func _render_team_menu() -> void:
	var box: ColorRect = get_node_or_null("UILayer/TeamBox") as ColorRect
	var label: RichTextLabel = get_node_or_null("UILayer/TeamText") as RichTextLabel
	if box == null or label == null:
		return

	if not team_menu_active:
		box.visible = false
		_set_ui_visible(label, false)
		_set_ui_text(label, "")
		_clear_runtime_icon_layer("TeamIcons")
		_render_runtime_portrait("TeamPortrait", Vector2(984.0, 132.0), "", false)
		return

	var keys_sorted: Array = _team_menu_sorted_keys()
	team_menu_cursor = clamp(team_menu_cursor, 0, TEAM_MENU_GRID_SLOTS - 1)
	if team_menu_move_source_row >= keys_sorted.size():
		team_menu_move_source_row = -1

	var lines: Array = []
	lines.append("PARTY PEPTIDES")
	match team_menu_state:
		TEAM_MENU_STATE_GRID:
			lines.append("Grid: Arrows move | Enter select | Esc close")
		TEAM_MENU_STATE_ACTION_MENU:
			lines.append("Actions: Up/Down choose | Enter confirm | Esc back")
		TEAM_MENU_STATE_MOVE_PICK:
			lines.append("Move: Arrows destination | Enter swap | Esc cancel")
		TEAM_MENU_STATE_INSPECT:
			lines.append("Inspect: Arrows browse | Enter/Esc back")
		_:
			lines.append("Arrows move | Enter select | Esc close")
	lines.append("Party size: %d / 6" % keys_sorted.size())
	lines.append("Party view is icon-first.")

	var focused_mon = _team_menu_mon_for_slot(team_menu_cursor, keys_sorted)
	var portrait_name: String = ""
	if focused_mon != null:
		portrait_name = str(focused_mon.name)

	lines.append("")
	if focused_mon == null:
		lines.append("Selected slot: empty")
	else:
		lines.append("Selected: %s Lv%d" % [str(focused_mon.name), int(focused_mon.level)])
		lines.append("HP %d / %d | EN %d / %d" % [
			int(round(float(focused_mon.health))),
			int(round(float(focused_mon.get_single_stat("MAX_HEALTH")))),
			int(round(float(focused_mon.energy))),
			int(round(float(focused_mon.get_single_stat("MAX_ENERGY"))))
		])

	if team_menu_state == TEAM_MENU_STATE_ACTION_MENU:
		lines.append("")
		lines.append("Actions:")
		for i in range(TEAM_MENU_ACTION_OPTIONS.size()):
			var prefix: String = ">> " if i == team_menu_action_cursor else "   "
			lines.append("%s%s" % [prefix, str(TEAM_MENU_ACTION_OPTIONS[i])])
	elif team_menu_state == TEAM_MENU_STATE_INSPECT:
		lines.append("")
		lines.append("INSPECT WINDOW (monsAminos sprite)")
		if focused_mon == null:
			lines.append("No Aminomon in this slot.")
		else:
			lines.append("Element: %s" % str(focused_mon.element))
			lines.append("ATK %d  DEF %d  SPD %d  REC %d" % [
				int(round(float(focused_mon.get_single_stat("attack")))),
				int(round(float(focused_mon.get_single_stat("defense")))),
				int(round(float(focused_mon.get_single_stat("speed")))),
				int(round(float(focused_mon.get_single_stat("recovery"))))
			])
			lines.append("XP %.0f | Next Lv at %.0f" % [float(focused_mon.xp), float(focused_mon.level_up)])
			lines.append("Skills: %s" % _team_menu_skill_summary(str(focused_mon.name)))
	elif team_menu_state == TEAM_MENU_STATE_MOVE_PICK and team_menu_move_source_row >= 0 and team_menu_move_source_row < keys_sorted.size():
		lines.append("")
		lines.append("Moving from slot %d" % [team_menu_move_source_row + 1])

	var team_icon_names: Array = []
	for slot in range(TEAM_MENU_GRID_SLOTS):
		var mon = _team_menu_mon_for_slot(slot, keys_sorted)
		team_icon_names.append("" if mon == null else str(mon.name))
	box.color = Color(0.05, 0.08, 0.11, 0.94)
	label.bbcode_enabled = false
	_render_runtime_icon_grid(
		"TeamIcons",
		team_icon_names,
		team_menu_cursor,
		TEAM_GRID_ORIGIN,
		TEAM_MENU_GRID_COLS,
		TEAM_GRID_SPACING,
		18.0,
		team_menu_move_source_row if team_menu_state == TEAM_MENU_STATE_MOVE_PICK else -1,
		MENU_LARGE_ICON_SIZE
	)
	if team_menu_state == TEAM_MENU_STATE_INSPECT and not portrait_name.is_empty():
		_render_runtime_mon_sprite("TeamPortrait", Vector2(824.0, 178.0), portrait_name, true, Vector2(304.0, 304.0))
	else:
		_render_runtime_portrait("TeamPortrait", Vector2(984.0, 132.0), "", false)

	box.visible = true
	_set_ui_visible(label, true)
	_set_ui_text(label, "\n".join(PackedStringArray(lines)))


func _team_menu_skill_summary(mon_name: String) -> String:
	var mon_data: Dictionary = BigData.PEPTIDE_DEX.get(mon_name, {})
	var abilities: Dictionary = mon_data.get("ability", {})
	var ability_keys: Array = abilities.keys()
	ability_keys.sort()
	var names: Array = []
	for ability_key in ability_keys:
		var ability_name: String = str(abilities.get(ability_key, "")).strip_edges()
		if not ability_name.is_empty():
			names.append(ability_name)
	return "None" if names.is_empty() else ", ".join(PackedStringArray(names))


func _show_team_dialog() -> void:
	var lines: Array = ["Party (%d)" % player_monsters.size()]
	var indexes: Array = player_monsters.keys()
	indexes.sort()
	for index_variant in indexes:
		var monster = player_monsters.get(int(index_variant))
		if monster == null:
			continue
		lines.append(_monster_detail_line(int(index_variant), monster))
	if lines.size() == 1:
		lines.append("No Aminomons in party.")
	_show_dialog(lines)


func _show_storage_dialog() -> void:
	var lines: Array = ["Storage (%d)" % player_storage.size()]
	var indexes: Array = _storage_sorted_keys(player_storage)
	for index_variant in indexes:
		var monster = player_storage.get(int(index_variant))
		if monster == null:
			continue
		lines.append(_monster_detail_line(int(index_variant), monster))
	if lines.size() == 1:
		lines.append("Storage is empty.")
	_show_dialog(lines)


func _storage_sorted_keys(source_dict: Dictionary) -> Array:
	var keys_sorted: Array = source_dict.keys()
	keys_sorted.sort_custom(Callable(self, "_storage_key_sorter").bind(source_dict))
	return keys_sorted


func _storage_key_sorter(a, b, source_dict: Dictionary) -> bool:
	var a_key: int = int(a)
	var b_key: int = int(b)
	var a_mon = source_dict.get(a_key, null)
	var b_mon = source_dict.get(b_key, null)
	if a_mon == null and b_mon == null:
		return a_key < b_key
	if a_mon == null:
		return false
	if b_mon == null:
		return true
	var a_name: String = str(a_mon.name).to_lower()
	var b_name: String = str(b_mon.name).to_lower()
	if a_name == b_name:
		var a_level: int = int(a_mon.level)
		var b_level: int = int(b_mon.level)
		if a_level == b_level:
			return a_key < b_key
		return a_level < b_level
	return a_name < b_name


func _open_storage_menu() -> void:
	if battle_active or fusion_sequence_active or dialog_active or team_menu_active or pause_menu_active or peptide_dex_active:
		return
	storage_menu_active = true
	storage_menu_side = "party" if player_monsters.size() > 0 else "storage"
	storage_menu_party_cursor = clamp(storage_menu_party_cursor, 0, max(0, player_monsters.size() - 1))
	storage_menu_storage_cursor = clamp(storage_menu_storage_cursor, 0, max(0, _storage_sorted_keys(player_storage).size() - 1))
	_set_player_blocked(true)
	_render_storage_menu()
	_set_status("Storage PC opened. Left=Party, Right=Storage, Enter transfers.")


func _close_storage_menu() -> void:
	storage_menu_active = false
	_render_storage_menu()
	_set_player_blocked(false)
	_set_status("Closed storage PC. Party: %d | Storage: %d" % [player_monsters.size(), player_storage.size()])


func _storage_menu_set_side(side: String) -> void:
	if not storage_menu_active:
		return
	if side != "party" and side != "storage":
		return
	storage_menu_side = side
	_render_storage_menu()


func _storage_menu_move_cursor(delta: int) -> void:
	if not storage_menu_active:
		return
	if storage_menu_side == "party":
		var party_count: int = player_monsters.size()
		if party_count <= 0:
			return
		storage_menu_party_cursor = posmod(storage_menu_party_cursor + delta, party_count)
	else:
		var storage_count: int = _storage_sorted_keys(player_storage).size()
		if storage_count <= 0:
			return
		storage_menu_storage_cursor = posmod(storage_menu_storage_cursor + delta, storage_count)
	_render_storage_menu()


func _storage_menu_confirm() -> void:
	if not storage_menu_active:
		return

	var party_keys: Array = player_monsters.keys()
	party_keys.sort()
	var storage_keys: Array = _storage_sorted_keys(player_storage)

	if storage_menu_side == "party":
		if party_keys.is_empty():
			_set_status("No party Aminomons to move.")
			_render_storage_menu()
			return
		if player_monsters.size() <= 1:
			_set_status("You must keep at least 1 Aminomon in your party.")
			_render_storage_menu()
			return
		var party_slot: int = int(party_keys[clamp(storage_menu_party_cursor, 0, party_keys.size() - 1)])
		var mon = player_monsters.get(party_slot, null)
		if mon == null:
			_render_storage_menu()
			return
		player_monsters.erase(party_slot)
		player_storage[_next_party_slot_index(player_storage)] = mon
		_reindex_monster_dict(player_monsters)
		_reindex_monster_dict(player_storage)
		storage_menu_party_cursor = clamp(storage_menu_party_cursor, 0, max(0, player_monsters.size() - 1))
		storage_menu_storage_cursor = clamp(storage_menu_storage_cursor, 0, max(0, _storage_sorted_keys(player_storage).size() - 1))
		_set_status("Sent %s to storage." % str(mon.name))
		_render_storage_menu()
		return

	if storage_keys.is_empty():
		_set_status("Storage is empty.")
		_render_storage_menu()
		return
	if player_monsters.size() >= 6:
		_set_status("Party is full (6). Move one to storage first.")
		_render_storage_menu()
		return

	var storage_slot: int = int(storage_keys[clamp(storage_menu_storage_cursor, 0, storage_keys.size() - 1)])
	var stored_mon = player_storage.get(storage_slot, null)
	if stored_mon == null:
		_render_storage_menu()
		return
	player_storage.erase(storage_slot)
	player_monsters[_next_party_slot_index(player_monsters)] = stored_mon
	_reindex_monster_dict(player_monsters)
	_reindex_monster_dict(player_storage)
	storage_menu_party_cursor = clamp(storage_menu_party_cursor, 0, max(0, player_monsters.size() - 1))
	storage_menu_storage_cursor = clamp(storage_menu_storage_cursor, 0, max(0, _storage_sorted_keys(player_storage).size() - 1))
	_set_status("Withdrew %s to party." % str(stored_mon.name))
	_render_storage_menu()


func _render_storage_menu() -> void:
	var box: ColorRect = get_node_or_null("UILayer/StorageBox") as ColorRect
	var label: RichTextLabel = get_node_or_null("UILayer/StorageText") as RichTextLabel
	if box == null or label == null:
		return

	if not storage_menu_active:
		box.visible = false
		_set_ui_visible(label, false)
		_set_ui_text(label, "")
		_clear_runtime_icon_layer("StoragePartyIcons")
		_clear_runtime_icon_layer("StorageStorageIcons")
		_render_runtime_portrait("StoragePortrait", Vector2(1012.0, 132.0), "", false)
		return

	var party_keys: Array = player_monsters.keys()
	party_keys.sort()
	var storage_keys: Array = _storage_sorted_keys(player_storage)
	storage_menu_party_cursor = clamp(storage_menu_party_cursor, 0, max(0, party_keys.size() - 1))
	storage_menu_storage_cursor = clamp(storage_menu_storage_cursor, 0, max(0, storage_keys.size() - 1))

	var lines: Array = []
	var party_icon_names: Array = []
	for slot in range(6):
		var mon = null
		if slot < party_keys.size():
			mon = player_monsters.get(int(party_keys[slot]))
		party_icon_names.append("" if mon == null else str(mon.name))
	var storage_start: int = 0
	if storage_keys.size() > STORAGE_STORAGE_VISIBLE_SLOTS:
		var half_window: int = int(STORAGE_STORAGE_VISIBLE_SLOTS / 2)
		storage_start = clamp(storage_menu_storage_cursor - half_window, 0, storage_keys.size() - STORAGE_STORAGE_VISIBLE_SLOTS)
	var storage_end: int = min(storage_keys.size(), storage_start + STORAGE_STORAGE_VISIBLE_SLOTS)
	var storage_icon_names: Array = []
	for i in range(storage_start, storage_end):
		var storage_mon = player_storage.get(int(storage_keys[i]), null)
		storage_icon_names.append("" if storage_mon == null else str(storage_mon.name))

	lines.append("STORAGE PC")
	lines.append("Left Party | Right Storage | Up/Down Move | Enter Transfer | Esc Close")
	lines.append("Party %d / 6 | Storage %d | Active Panel: %s" % [
		player_monsters.size(),
		player_storage.size(),
		"PARTY" if storage_menu_side == "party" else "STORAGE"
	])
	lines.append("Icons-only transfer view.")
	if storage_keys.size() > STORAGE_STORAGE_VISIBLE_SLOTS:
		lines.append("Storage window: %d-%d of %d" % [storage_start + 1, storage_end, storage_keys.size()])
	lines.append("")
	if storage_menu_side == "party" and not party_keys.is_empty():
		var p_index: int = clamp(storage_menu_party_cursor, 0, party_keys.size() - 1)
		var p_key: int = int(party_keys[p_index])
		var p_focus = player_monsters.get(p_key, null)
		if p_focus != null:
			lines.append("Selected Party #%d: %s Lv%d" % [p_key, str(p_focus.name), int(p_focus.level)])
	elif storage_menu_side == "storage" and not storage_keys.is_empty():
		var s_index: int = clamp(storage_menu_storage_cursor, 0, storage_keys.size() - 1)
		var s_key: int = int(storage_keys[s_index])
		var s_focus = player_storage.get(s_key, null)
		if s_focus != null:
			lines.append("Selected Storage #%d: %s Lv%d" % [s_key, str(s_focus.name), int(s_focus.level)])

	var party_selected_index: int = storage_menu_party_cursor if storage_menu_side == "party" else -1
	var storage_selected_local: int = -1
	if storage_menu_side == "storage" and not storage_keys.is_empty():
		storage_selected_local = clamp(storage_menu_storage_cursor - storage_start, 0, max(0, storage_icon_names.size() - 1))

	box.color = Color(0.04, 0.07, 0.11, 0.94)
	label.bbcode_enabled = false
	_render_runtime_icon_grid(
		"StoragePartyIcons",
		party_icon_names,
		party_selected_index,
		STORAGE_PARTY_ORIGIN,
		STORAGE_PARTY_COLUMNS,
		Vector2(142.0, 108.0),
		14.0,
		-1,
		MENU_LARGE_ICON_SIZE
	)
	_render_runtime_icon_grid(
		"StorageStorageIcons",
		storage_icon_names,
		storage_selected_local,
		STORAGE_STORAGE_ORIGIN,
		STORAGE_STORAGE_COLUMNS,
		Vector2(128.0, 98.0),
		10.0,
		-1,
		MENU_LARGE_ICON_SIZE
	)
	_render_runtime_portrait("StoragePortrait", Vector2(1012.0, 132.0), "", false)

	box.visible = true
	_set_ui_visible(label, true)
	_set_ui_text(label, "\n".join(PackedStringArray(lines)))


func _monster_detail_line(slot_index: int, monster) -> String:
	var hp_now: int = int(round(float(monster.health)))
	var hp_max: int = int(round(monster.get_single_stat("MAX_HEALTH")))
	var en_now: int = int(round(float(monster.energy)))
	var en_max: int = int(round(monster.get_single_stat("MAX_ENERGY")))
	return "#%d %s Lv%d | HP %d/%d | EN %d/%d | XP %.0f" % [
		slot_index,
		str(monster.name),
		int(monster.level),
		hp_now,
		hp_max,
		en_now,
		en_max,
		float(monster.xp)
	]


func _check_chemical_spills() -> void:
	if player == null or chemical_spill_zones.is_empty():
		return

	var now_msec: int = Time.get_ticks_msec()
	if now_msec < wild_encounter_cooldown_until_msec:
		return

	var player_rect: Rect2 = _get_player_footprint_rect()
	var active_index: int = -1
	for i in range(chemical_spill_zones.size()):
		var spill_zone: Dictionary = chemical_spill_zones[i]
		var spill_rect: Rect2 = spill_zone.get("rect", Rect2())
		if spill_rect.intersects(player_rect):
			active_index = i
			break

	if active_index == -1:
		pending_spill_index = -1
		pending_spill_encounter_at_msec = 0
		return

	if pending_spill_index != active_index:
		pending_spill_index = active_index
		pending_spill_encounter_at_msec = now_msec + randi_range(800, 2500)
		return

	if pending_spill_encounter_at_msec > 0 and now_msec >= pending_spill_encounter_at_msec:
		_trigger_wild_encounter(chemical_spill_zones[active_index])
		pending_spill_index = -1
		pending_spill_encounter_at_msec = 0
		wild_encounter_cooldown_until_msec = now_msec + 1800


func _trigger_wild_encounter(spill_zone: Dictionary) -> void:
	var aminos: Array = spill_zone.get("aminos", [])
	var picked_name: String = "alanine"
	if not aminos.is_empty():
		picked_name = str(aminos.pick_random())

	var base_level: int = int(spill_zone.get("level", 1))
	var wild_level: int = max(1, base_level + _battle_randi_range(-2, 2))
	if _has_milestone("lab_badge"):
		wild_level += POST_BOSS_WILD_LEVEL_BONUS
	var rarity_variant: String = _roll_rarity_variant()
	var trait_id: String = _roll_trait_id()
	var element_name: String = str(BigData.PEPTIDE_DEX.get(picked_name, {}).get("stats", {}).get("element", "normal"))
	var passive_id: String = BigData.get_species_passive(picked_name, element_name)
	var classroom: String = str(spill_zone.get("classroom", "labfight"))
	_start_battle({
		"kind": "wild",
		"opponent_name": picked_name,
		"opponent_level": wild_level,
		"opponent_rarity_variant": rarity_variant,
		"opponent_trait_id": trait_id,
		"opponent_passive_id": passive_id,
		"classroom": classroom,
	})


func _build_marker_debug(parsed_map: Dictionary) -> void:
	var objects: Array = _get_object_group(parsed_map, "GameObjects")
	for object_variant in objects:
		var object_data: Dictionary = object_variant
		var object_name: String = str(object_data.get("name", ""))
		var props: Dictionary = object_data.get("properties", {})
		var pos: Vector2 = Vector2(float(object_data.get("x", 0.0)), float(object_data.get("y", 0.0)))

		if object_name == "Player":
			var spawn_name: String = str(props.get("pos", ""))
			_add_debug_point(pos, Color(0.95, 0.92, 0.35, 0.85))
			_add_debug_label("Spawn: %s" % spawn_name, pos + Vector2(8, -8))
		elif object_name == "Character":
			var char_id: String = str(props.get("character_id", "npc"))
			_add_debug_point(pos, Color(0.45, 1.0, 0.55, 0.85))
			_add_debug_label(char_id, pos + Vector2(8, -8))

	var spills: Array = _get_object_group(parsed_map, "ChemicalSpills")
	for spill_variant in spills:
		var spill: Dictionary = spill_variant
		var spill_rect: Rect2 = _tmx_object_rect(spill, true)
		_add_debug_rect(spill_rect, Color(0.1, 0.95, 0.55, 0.18), map_debug_root, "Spill")


func _place_player_from_map(parsed_map: Dictionary, spawn_tag: String) -> void:
	if player == null:
		return

	var game_objects: Array = _get_object_group(parsed_map, "GameObjects")
	var fallback_position: Vector2 = Vector2(64, 64)
	var found_spawn: bool = false

	for object_variant in game_objects:
		var object_data: Dictionary = object_variant
		if str(object_data.get("name", "")) != "Player":
			continue

		var props: Dictionary = object_data.get("properties", {})
		var pos_name: String = str(props.get("pos", ""))
		var candidate_position: Vector2 = Vector2(
			float(object_data.get("x", 0.0)),
			float(object_data.get("y", 0.0))
		)

		if fallback_position == Vector2(64, 64):
			fallback_position = candidate_position

		if pos_name == spawn_tag:
			player.global_position = candidate_position
			if player.has_method("set_facing"):
				player.set_facing(str(props.get("direction", "down")))
			found_spawn = true
			break

	if not found_spawn:
		player.global_position = fallback_position


func _update_camera_limits() -> void:
	if player == null:
		return
	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return

	camera.limit_enabled = true
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(current_map_pixel_size.x)
	camera.limit_bottom = int(current_map_pixel_size.y)


func _get_object_group(parsed_map: Dictionary, group_name: String) -> Array:
	var groups: Dictionary = parsed_map.get("objectgroups", {})
	return groups.get(group_name, [])


func _tmx_object_rect(object_data: Dictionary, tile_object_uses_bottom_y: bool = false) -> Rect2:
	var width_value: float = max(float(object_data.get("width", 0.0)), 1.0)
	var height_value: float = max(float(object_data.get("height", 0.0)), 1.0)
	var x_value: float = float(object_data.get("x", 0.0))
	var y_value: float = float(object_data.get("y", 0.0))
	var has_gid: bool = int(object_data.get("gid", 0)) != 0
	if tile_object_uses_bottom_y and has_gid:
		y_value -= height_value
	return Rect2(x_value, y_value, width_value, height_value)


func _get_player_footprint_rect() -> Rect2:
	if player == null:
		return Rect2()

	var collision_shape: CollisionShape2D = player.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision_shape and collision_shape.shape is RectangleShape2D:
		var rect_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
		var size_value: Vector2 = rect_shape.size
		var center_pos: Vector2 = collision_shape.global_position
		return Rect2(center_pos - size_value * 0.5, size_value)

	return Rect2(player.global_position - Vector2(8, 4), Vector2(16, 8))


func _check_transitions() -> void:
	if player == null:
		return
	if transition_zones.is_empty():
		return

	var now_msec: int = Time.get_ticks_msec()
	if now_msec < transition_cooldown_until_msec:
		return

	var player_rect: Rect2 = _get_player_footprint_rect()
	for zone_variant in transition_zones:
		var zone: Dictionary = zone_variant
		var zone_rect: Rect2 = zone.get("rect", Rect2())
		if zone_rect.intersects(player_rect):
			var target_map: String = str(zone.get("target", ""))
			var target_spawn: String = str(zone.get("pos", "world"))
			if target_map.is_empty():
				return
			var required_milestone: String = str(MAP_MILESTONE_REQUIREMENTS.get(target_map, ""))
			if not required_milestone.is_empty() and not _has_milestone(required_milestone):
				_set_status("Route to %s is locked. Objective: %s" % [target_map, str(objective_tracker.get("next", "Defeat milestone trainer."))])
				return
			transition_cooldown_until_msec = now_msec + 500
			_trigger_transition_fade()
			_load_map(target_map, target_spawn)
			_set_status("Transitioned to %s (%s). F5 saves." % [target_map, target_spawn])
			return


func _validate_ui_layer() -> void:
	if not has_node("UILayer"):
		push_error("World scene is missing UILayer. Instance res://scenes/WorldUI.tscn in World.tscn.")


func _update_map_labels() -> void:
	var map_label: Label = get_node_or_null("UILayer/MapInfo") as Label
	if map_label:
		map_label.text = "Map: %s | Spawn: %s | Size: %dx%d" % [
			current_map_name,
			current_spawn_tag,
			int(current_map_pixel_size.x),
			int(current_map_pixel_size.y)
		]


func _set_status(message: String) -> void:
	var status_label: Label = get_node_or_null("UILayer/Status") as Label
	if status_label:
		status_label.text = message


func _set_hint(message: String) -> void:
	var hint_label: Label = get_node_or_null("UILayer/Hint") as Label
	if hint_label:
		hint_label.text = message


func _set_ui_text(node: Node, value: String) -> void:
	if node == null:
		return
	if node is Label:
		(node as Label).text = value
		return
	if node is RichTextLabel:
		(node as RichTextLabel).text = value


func _set_ui_visible(node: Node, value: bool) -> void:
	if node is CanvasItem:
		(node as CanvasItem).visible = value


func _show_dialog(lines: Array) -> void:
	_start_dialog(lines)


func _start_dialog(lines: Array, on_close: Callable = Callable()) -> void:
	var sanitized: Array = []
	for line_variant in lines:
		var line_text: String = str(line_variant).strip_edges()
		if not line_text.is_empty():
			sanitized.append(line_text)

	if sanitized.is_empty():
		_close_dialog()
		return

	dialog_lines = sanitized
	dialog_index = 0
	dialog_active = true
	dialog_on_close = on_close
	_set_player_blocked(true)
	_render_dialog()


func _advance_dialog() -> void:
	if not dialog_active:
		return

	dialog_index += 1
	if dialog_index >= dialog_lines.size():
		_close_dialog()
		return

	_render_dialog()


func _close_dialog() -> void:
	var callback: Callable = dialog_on_close
	dialog_active = false
	dialog_lines.clear()
	dialog_index = 0
	dialog_on_close = Callable()
	_set_player_blocked(false)
	_render_dialog()
	if callback.is_valid():
		callback.call()


func _render_dialog() -> void:
	var box: ColorRect = get_node_or_null("UILayer/DialogBox") as ColorRect
	var label: Label = get_node_or_null("UILayer/DialogText") as Label

	var dialog_message: String = ""
	if dialog_active and dialog_index >= 0 and dialog_index < dialog_lines.size():
		dialog_message = "%s\n[Space/Enter] %d/%d" % [
			str(dialog_lines[dialog_index]),
			dialog_index + 1,
			dialog_lines.size()
		]

	if box:
		box.visible = not dialog_message.is_empty()
	if label:
		label.text = dialog_message
		label.visible = not dialog_message.is_empty()


func _update_interaction_hint() -> void:
	if battle_active:
		_set_interaction_notice(false)
		var battle_state: String = str(battle_context.get("state", "main_menu"))
		if battle_state == "message":
			_set_hint("Battle: Space/Enter continue")
		elif battle_state == "attack_menu":
			_set_hint("Battle: Up/Down choose attack/wait | Enter confirm | Esc back")
		elif battle_state == "switch_menu":
			_set_hint("Battle: Up/Down choose switch | Enter confirm | Esc back")
		else:
			var kind: String = str(battle_context.get("kind", "battle"))
			if kind == "wild":
				_set_hint("Battle: Fight / Switch / Catch / Run")
			else:
				_set_hint("Trainer battle: Fight / Switch")
		return

	if fusion_sequence_active:
		_set_interaction_notice(false)
		_set_hint("Fusion: Space/Enter to skip animation")
		return

	if pause_menu_active:
		_set_interaction_notice(false)
		_set_hint("Pause: Up/Down choose | Enter select | Esc close")
		return

	if peptide_dex_active:
		_set_interaction_notice(false)
		_set_hint("Peptide Dex: Up/Down browse | Esc close")
		return

	if team_menu_active:
		_set_interaction_notice(false)
		match team_menu_state:
			TEAM_MENU_STATE_GRID:
				_set_hint("Party Grid: Arrows move | Enter actions | Esc close")
			TEAM_MENU_STATE_ACTION_MENU:
				_set_hint("Party Actions: Up/Down choose | Enter confirm | Esc back")
			TEAM_MENU_STATE_MOVE_PICK:
				_set_hint("Party Move: Arrows destination | Enter swap | Esc cancel")
			TEAM_MENU_STATE_INSPECT:
				_set_hint("Party Inspect: Arrows browse | Enter/Esc back")
			_:
				_set_hint("Party: Arrows move | Enter select | Esc close")
		return

	if storage_menu_active:
		_set_interaction_notice(false)
		_set_hint("Storage: Left Party | Right Storage | Up/Down select | Enter transfer | Esc close")
		return

	if dialog_active:
		_set_interaction_notice(false)
		_set_hint("Space/Enter: continue dialog")
		return

	var npc: Dictionary = _get_nearby_npc_for_interaction()
	if npc.is_empty():
		_set_interaction_notice(false)
		_set_hint("Arrows move | Space interact | Stand in spills for encounters | P pause | F5 save")
		return

	_set_interaction_notice(true)
	var npc_id: String = str(npc.get("id", "npc"))
	_set_hint("Space: interact with %s" % npc_id)


func _set_player_blocked(value: bool) -> void:
	if player == null:
		return
	if player.has_method("set_blocked"):
		player.set_blocked(value)


func _npc_record_key(npc_id: String, position_value: Vector2) -> String:
	return "%s|%s|%d|%d" % [current_map_name, npc_id, int(round(position_value.x)), int(round(position_value.y))]


func _npc_is_defeated(npc: Dictionary) -> bool:
	var npc_id: String = str(npc.get("id", "npc"))
	if rematch_unlocked and not _is_special_npc(npc_id):
		return false
	var record_key: String = str(npc.get("record_key", ""))
	if record_key.is_empty():
		return bool(npc.get("defeated", false))
	return bool(trainer_battle_state.get(record_key, bool(npc.get("defeated", false))))


func _is_special_npc(npc_id: String) -> bool:
	return npc_id == "healer" or npc_id == "fuser" or npc_id == "unfuser" or npc_id == "storage"


func _add_debug_rect(rect: Rect2, color: Color, parent_node: Node, prefix: String) -> void:
	var poly := Polygon2D.new()
	poly.name = "%sRect" % prefix
	poly.color = color
	poly.polygon = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	parent_node.add_child(poly)

	var outline := Line2D.new()
	outline.name = "%sOutline" % prefix
	outline.width = 2.0
	outline.default_color = Color(color.r, color.g, color.b, 0.75)
	outline.closed = true
	outline.points = PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	parent_node.add_child(outline)


func _add_debug_point(point: Vector2, color: Color) -> void:
	var marker := Polygon2D.new()
	marker.name = "DebugPoint"
	marker.color = color
	marker.polygon = PackedVector2Array([
		point + Vector2(0, -6),
		point + Vector2(6, 0),
		point + Vector2(0, 6),
		point + Vector2(-6, 0),
	])
	map_marker_root.add_child(marker)


func _add_debug_label(text_value: String, position_value: Vector2) -> void:
	var label := Label.new()
	label.name = "DebugLabel"
	label.text = text_value
	label.position = position_value
	label.add_theme_font_size_override("font_size", 11)
	map_marker_root.add_child(label)

