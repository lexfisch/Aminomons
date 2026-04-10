# Aminomon Project Architecture and File-Interaction Outline

Last verified: 2026-04-10 (America/Chicago)

This document explains how the project works end-to-end in Godot, with:
- Deep file-by-file coverage for the active runtime (`Aminomon/`).
- Grouped appendix coverage for legacy runtime/code (`Code/`, `Archive/`) and asset trees.
- Dual explanation layers throughout:
  - Beginner lens: what this means in plain Godot/game terms.
  - Advanced lens: implementation and architecture details.
- Explicit interaction mapping: who loads/calls/references whom, and when in lifecycle.

## 1) Project Topology

### Beginner lens
Think of this repo as one active game plus older history:
- Active game: `Aminomon/` (this is what actually runs in Godot now).
- Old pygame game: `Code/` (reference only, not runtime).
- Old Godot port snapshot: `Archive/GodotProject_legacy/` (reference only).
- Root `images/` and `data/` are older duplicated assets; active runtime uses `Aminomon/images` and `Aminomon/data`.

### Advanced lens
Tracked top-level footprint (`git ls-files` summary):
- `Aminomon`: 422 tracked files (canonical runtime assets, scenes, scripts, data, configs).
- `Code`: 33 tracked files (deprecated pygame implementation).
- `Archive`: 12 tracked files (legacy Godot snapshot).
- Root `images`: 190 tracked files (legacy duplicate assets).
- Root `data`: 9 tracked files (legacy duplicate map/save/tileset files).
- Ops/docs/config: `.github`, `tools`, `README.md`, `.vscode`, root git config files.

Runtime ownership model:
- Canonical runtime data/logic paths are all `res://...` under `Aminomon/`.
- Save data is written to `user://save` at runtime by `World.gd`.
- CLI smoke and CI run via root `tools/` and `.github/workflows/godot-port-ci.yml`.

## 2) Godot Runtime Boot Flow

### Beginner lens
Startup flow:
1. Godot starts `Main.tscn` (set in `project.godot`).
2. You see `StartScreen`.
3. When you choose New/Load, `Main.gd` hides `StartScreen`, shows `World`, and calls `world.start_game(new_game)`.
4. `World.gd` loads player team/storage, loads map data (`.tmx`), and then runs the world loop each frame.

### Advanced lens
Detailed flow and lifecycle boundaries:
1. `project.godot`:
   - `application/run/main_scene = res://scenes/Main.tscn`.
2. `Main.tscn` root `Node2D` with `Main.gd`:
   - `_ready`: `StartScreen.visible = true`, `World.visible = false`.
   - `_process`: polls `StartScreen.game_active`.
3. `StartScreen.gd`:
   - `_unhandled_input`: updates `selection_index`, sets `game_active/new_game`.
4. Handoff:
   - `Main.gd` detects `start_screen.game_active`, copies `new_game`, calls `world.start_game(new_game)`.
5. `World.gd` setup:
   - `_ready` prebuilds runtime nodes and first map parse.
   - `start_game` resets runtime state, loads/creates party and storage, loads world state, loads map.
6. Frame update:
   - `Main.gd._process` delegates per-frame runtime to `world.update_world(delta)`.
7. Input routing:
   - `StartScreen.gd._unhandled_input` handles menu before game starts.
   - `World.gd._unhandled_input` handles gameplay menus/modes after handoff.
   - `Player.gd._physics_process` handles movement vector and collision motion.

## 3) Scene Tree + Script Binding Map

### Main runtime tree (active)
```text
Main.tscn (Node2D) [scripts/Main.gd]
|- StartScreen (Control instance) [scenes/StartScreen.tscn -> scripts/StartScreen.gd]
\- World (Node2D instance, initially hidden) [scenes/World.tscn -> scripts/World.gd]
   |- Player (CharacterBody2D instance) [scenes/Player.tscn -> scripts/Player.gd]
   |- UILayer (CanvasLayer instance) [scenes/WorldUI.tscn]
   \- FusionCinematic (CanvasLayer instance) [scenes/FusionCinematic.tscn -> scripts/FusionCinematic.gd]
```

