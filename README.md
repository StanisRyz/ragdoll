# Ragdoll Arena

Godot 4.5 Compatibility-renderer foundation for a future browser ragdoll arena. The current stage is a playable modular graybox test arena; it intentionally has no fighters, AI, ragdolls, attacks, active traps, match flow, final assets, or Yandex SDK.

## Open, run, and verify

Open `project.godot` in Godot 4.5+. The main scene remains `Bootstrap.tscn`, which safely opens `ArenaGrayboxTest.tscn`.

```powershell
godot --path .
godot --headless --path . --editor --quit
```

The project uses a 1280×720 baseline viewport, resizable window, canvas-item UI scaling, and 60 Hz physics. The test scene automatically runs `ArenaValidator` and shows its report in the upper-left UI.

## Graybox arena

`ArenaGraybox.tscn` is a 24×24 metre, primitive-only arena built from reusable floor, edge, corner, pillar, and block modules. It has a clear centre, raised obstacles, open edges, one player spawn, eleven bot spawns, ten future hazard sockets, three camera anchors, and one large DeathZone below the floor.

`ArenaRoot` is the public arena interface. Future gameplay must obtain player/bot spawns, sockets, anchors, and DeathZones through it rather than searching scene paths. It exposes the player-spawn count for validation, and also owns arena debug-marker visibility and the baseline structural check.

Main scenes and scripts:

- `scenes/arena/ArenaGraybox.tscn` — reusable arena and its stable container structure.
- `scenes/arena/ArenaGrayboxTest.tscn` — test lighting, free camera, validator, physics probe, UI, and DebugOverlay.
- `scenes/arena/modules/` — manually-collided primitive graybox modules on the `World` layer.
- `ArenaSpawnPoint`, `ArenaHazardSocket`, `ArenaCameraAnchor`, and `ArenaDeathZone` — typed public arena components.
- `ArenaValidationConfig` — small resource for spawn counts, distances, edge margin, DeathZone height, and arena size.

## Test controls

| Control | Action |
| --- | --- |
| WASD, Space, Ctrl | Free-camera movement |
| Shift | Faster camera movement |
| Right mouse | Capture/release cursor |
| Tab | Cycle camera anchors |
| 1 / 2 | Spawn probe over player / next bot |
| X / R | Remove / reset current probe |
| M | Toggle arena markers |
| F10 / F11 | Reload test scene / toggle DebugOverlay |

The orange `ArenaPhysicsProbe` is a RigidBody3D with a manual collider. Its DeathZone entry is reported in the test UI; the zone deliberately does not delete the probe or control gameplay.

## Input and collision contract

Gameplay reads named Input Map actions, allowing a later mobile-input adapter. `World` is layer 1; `DeathZones` is layer 6. The remaining reserved layers are Fighters (2), Hitboxes (3), Hurtboxes (4), Hazards (5), Props (7), and Sensors (8).

## Checks performed

`godot --headless --path . --editor --quit` and a four-second headless Bootstrap run completed successfully after this stage. The arena validator runs at startup; its authored arena configuration is expected to return **0 errors and 0 warnings**. Visual flight controls, anchor switching, and probe interaction still require a manual editor/window check because headless mode cannot provide mouse-driven inspection.

## KayKit visual arena

KayKit originals are archived under `assets/kaykit/source/` and ignored by Godot through `.gdignore`. Runtime visuals use only curated copies under `assets/environment/kaykit/` and `assets/characters/kaykit/`; package licenses are registered in `assets/kaykit/licenses/`.

`scenes/arena/ArenaMedievalForest.tscn` is the first visual arena. It wraps the existing `ArenaGraybox` physics scene, adds independent KayKit floor, wall, nature, hazard-socket, and background visual layers, and keeps decorative assets collision-free. The gameplay contract remains the inner `ArenaRoot` at `Physics/ArenaGraybox`.

`scenes/arena/ArenaVisualTest.tscn` validates the inner arena and provides visual toggles: Q switches quality profile, G toggles graybox meshes, V toggles KayKit visuals, B toggles background decoration, and M toggles debug markers. `scenes/debug/EnvironmentBenchmark.tscn` rotates a camera around the visual arena and alternates quality profiles for a quick performance smoke test.

The runtime asset catalog is documented in `resources/configuration/kaykit_runtime_catalog.md`. Adventurer GLB assets are staged only for a later character pipeline; see `assets/characters/kaykit/adventurers/TECHNICAL_REPORT.md`.

## Web export and next stage

The repository keeps a baseline Web preset without a custom shell or Yandex SDK. Export templates must be installed locally to produce the build. The Web preset excludes `assets/kaykit/source/**`, FBX, OBJ, MTL, PDFs, source URLs, samples, and contents preview images.

Next: gameplay-facing character and hazard visuals can consume the curated KayKit pipeline without changing graybox collision or the `ArenaRoot` API.
