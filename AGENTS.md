# Repository conventions

## GDScript and naming

- Use typed GDScript where a stable engine or project type is known. Prefer `snake_case` for files, variables, functions, and folders; use `PascalCase` for scene files, classes, and node names.
- Use clear node names that describe their role (`Camera3D`, `WorldEnvironment`, `DebugOverlay`), not implementation accidents.
- Keep scripts small and single-purpose. Handle failed resource loading explicitly.

## Directory ownership

- `assets/` contains imported source assets; `scenes/` contains composed scenes; `scripts/` contains runtime code; `resources/` contains authored data resources; `tests/` contains automated checks; and `addons/` contains third-party/editor extensions.
- `core/` is for narrow cross-cutting technical services. `debug/` is diagnostic-only. `gameplay/`, `arena/`, and `characters/` own their future domain logic; they must not be folded into core.

## Autoloads and bootstrap

- Autoloads are limited to small, stateless-or-configuration services. `AppConfig` exposes technical configuration; `SceneRouter` only validates and changes scenes. Neither stores gameplay state.
- `Bootstrap` only starts the configured initial scene and displays loading errors. Do not put gameplay logic, arena assembly, fighters, or persistence there.

## Verification

- After project or GDScript changes, run Godot headlessly when available: `Godot --headless --path . --editor --quit`.
- Also launch `Bootstrap`, exercise F10 restart and F11 overlay toggle, and inspect the Output panel for parser, missing-resource, or autoload errors before handing off a change.

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