### Scene/script binding table
| Scene | Root Node Type | Script | Main runtime responsibility |
|---|---|---|---|
| `Aminomon/scenes/Main.tscn` | `Node2D` | `Aminomon/scripts/Main.gd` | Start screen to world boot handoff and world frame delegation. |
| `Aminomon/scenes/StartScreen.tscn` | `Control` | `Aminomon/scripts/StartScreen.gd` | New/Load selection input and mode flagging. |
| `Aminomon/scenes/World.tscn` | `Node2D` | `Aminomon/scripts/World.gd` | Core game orchestrator (maps, NPCs, battles, UI, saves, progression). |
| `Aminomon/scenes/Player.tscn` | `CharacterBody2D` | `Aminomon/scripts/Player.gd` | Player movement, facing, sprite/collision/camera creation. |
| `Aminomon/scenes/WorldUI.tscn` | `CanvasLayer` | none | Static UI node scaffold consumed by `World.gd`. |
| `Aminomon/scenes/FusionCinematic.tscn` | `CanvasLayer` | `Aminomon/scripts/FusionCinematic.gd` | Fusion/unfusion overlay animation and completion signaling. |

## 4) Runtime File Index

This section explicitly documents all 30 tracked runtime text/config files under `Aminomon/`:
- 11 scripts (`.gd`)
- 6 scenes (`.tscn`)
- 5 maps (`.tmx`)
- 2 tilesets (`.tsx`)
- 6 runtime config/metadata files (`.godot`, `.cfg`, `.svg`, dotfiles)

### 4.1 Runtime Config and Metadata Files

#### `Aminomon/.editorconfig`
- Role/Purpose: Repository text encoding policy (`utf-8`), root marker.
- Godot type and lifecycle hooks: N/A (editor/tooling config).
- Inputs/Dependencies: Used by editors/IDEs.
- Outputs/Side effects: Normalizes text editing behavior.
- Interaction links: Indirectly affects all edited text files in `Aminomon/`.

#### `Aminomon/.gitattributes`
- Role/Purpose: Git EOL normalization for runtime subtree.
- Godot type and lifecycle hooks: N/A.
- Inputs/Dependencies: Git client behavior.
- Outputs/Side effects: Text files committed with normalized line endings.
- Interaction links: All tracked runtime text files.

#### `Aminomon/.gitignore`
- Role/Purpose: Ignore Godot local state (`.godot/`, Android build dirs).
- Godot type and lifecycle hooks: N/A.
- Inputs/Dependencies: Git status/indexing.
- Outputs/Side effects: Keeps generated editor files untracked.
- Interaction links: Runtime-generated local files.

#### `Aminomon/project.godot`
- Role/Purpose: Engine project entry/config (`run/main_scene`, window size, renderer).
- Godot type and lifecycle hooks: Godot engine project manifest.
- Inputs/Dependencies: Read by Godot at startup.
- Outputs/Side effects: Launches `Main.tscn`; sets render/display defaults.
- Interaction links: Entry point into all scene/script runtime logic.

#### `Aminomon/export_presets.cfg`
- Role/Purpose: Export preset definition (`Windows Desktop`).
- Godot type and lifecycle hooks: Export pipeline config.
- Inputs/Dependencies: Godot export runner, templates.
- Outputs/Side effects: Produces `build/Aminomon.exe` on export.
- Interaction links: Used by CI export sanity and local export checks.

#### `Aminomon/icon.svg`
- Role/Purpose: Project icon resource.
- Godot type and lifecycle hooks: Static asset referenced by project config.
- Inputs/Dependencies: `project.godot` `config/icon`.
- Outputs/Side effects: App icon in editor/runtime metadata.
- Interaction links: `project.godot`.

### 4.2 Data and Map Files

#### `Aminomon/data/tileset/indoor_tiles.tsx`
- Role/Purpose: Tiled tileset metadata for indoor tile atlas (`64x64`, 90 tiles).
- Godot type and lifecycle hooks: Tiled external tileset descriptor.
- Inputs/Dependencies: `indoor.png` source metadata mapping.
- Outputs/Side effects: Authoring-time tileset description.
- Interaction links: TMX maps reference this logically; runtime uses `World.gd` constants and sprite slicing rules aligned to it.

#### `Aminomon/data/tileset/spriteSheet_tiledLiquids_32x32.tsx`
- Role/Purpose: Tiled tileset metadata for liquid tiles (`32x32`, 48 tiles).
- Godot type and lifecycle hooks: Tiled external tileset descriptor.
- Inputs/Dependencies: liquid spritesheet metadata.
- Outputs/Side effects: Authoring-time mapping for spill/liquid tiles.
- Interaction links: TMX maps + `World.gd` GID and atlas slicing logic.

