# Ragdoll Arena

Technical Godot 4.5 foundation for a future browser ragdoll arena targeting Yandex Games. This stage deliberately contains no arena rules, fighters, ragdolls, progression, or SDK integration.

## Opening and running

Open `project.godot` in Godot 4.5 or newer. The project uses the Compatibility renderer and starts at `scenes/bootstrap/Bootstrap.tscn`; Bootstrap validates and opens the debug playground. Run with the editor's **Play** button or:

```powershell
D:\godot\Godot.exe --path .
```

The baseline viewport is 1280×720, the window is resizable, UI uses canvas-item stretching, and physics runs at 60 ticks per second.

## Technical checks

When Godot is available, import and parse the project with:

```powershell
D:\godot\Godot.exe --headless --path . --editor --quit
```

Then launch the project manually. The playground confirms 3D rendering, lighting, a static physics floor, UI, routing, and the debug interface. Press F10 to safely reload the active test scene and F11 to toggle diagnostics.

## Layout

- `assets/` — character, environment, material, audio, and UI source assets.
- `scenes/` — bootstrap, arena, character, gameplay, UI, and debug scenes.
- `scripts/` — matching runtime domains. `core/` contains only AppConfig, routing, and bootstrap logic; `debug/` contains diagnostics.
- `resources/` — configuration, future character data, and arena data.
- `tests/` and `addons/` — automated checks and project extensions.

Empty planned directories are retained with `.gitkeep` files.

## Input Map

| Action | Default input |
| --- | --- |
| `move_left`, `move_right`, `move_forward`, `move_backward` | A, D, W, S |
| `primary_action`, `secondary_action` | Left mouse, right mouse |
| `pause` | Escape |
| `debug_restart`, `debug_toggle_overlay` | F10, F11 |

Gameplay code must read named actions rather than physical devices, leaving room for a later mobile input adapter.

## Collision layers

| Layer | Name |
| --- | --- |
| 1 | World |
| 2 | Fighters |
| 3 | Hitboxes |
| 4 | Hurtboxes |
| 5 | Hazards |
| 6 | DeathZones |
| 7 | Props |
| 8 | Sensors |

## Core components

- `AppConfig` is a small autoload exposing debug flags, target FPS, technical constants, and editor/Web detection.
- `SceneRouter` is a small autoload that checks scene resources and returns `{ ok, error }` results when switching or reloading scenes.
- `Bootstrap` is the main scene; it contains no gameplay and reports any initial-scene loading failure.
- `DebugOverlay` is a reusable UI scene with FPS, current scene, window size, renderer setting, run mode, node count, and debug state. It follows `AppConfig` and refreshes after scene changes.

## Web export

`export_presets.cfg` contains a baseline Web preset using ordinary browser-compatible settings, Compatibility rendering, and no Yandex SDK or custom shell. Export templates still need to be installed in the local Godot editor before producing a Web build.

## Current stage and next step

The project now has a verified bootstrap-to-playground technical baseline. The recommended next step is a modular graybox arena: world bounds, floor modules, hazards, and sensors using the documented collision-layer contract.
