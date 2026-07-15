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

## Arena scenes

- `ArenaGraybox` must retain these direct containers: `Geometry`, `StaticCollision`, `SpawnPoints`, `HazardSockets`, `CameraAnchors`, `DeathZones`, `Decoration`, and `DebugVisualization`.
- Visual arena scenes may wrap `ArenaGraybox` instead of duplicating its physics. Keep the gameplay-facing `ArenaRoot` discoverable and do not move spawn, hazard, camera, or DeathZone ownership into decorative layers.
- `ArenaRoot` is the only public discovery surface for arena content. Gameplay systems use its typed methods; they must not hard-code child paths or repeatedly scan the tree.
- Spawn points, hazard sockets, camera anchors, and DeathZones need unique IDs. Spawn points face the arena, remain above the floor, stay clear of open edges, and preserve the configured minimum spacing.
- DeathZones only signal that a `PhysicsBody3D` entered. They never delete bodies, reload a scene, or control a match.
- Use explicit primitive `MeshInstance3D` plus manual `CollisionShape3D` pairs for physical graybox modules. Static arena modules use layer 1 `World`; DeathZones use layer 6 `DeathZones`. Do not generate mesh collision automatically.
- Run `ArenaValidator` whenever arena composition, IDs, transforms, containers, or collision layers change. Address errors before treating an arena scene as usable; warnings need an explicit review.

## KayKit assets

- Keep original KayKit packages in `assets/kaykit/source/`; Godot should not import from this folder.
- Runtime visuals must use curated GLTF/GLB copies under `assets/environment/kaykit/` or `assets/characters/kaykit/`, with shared atlas textures under `assets/environment/kaykit/textures/`.
- Decorative KayKit prefabs live under `scenes/environment/kaykit/prefabs/` and must not add physics collision unless a later task explicitly promotes an asset to gameplay collision.
- Use `EnvironmentQualityProfile` and `EnvironmentQualityController` for visual quality switches. Do not reload scenes just to change visual quality.
- City Builder Bits are license/catalog source only until a later task explicitly curates runtime assets from that package.

## Character visuals

- `CharacterDefinition` owns character identity, model scene, normalization transform, animation set, default loadout, and enabled state. Per-character visual scale, offset, and forward rotation belong in the definition, not in showcase scenes.
- `CharacterVisual` is the public facade for imported character models. Gameplay and debug scenes must use its API (`apply_definition`, `get_skeleton`, `get_animation_controller`, `get_available_actions`, `get_diagnostics`, `clear_character`) instead of searching inside imported GLB nodes.
- `CharacterAnimationController` uses canonical action IDs: `idle`, `walk`, `run`, `fall`, `hit`, `attack`, and `victory`. It maps those IDs through `CharacterAnimationSet`; do not hard-code KayKit clip names in gameplay.
- `CharacterAttachmentController` applies visual-only loadouts to `BoneAttachment3D` sockets. Accessories must not include gameplay collision, hitboxes, damage logic, or physics simulation.
- Attachment sockets are canonical (`right_hand`, `left_hand`, `back`, `head`) and must be resolved from audited skeleton bones. If KayKit skeletons change, rerun the audit before changing socket names.
- Run `scenes/characters/CharacterValidationTest.tscn` after editing character definitions, animation sets, accessory prefabs, loadouts, or curated Adventurers assets. Treat validation errors as blockers; warnings require explicit review in the reports.

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