#### `Aminomon/data/mapfile/firstlab.tmx`
- Role/Purpose: Start hub map with special NPCs and first progression routes.
- Godot type and lifecycle hooks: Parsed by `World.gd` XML TMX parser.
- Inputs/Dependencies: Terrain layers; object groups (`GameObjects`, `Collisions`, `ChemicalSpills`, `Transition`).
- Outputs/Side effects: Spawns player/NPCs, collision geometry, wild spill zones, transitions to `biochem1`/`biology1`.
- Interaction links: `World.gd::_parse_tmx_map`, `_build_*`, `_place_player_from_map`, `_check_transitions`.

#### `Aminomon/data/mapfile/biochem1.tmx`
- Role/Purpose: First chemistry route map.
- Godot type and lifecycle hooks: TMX map.
- Inputs/Dependencies: Trainer NPCs `bc1`, `bc2`; transitions to `firstlab` and `biochem2`; chemistry spill species set.
- Outputs/Side effects: Runtime map content and encounter population for this route.
- Interaction links: `World.gd` map loader and progression gate checks.

#### `Aminomon/data/mapfile/biochem2.tmx`
- Role/Purpose: Advanced chemistry route map.
- Godot type and lifecycle hooks: TMX map.
- Inputs/Dependencies: Trainer NPCs `bc3`, `bc4`, `bc5`; transition back to `biochem1`; large spill density.
- Outputs/Side effects: Late chemistry encounters and trainer progression path.
- Interaction links: `World.gd`, gated by milestone (`lab_badge`) for route access.

#### `Aminomon/data/mapfile/biology1.tmx`
- Role/Purpose: First biology route map.
- Godot type and lifecycle hooks: TMX map.
- Inputs/Dependencies: Trainer NPCs `b1`, `b2`; transitions to `firstlab` and `biology2`.
- Outputs/Side effects: Runtime map content and biology encounter pool.
- Interaction links: `World.gd` map parse/build/transition subsystem.

#### `Aminomon/data/mapfile/biology2.tmx`
- Role/Purpose: Advanced biology route map.
- Godot type and lifecycle hooks: TMX map.
- Inputs/Dependencies: Trainer NPCs `b3`, `b4`, `b5`; transition to `biology1`; large spill density.
- Outputs/Side effects: Late biology progression and encounter population.
- Interaction links: `World.gd`, gated by milestone (`lab_badge`) for route access.

### 4.3 Scene Files (`.tscn`)

#### `Aminomon/scenes/Main.tscn`
- Role/Purpose: Runtime root scene with start menu and world instance.
- Godot type and lifecycle hooks: `Node2D` scene instantiated by engine as main scene.
- Inputs/Dependencies: `Main.gd`, `StartScreen.tscn`, `World.tscn`.
- Outputs/Side effects: Owns high-level visibility and runtime delegation boundaries.
- Interaction links: `project.godot` -> `Main.tscn` -> `Main.gd`.

#### `Aminomon/scenes/StartScreen.tscn`
- Role/Purpose: Main menu UI for New/Load selection.
- Godot type and lifecycle hooks: `Control` scene.
- Inputs/Dependencies: `StartScreen.gd`, background texture.
- Outputs/Side effects: Emits mode via script vars (`game_active`, `new_game`) polled by `Main.gd`.
- Interaction links: Child of `Main.tscn`; consumed by `Main.gd`.

#### `Aminomon/scenes/World.tscn`
- Role/Purpose: Core world runtime composition scene.
- Godot type and lifecycle hooks: `Node2D` scene.
- Inputs/Dependencies: `World.gd`, `Player.tscn`, `WorldUI.tscn`, `FusionCinematic.tscn`.
- Outputs/Side effects: Hosts all map runtime nodes, player actor, UI, cinematic overlay.
- Interaction links: Child of `Main.tscn`; primary runtime logic in `World.gd`.

#### `Aminomon/scenes/Player.tscn`
- Role/Purpose: Minimal player actor scene shell.
- Godot type and lifecycle hooks: `CharacterBody2D` scene.
- Inputs/Dependencies: `Player.gd`.
- Outputs/Side effects: Movement/collision/camera behavior and player facing state.
- Interaction links: Instanced by `World.tscn`, controlled by `World.gd`.

