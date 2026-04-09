# Aminomon
Main repo for Vandy IGP Project

Thank you for checking it out!

## Godot Port (Canonical)
- Active project: `Aminomon/`
- Legacy project archive: `Archive/GodotProject_legacy/`

## Runtime Policy
- Canonical runtime is Godot only (`Aminomon/`).
- Legacy Python/pygame code under `Code/` is deprecated reference code and is not supported as a runtime target.
- New feature work should be implemented in Godot scripts/scenes.

## Godot Data/Assets Layout
- Runtime content now lives under the Godot project:
  - `Aminomon/images/`
  - `Aminomon/data/mapfile/`
- Save files are written to `user://save/` (Godot user data path).
- Legacy `data/save/*.csv` compatibility is intentionally out of scope for the current Godot runtime.

## Godot Validation
- Headless smoke tests: `tools/ci/run_godot_checks.ps1`
- Smoke + export sanity: `tools/ci/run_godot_checks.ps1 -RunExport`

## Godot Run (Crash-Safe Launcher)
- Use `tools/run_godot.ps1` for local runs in restricted/sandboxed environments.
- It forces a writable local user-data path and runtime log file to avoid `user://logs` startup crashes.
- Run game/editor:
  - `powershell -ExecutionPolicy Bypass -File tools/run_godot.ps1 -Editor`
- Run headless smoke directly:
  - `powershell -ExecutionPolicy Bypass -File tools/run_godot.ps1 -Headless -Script res://scripts/SmokeTest.gd`
- Runtime logs:
  - `Aminomon/.godot_userdata_local/godot_runtime.log`


Alex





fonts: https://ggbot.itch.io/matrixtype-font-family
characters: https://elvgames.itch.io/free-retro-game-world-sprites
Amino Acid Chemical Patches: https://marceles.itch.io/land-of-pixels-laboratory-tileset-pixel-art
Tileset and UI Buttons:https://scarloxy.itch.io/mpwsp01