#### `Aminomon/scenes/WorldUI.tscn`
- Role/Purpose: UI node scaffold for overlays, battle HUD, menu text, fade layer.
- Godot type and lifecycle hooks: `CanvasLayer`.
- Inputs/Dependencies: Referenced node names expected by `World.gd`.
- Outputs/Side effects: Rendering anchor points for dialog, battle, pause, dex, team, storage.
- Interaction links: `World.gd` reads/updates named nodes each mode transition.

#### `Aminomon/scenes/FusionCinematic.tscn`
- Role/Purpose: Fusion animation overlay scene.
- Godot type and lifecycle hooks: `CanvasLayer` with scripted animation and signal.
- Inputs/Dependencies: `FusionCinematic.gd`.
- Outputs/Side effects: Plays fusion/unfusion sequence and signals completion.
- Interaction links: `World.gd` connects to `sequence_finished`.

### 4.4 Script Files (`.gd`)

#### `Aminomon/scripts/Main.gd`
- Role/Purpose: Boot coordinator between menu and world.
- Godot type and lifecycle hooks: `Node2D`; hooks: `_ready`, `_process`.
- Inputs/Dependencies: Child nodes `$StartScreen`, `$World`; checks `world.start_game`/`world.update_world`.
- Outputs/Side effects: Toggles scene visibility and launches world state.
- Interaction links: Attached to `Main.tscn`; consumes `StartScreen.gd`; invokes `World.gd`.

#### `Aminomon/scripts/StartScreen.gd`
- Role/Purpose: Start menu input/controller logic.
- Godot type and lifecycle hooks: `Control`; hooks: `_ready`, `_unhandled_input`.
- Inputs/Dependencies: Label nodes `OptionNew`, `OptionLoad`; keyboard events.
- Outputs/Side effects: Sets `game_active` and `new_game`; updates label styles.
- Interaction links: Attached to `StartScreen.tscn`; polled by `Main.gd`.

#### `Aminomon/scripts/World.gd`
- Role/Purpose: Main runtime orchestrator for world state, maps, interactions, battle, UI, saves, progression.
- Godot type and lifecycle hooks: `Node2D`; hooks: `_ready`, `_unhandled_input`; runtime entry methods `start_game`, `update_world`.
- Inputs/Dependencies:
  - Preloads: `Settings.gd`, `BigBigData.gd`, `Aminomon.gd`, `BattleState.gd`.
  - Scene children: `$Player`, `$FusionCinematic`, `UILayer/*` nodes.
  - Data assets: `res://data/mapfile/*.tmx`, `res://images/...`.
  - Runtime files: `user://save/player_aminos.csv`, `player_storage.csv`, `world_state.json`.
- Outputs/Side effects:
  - Builds runtime map nodes, collisions, NPCs, spills.
  - Mutates game state dicts (party/storage/battle/progression/objectives).
  - Opens/closes overlays and updates UI text/icons/portraits.
  - Writes and reads save data under `user://save`.
  - Starts/ends battles and map transitions.
- Interaction links:
  - Called by `Main.gd`.
  - Calls into `BattleState.gd` helpers.
  - Instantiates/updates `Aminomon` resources.
  - Uses `BigBigData` constants/rules for stats/skills/trainers/progression.
  - Interacts with `Player.gd` and `FusionCinematic.gd`.

#### `Aminomon/scripts/Player.gd`
- Role/Purpose: Player movement and sprite assembly from sheet assets.
- Godot type and lifecycle hooks: `CharacterBody2D`; hooks: `_ready`, `_physics_process`.
- Inputs/Dependencies: Input actions (`ui_*`), `res://images/characters/player.png`.
- Outputs/Side effects: Updates velocity, facing direction, animations, collision and camera nodes.
- Interaction links: Instanced by `Player.tscn`; controlled and blocked/unblocked by `World.gd`.

#### `Aminomon/scripts/FusionCinematic.gd`
- Role/Purpose: Animated fusion/unfusion overlay sequence controller.
- Godot type and lifecycle hooks: `CanvasLayer`; signal `sequence_finished`; hooks: `_ready`, `_process`.
- Inputs/Dependencies: Called with start/end textures and names by `World.gd`.
- Outputs/Side effects: Renders pulse/fade transition and emits completion signal.
- Interaction links: Attached to `FusionCinematic.tscn`; `World.gd` connects and drives it.

#### `Aminomon/scripts/Aminomon.gd`
- Role/Purpose: Aminomon domain model resource (stats, XP, skills, metadata/status/passive state).
- Godot type and lifecycle hooks: `Resource` (`class_name Aminomon`); `_init`.
- Inputs/Dependencies: `BigBigData.PEPTIDE_DEX`, traits/status/passive tables, skill data.
- Outputs/Side effects: Computes derived stats/skills; mutates health/energy/xp/level/status metadata.
- Interaction links: Instantiated by `World.gd` and `BattleState.gd`; heavily exercised by `SmokeTest.gd`.

#### `Aminomon/scripts/BigBigData.gd`
- Role/Purpose: Canonical static game data store.
- Godot type and lifecycle hooks: `Resource` (`class_name BigBigData`); static helper `get_species_passive`.
- Inputs/Dependencies: None (constant data source).
- Outputs/Side effects: Provides dex/trainer/skill/rarity/trait/status/passive/reward data lookups.
- Interaction links: Consumed by `Aminomon.gd`, `World.gd`, `BattleState.gd`, `SmokeTest.gd`.

#### `Aminomon/scripts/BattleState.gd`
- Role/Purpose: Battle state machine helper module (pure-ish context and menu utilities).
- Godot type and lifecycle hooks: `RefCounted` (`class_name BattleState`).
- Inputs/Dependencies: Battle context dictionaries, player party, `Aminomon` script class.
- Outputs/Side effects: Builds opponent/runtime contexts; computes options/cursor/state transitions.
- Interaction links: Owned and called by `World.gd`; smoke-tested indirectly and directly via world behavior.

#### `Aminomon/scripts/Settings.gd`
- Role/Purpose: Shared constants for dimensions, colors, layer conventions, menu icon mapping.
- Godot type and lifecycle hooks: `Resource` (`class_name Settings`).
- Inputs/Dependencies: None.
- Outputs/Side effects: Constant lookup for scripts.
- Interaction links: Preloaded in `World.gd`; legacy parity with earlier architecture values.

#### `Aminomon/scripts/Timer.gd`
- Role/Purpose: Small reusable timer resource abstraction (`TimerGD`) based on `Time.get_ticks_msec`.
- Godot type and lifecycle hooks: `Resource` (`class_name TimerGD`), `_init`, `update`.
- Inputs/Dependencies: Callable callback and duration.
- Outputs/Side effects: Invokes callback when elapsed; supports repeat mode.
- Interaction links: Utility script (legacy parity); not central in current `World.gd` runtime loop.

#### `Aminomon/scripts/SmokeTest.gd`
- Role/Purpose: Headless migration smoke/integration test harness.
- Godot type and lifecycle hooks: `SceneTree`; `_init` -> deferred `_run`.
- Inputs/Dependencies: Loads `World.tscn`; calls world internals/methods and validates UI/state behavior.
- Outputs/Side effects:
  - Prints `[PASS]/[FAIL]` checks.
  - Exits process with code `0` on success, `1` on failure.
  - Optionally writes probe file to `user://save` for save/write checks.
- Interaction links: Invoked by `tools/ci/run_godot_checks.ps1`, local headless runs, and GitHub Actions.

### 4.5 Coverage Checklist (runtime text/config files)

Verified against `git ls-files "Aminomon/*"` for text/config/runtime files:
- `Aminomon/.editorconfig`
- `Aminomon/.gitattributes`
- `Aminomon/.gitignore`
- `Aminomon/project.godot`
- `Aminomon/export_presets.cfg`
- `Aminomon/icon.svg`
- `Aminomon/scenes/FusionCinematic.tscn`
- `Aminomon/scenes/Main.tscn`
- `Aminomon/scenes/Player.tscn`
- `Aminomon/scenes/StartScreen.tscn`
- `Aminomon/scenes/World.tscn`
- `Aminomon/scenes/WorldUI.tscn`
- `Aminomon/scripts/Aminomon.gd`
- `Aminomon/scripts/BattleState.gd`
- `Aminomon/scripts/BigBigData.gd`
- `Aminomon/scripts/FusionCinematic.gd`
- `Aminomon/scripts/Main.gd`
- `Aminomon/scripts/Player.gd`
- `Aminomon/scripts/Settings.gd`
- `Aminomon/scripts/SmokeTest.gd`
- `Aminomon/scripts/StartScreen.gd`
- `Aminomon/scripts/Timer.gd`
- `Aminomon/scripts/World.gd`
- `Aminomon/data/mapfile/firstlab.tmx`
- `Aminomon/data/mapfile/biochem1.tmx`
- `Aminomon/data/mapfile/biochem2.tmx`
- `Aminomon/data/mapfile/biology1.tmx`
- `Aminomon/data/mapfile/biology2.tmx`
- `Aminomon/data/tileset/indoor_tiles.tsx`
- `Aminomon/data/tileset/spriteSheet_tiledLiquids_32x32.tsx`

Excluded from per-file template by scope (still covered in Asset Appendix):
- Binary runtime assets (`.png`, `.ttf`).
- Godot import sidecars and identifiers (`.import`, `.uid`) as generated/asset-adjacent metadata.

### 4.6 Runtime Operations Files (Tools and CI)

#### `tools/run_godot.ps1`
- Role/Purpose: Local crash-safe launcher wrapper for Godot runtime/editor/headless script execution.
- Godot type and lifecycle hooks: External PowerShell tool.
- Inputs/Dependencies: Local Godot executable path, project path, user-data dir, optional script/headless/editor flags.
- Outputs/Side effects: Runs Godot with stable `--user-data-dir` and `--log-file`.
- Interaction links: Used for local execution and smoke script runs.

#### `tools/ci/run_godot_checks.ps1`
- Role/Purpose: CI/local validation script for smoke tests and optional Windows export sanity.
- Godot type and lifecycle hooks: External PowerShell tool.
- Inputs/Dependencies: Godot executable, project path, writable user-data dir, optional export templates.
- Outputs/Side effects: Runs headless smoke; can run export and fail non-zero on error markers.
- Interaction links: Manual local checks; mirrors CI behavior.

#### `.github/workflows/godot-port-ci.yml`
- Role/Purpose: GitHub Actions pipeline for active Godot runtime path changes.
- Godot type and lifecycle hooks: CI workflow.
- Inputs/Dependencies: `Aminomon/**` changes; Linux Godot CI container; Windows export templates download.
- Outputs/Side effects: Runs smoke tests and Windows export sanity.
- Interaction links: Executes `SmokeTest.gd` headlessly in CI; validates export artifacts.

#### `README.md`
- Role/Purpose: Runtime policy and command surface documentation.
- Godot type and lifecycle hooks: Project documentation.
- Inputs/Dependencies: Human/operator guidance.
- Outputs/Side effects: Defines canonical runtime and approved validation commands.
- Interaction links: Points to `tools/ci/run_godot_checks.ps1` and `tools/run_godot.ps1`.

## 5) System Interaction Maps (Deep Dives)

### 5.1 Main boot handoff: `Main.tscn` + `Main.gd`

```text
project.godot -> Main.tscn(Main.gd)
Main._ready:
  StartScreen visible
  World hidden
Main._process:
  if StartScreen.game_active:
    copy StartScreen.new_game
    hide StartScreen
    show World
    call World.start_game(new_game)
  else:
    call World.update_world(delta)
```

Beginner lens:
- `Main.gd` is the traffic controller that waits at menu, then starts game world.

Advanced lens:
- This is a polling handoff (no custom signal), so `Main._process` checks menu flags each frame.
- `World` is always pre-instanced in scene tree; activation is visibility + `start_game` state reset, not scene replacement.

### 5.2 `World.gd` orchestration deep dive

Core orchestration layers:
1. Startup and state reset:
   - `_ready` builds runtime roots, validates UI layer, preloads first map.
   - `start_game` resets modal states, RNG, progression dicts, party/storage, map load.
2. Map runtime pipeline:
   - `_parse_tmx_map` -> `_validate_parsed_map` -> `_build_floor_visual` / `_build_collision_bodies` / `_build_npc_runtime` / `_build_chemical_spill_runtime` -> `_place_player_from_map`.
3. Interaction and dialog:
   - `_try_interact` -> `_get_nearby_npc_for_interaction` -> special NPC or trainer flow.
4. Battle state machine:
   - `_start_battle`, `_battle_set_state`, `_battle_current_menu_options`, `_battle_confirm_current_selection`, `_battle_apply_skill`, `_battle_check_faints_and_progress`, `_end_battle`.
5. Menu overlays:
   - Pause, dex, team, storage are explicit modal states (`*_active` flags) with renderer functions.
6. Save/load and progression:
   - CSV party/storage + JSON world state; milestones unlock gated routes and rematches.

Beginner lens:
- `World.gd` is effectively the game engine for gameplay rules in this project.

Advanced lens:
- Single-script orchestration favors rapid feature parity over subsystem decomposition.
- Internal APIs (`_`-prefixed helpers) are intentionally reused by smoke tests to validate gameplay branches quickly.

### 5.3 Data model coupling: `Aminomon.gd` + `BigBigData.gd`

Interaction model:
- `Aminomon._init` reads species stats/abilities/fusion from `BigBigData.PEPTIDE_DEX`.
- Runtime stat calculations pull trait multipliers from `BigBigData.TRAIT_DATA`.
- Status lifecycle uses `BigBigData.STATUS_RULES`.
- Passive identity defaults from `BigBigData.get_species_passive`.
- Battle effects read `BigBigData.SKILLS_DATA`, passives, and elemental metadata.

Beginner lens:
- `BigBigData.gd` is the encyclopedia; `Aminomon.gd` is one actual creature instance using that encyclopedia.

Advanced lens:
- This is data-driven combat behavior; adding a species/skill/trait/status/passive mostly means data edits, not algorithm rewrites.

### 5.4 `BattleState.gd` helpers as a world battle adapter

Delegated responsibilities from `World.gd`:
- Opponent party construction (`build_opponent_party`).
- Runtime context initialization (`build_runtime_context`).
- Active mon lookup and status line rendering.
- Menu prompt/options generation and cursor movement.
- Alive-index utility functions for switch/faint flow.

Beginner lens:
- `World.gd` still owns battle execution, but asks `BattleState.gd` for shared menu/state math.

Advanced lens:
- This separation reduces boilerplate and keeps context mutation semantics centralized for menu navigation and roster traversal.

### 5.5 `SmokeTest.gd` coverage map and validation intent

Major test blocks and intent:
- `_run_world_tests`: world startup, map parsing, collision queries, transition and spill encounter behavior, special NPC flows.
- `_run_collection_meta_tests`: deterministic rarity rolls, catch metadata persistence, save/load metadata retention.
- `_run_status_accuracy_and_passive_tests`: deterministic accuracy with seed, status DoT and ordering, passive hooks.
- `_run_progression_loop_tests`: milestone-gated transitions and post-boss loop state.
- `_run_catch_flow_tests`: fail/succeed capture logic and party-vs-storage routing.
- `_run_battle_menu_flow_tests`: menu navigation, switch/run constraints trainer vs wild.
- `_run_wait_and_basic_attack_tests`: zero-energy behavior (Basic Attack, Wait recovery, enemy fallback turns).
- `_run_battle_xp_tests`: XP gain after opponent faint and battle-end correctness.
- `_run_storage_menu_tests`: transfer constraints, ordering rules, cursor-to-item mapping.
- `_run_team_menu_tests`: action menu, inspect, placeholder action stability, move/swap correctness.

Beginner lens:
- This is a big automated playthrough validator that checks many game loops without opening the full game window.

Advanced lens:
- Tests are integration-heavy and use internal method access for deterministic coverage of branch-heavy gameplay logic.

## 6) CLI Test and CI Execution Path

### Command path

Local scripted check:
```powershell
powershell -ExecutionPolicy Bypass -File tools/ci/run_godot_checks.ps1
```

Direct headless smoke:
```powershell
& "c:\School\Aminomon\tools\godot\Godot_v4.5.1-stable_win64.exe" `
  --headless `
  --path "c:\School\Aminomon\Aminomon" `
  --user-data-dir "c:\School\Aminomon\Aminomon\.godot_ci_userdata_manual" `
  --log-file "c:\School\Aminomon\Aminomon\.godot_ci_userdata_manual\smoke.log" `
  -s res://scripts/SmokeTest.gd
```

CI path:
- `.github/workflows/godot-port-ci.yml`
  - Job 1: Linux container smoke (`godot --headless ... -s res://scripts/SmokeTest.gd`).
  - Job 2: Windows export sanity (`--export-release "Windows Desktop"`).

### Snapshot of this verification run

`tools/ci/run_godot_checks.ps1`:
- Exit code: `0`
- Summary output: `Godot checks completed.`

Direct smoke run:
- Exit code: `0`
- Report: `[SmokeTest] Checks run: 132`, `[SmokeTest] SUCCESS`
- Note: trailing `Failed to read the root certificate store` log was non-fatal and did not affect smoke status.

### Validation checklist executed

- Coverage completeness against tracked runtime text/config files:
  - Result: `doc_count=30`, `tracked_count=30`, `missing:none`.
- Scene resource wiring (`ext_resource`) recheck:
  - Verified script and scene instance links for `Main.tscn`, `World.tscn`, `StartScreen.tscn`, `Player.tscn`, `FusionCinematic.tscn`.
- Script dependency recheck (`preload`, `load`, cross-script calls):
  - Verified `World.gd` preloads (`Settings`, `BigBigData`, `Aminomon`, `BattleState`) and texture/data load paths.
- Map and tileset alignment (`.tmx`/`.tsx` with runtime parser):
  - Verified `World.gd` constants and slicing logic align with `indoor_tiles.tsx` and `spriteSheet_tiledLiquids_32x32.tsx`.
- Node-path sanity:
  - Verified key `World.gd` lookups against `WorldUI.tscn` node names (battle, dialog, pause/dex/team/storage, fade overlay).
- File-path sanity:
  - Verified documented file references exist in tracked paths and runtime loading paths.

## 7) Legacy Appendix (`Code/`, `Archive/`)

### Source of Truth vs Legacy
| Area | Status | What it is | Runtime authority |
|---|---|---|---|
| `Aminomon/` | Canonical | Active Godot runtime (scenes, scripts, assets, maps). | Yes |
| `Code/` | Deprecated | Legacy pygame implementation and systems. | No |
| `Archive/GodotProject_legacy/` | Archived reference | Earlier Godot migration snapshot. | No |
| Root `images/`, root `data/` | Legacy/reference duplicate | Older duplicated assets and data trees. | No (unless explicitly linked, currently not) |

### `Code/` (pygame legacy) grouped outline

Architecture:
- Entrypoint/orchestrator: `Code/Main.py` (`Game` class; map load, overlays, battle transitions).
- Data model: `Code/AminoMons.py`, `Code/BigBigData.py`.
- Battle system: `Code/FightFightFight.py`.
- Map actors and interactions: `Code/GameObjects.py`, `Code/Sprites.py`, `Code/SpriteGroups.py`.
- Menus and overlays: `Code/HomePage.py`, `Code/PauseMenu.py`, `Code/PartyScreen.py`, `Code/StorageMenu.py`, `Code/PeptideDex.py`, `Code/AminoIndex.py`.
- Utilities: `Code/SettingsAndSupport.py`, `Code/TimerForTimingThings.py`, `Code/Dialog.py`, `Code/FusionMethods.py`.

Interaction summary:
- `Main.py` imports almost every module and drives the pygame loop.
- Supporting modules are tightly coupled around shared globals from `SettingsAndSupport.py` and data tables in `BigBigData.py`.

### `Archive/GodotProject_legacy/` grouped outline

Contains an earlier smaller Godot port:
- Scripts mirror core names (`Main.gd`, `World.gd`, `Aminomon.gd`, etc.) but with much smaller behavior surface.
- Scenes include old `Main/World/StartScreen/Player`.

Use:
- Historical reference only for migration context.
- Not targeted by active CI/runtime policy.

## 8) Asset Appendix (Grouped by Usage Domain)

### Active runtime asset domains (`Aminomon/images`)
- `backgrounds/`: start and battle backgrounds.
- `characters/`: overworld actor sheets (player, boss, healer, fuser, unfuser, storage).
- `monsAminos/`: battle sprite sheets for species/forms.
- `iconsAminos/`: menu/dex/storage icon sprites.
- `ui/`: battle and menu iconography (`sword`, `arrows`, `hand`, `cross`, stats icons, highlights).
- `attacks/`: effect strips for attack/heal visuals.
- `tilesets/`: indoor and liquids atlas images used by TMX tile rendering.
- `fonts/`: MatrixType font family used in UI text systems.
- `other/`: support visuals (shadow, star animation frames).
- `objs/`: misc map object texture(s).

### Import and Godot sidecar metadata
- `.import` files: Godot import metadata for assets.
- `.uid` files: script UID mappings for editor/resource references.
- `.godot/` runtime/editor state: intentionally ignored in git.

These are operationally important for editor/runtime behavior but treated as generated/asset-adjacent metadata rather than authored gameplay logic files.

### Duplicate root assets/data classification
- Root `images/` and root `data/` trees duplicate active runtime domains.
- Current runtime constants and resource paths in active scripts point to `res://images` and `res://data` inside `Aminomon/` project root (not repo root duplicates).
- Duplicates are kept as historical/reference artifacts unless intentionally re-linked.
