# Ragdoll Arena

Godot 4.5 Compatibility-renderer foundation for a future browser ragdoll arena. The current stage is a playable combat-interaction sandbox: modular arena, KayKit visual Fighters, camera-relative locomotion, action-layer attack and dash, Hitbox/Hurtbox contact events, and automated movement/combat validation. It intentionally still has no health, knockback, hit reaction, stun, instability, ragdoll, AI, match flow, active traps, final assets, or Yandex SDK.

## Open, run, and verify

Open `project.godot` in Godot 4.5+. The main scene remains `Bootstrap.tscn`, which safely opens `CombatInteractionTest.tscn` through `AppConfig.START_SCENE_PATH`.

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

## KayKit Adventurers

The data-driven character visual layer supports six curated Adventurers: Barbarian, Knight, Mage, Ranger, Rogue, and Rogue Hooded. All load through `scenes/characters/CharacterVisual.tscn` from `CharacterDefinition` resources in `resources/characters/kaykit/definitions/`.

All six models use a compatible `Rig_Medium` skeleton for the current visual layer: 23 bones, root bone `root`, skeleton path `Rig_Medium/Skeleton3D`, and common key/socket bones for hips, spine, head, arms, legs, `hand.r`, `hand.l`, and the canonical sockets `right_hand`, `left_hand`, `back`, `head`. Full bone order differs between several GLBs; validation records that as a warning, not a critical blocker.

Animation libraries are `Rig_Medium_General.glb` and `Rig_Medium_MovementBasic.glb`. The canonical mapping is:

| Action | Clip |
| --- | --- |
| idle | `Rig_Medium_General/Idle_A` |
| walk | `Rig_Medium_MovementBasic/Walking_A` |
| run | `Rig_Medium_MovementBasic/Running_A` |
| airborne | `Rig_Medium_MovementBasic/Jump_Idle` |
| land | `Rig_Medium_MovementBasic/Jump_Land` |
| hit | `Rig_Medium_General/Hit_A` |
| eliminated | `Rig_Medium_General/Death_A` |
| attack | unavailable in audited libraries |
| victory | unavailable in audited libraries |

Default visual loadouts are data resources: Knight uses sword + shield, Barbarian uses a two-handed axe, Mage uses a staff, Ranger uses bow + quiver, and both Rogue variants use a dagger. These accessories are visual-only prefabs under `scenes/characters/accessories/`; they have no gameplay collision, hitbox, or physics simulation.

`CharacterShowcase.tscn` controls: Tab switches character, 1/2 switch canonical action, Space plays, S stops, P cycles playback speed, L toggles loadout, F toggles fill light, D toggles debug visibility, A starts automatic showcase mode, and Left/Right rotate the character.

`CharacterValidationTest.tscn` is the headless check for all character definitions. It creates each `CharacterVisual`, checks skeleton/socket availability, connects animation libraries, plays mapped actions, applies default loadout, and writes:

- `reports/characters/kaykit_skeleton_compatibility.md`
- `reports/characters/kaykit_animation_compatibility.md`

Latest result: `0 errors`, `5 warnings`, `1 note`. The warnings document non-critical full bone list/order differences while shared key bones and attachment sockets remain compatible.

## Fighter Movement

`Fighter.tscn` is a reusable `CharacterBody3D` wrapper around `CharacterVisual`. It exposes movement, reset, death-zone, debug, and character-definition APIs without reading keyboard input. `PlayerFighter.tscn` adds `PlayerFighterInput`, which reads `move_left/right/forward/backward`, converts input through `ArenaCameraRig` flat forward/right vectors, and sends world-space movement intent to `Fighter`.

Locomotion states are `IDLE`, `WALKING`, `RUNNING`, `AIRBORNE`, and `DISABLED`. `FighterMotor` owns acceleration, deceleration, gravity, maximum speed, fall-speed limits, air control, and facing rotation from `FighterMovementConfig`. The default config is `resources/fighters/default_fighter_movement_config.tres`, tuned for the 24x24 metre arena.

`ArenaCameraRig.tscn` follows the Fighter `CameraTarget`, keeps a fixed arena-brawler yaw/pitch, uses a `SpringArm3D`, adds small velocity look-ahead, and biases the look target slightly toward the arena centre. It does not rotate with every Fighter turn.

`FighterMovementTest.tscn` is now the Bootstrap development scene. Controls: WASD moves camera-relative, R resets to player spawn, C cycles all six CharacterDefinitions, Q toggles environment quality, F toggles Fighter debug, V toggles CharacterVisual debug, and M toggles arena markers. DeathZone entry calls `Fighter.notify_death_zone`, disables movement, and can be recovered through reset.

`FighterMovementValidationTest.tscn` validates all six CharacterDefinitions without keyboard input: definition application, acceleration, speed cap, stopping without sliding, direction change and rotation, disabled movement, DeathZone transition to `DISABLED`, reset to `IDLE`, and runtime animation loop/one-shot policy. Latest result: `0 errors`, `0 warnings`.

## Fighter combat foundation

`Fighter.tscn` now separates locomotion from action state. `FighterStateController` still owns locomotion (`IDLE`, `WALKING`, `RUNNING`, `AIRBORNE`, `DISABLED`), while `FighterActionController` owns action occupancy (`NONE`, `PRIMARY_ATTACK`, `DASH`). `FighterMotor` keeps separate locomotion, action, future external impulse, and vertical velocity channels. Dash uses action velocity; knockback is intentionally left for the next stage.

Floor handling applies `CharacterBody3D.floor_snap_length` and `floor_max_angle` from `FighterMovementConfig`; `is_on_floor()` is the gameplay grounded source. `GroundProbe` remains only for debug and near-landing diagnostics. `Jump_Idle` loops at runtime for `airborne`; `land` remains one-shot.

`ArenaCameraRig` uses `FollowRoot/YawPivot/PitchPivot/SpringArm3D/Camera3D`. Distance is controlled through `SpringArm3D`, yaw and pitch are independent, and camera-relative forward/right still drive player movement.

### Attack, dash, and contact events

`AttackDefinition` describes the basic sweep: windup, active, recovery, cooldown, movement multiplier, rotation lock, max targets, hitbox offset/size, impulse metadata, animation action, and tags. `basic_sweep_attack.tres` is a short wide hit in front of the Fighter that can hit several close enemy targets.

`FighterAttackController` owns `READY`, `WINDUP`, `ACTIVE`, `RECOVERY`, and `COOLDOWN`. The Hitbox is enabled only during `ACTIVE`. Attack timing comes from `AttackDefinition`, not from animation length. KayKit does not currently provide a dedicated melee/dash library, so canonical `attack` uses `Rig_Medium_General/Use_Item` as a documented temporary fallback.

`DashDefinition` describes fixed duration, speed, cooldown, steering, gravity multiplier, movement lock, rotation permission, and optional animation action. `default_dash.tres` starts from current movement intent, falls back to facing direction, collides with World geometry through `CharacterBody3D.move_and_slide`, does not deal damage, and does not grant invulnerability.

`FighterHitbox` is an `Area3D` on layer 3 `Hitboxes`, masking only layer 4 `Hurtboxes`. It is disabled by default, clears hit targets per activation, rejects self-hits, applies team filtering, prevents repeat hits on the same target during one activation ID, and emits structured contact data.

`FighterHurtbox` is an `Area3D` on layer 4 `Hurtboxes`, masking only `Hitboxes`. It confirms whether its owner can receive the hit and forwards the confirmed event to the owner. It does not apply health, knockback, stun, instability, or ragdoll.

`CombatHitData` carries `source_fighter`, `target_fighter`, `attack_id`, `activation_id`, `hitbox_id`, `hurtbox_id`, `contact_position`, `attack_direction`, `base_impulse`, `vertical_impulse`, `source_velocity`, and `tags`. Signal relays use `duplicate_safe()`.

Team rules are owned by `FighterCombatIdentity`: same-team hits are rejected unless friendly fire is enabled, self-hits are always rejected, and `can_receive_hits` gates Hurtbox confirmation.

### CombatInteractionTest controls

`CombatInteractionTest.tscn` contains `ArenaMedievalForest`, `PlayerFighter`, `ArenaCameraRig`, three `CombatDummy` targets, `ArenaValidator`, `CombatDebugUI`, and `DebugOverlay`.

| Control | Action |
| --- | --- |
| WASD | Move camera-relative |
| Left mouse | Primary attack |
| Right mouse | Dash |
| R | Reset player and dummies |
| C | Cycle CharacterDefinition |
| F | Toggle Fighter/Hitbox/Hurtbox debug |
| M | Toggle arena markers |
| F11 | Toggle DebugOverlay |

`CombatDummy.tscn` is a Fighter without input or AI. It has a Hurtbox, team ID, hit counter, last `CombatHitData`, reset support, and debug label. The third dummy is same-team by default to verify friendly-fire filtering.

## Current validation results

- Headless import: `godot --headless --path . --editor --quit` completed with exit code 0.
- `CharacterValidationTest`: `0 errors`, `5 warnings`, `1 note`; warnings are the known non-critical full bone-list differences.
- `FighterMovementValidationTest`: completed with exit code 0; covers floor snap/angle, grounded source, locomotion, reset, airborne loop, and action velocity reset.
- `CombatInteractionValidationTest`: completed with exit code 0; covers active-only Hitbox, self/friendly filtering, enemy hit event, one-hit-per-activation, cooldown/recovery, reset/DeathZone cancellation, attack/dash mutual blocking, dash completion, dash distance, wall collision, and six CharacterDefinitions.
- Limited headless `CombatInteractionTest` launch completed with exit code 0.

Manual visual checks still needed: play `CombatInteractionTest.tscn` in a window and inspect camera feel over height changes, debug bounds/socket markers while animations play, visible Hitbox/Hurtbox timing, and multi-target attack readability.

Next stage: consume confirmed `CombatHitData` in a dedicated reaction layer for knockback, hit reaction, stun, instability, and later ragdoll activation.

## Web export and next stage

The repository keeps a baseline Web preset without a custom shell or Yandex SDK. Export templates must be installed locally to produce the build. The Web preset excludes `assets/kaykit/source/**`, FBX, OBJ, MTL, PDFs, source URLs, samples, and contents preview images.

`EnvironmentBenchmark.tscn` now reports current, average, and minimum FPS; node count; total and visible `MeshInstance3D` count; active quality profile; and visuals on/off. It automatically cycles STANDARD visuals on, LOW visuals on, STANDARD visuals off, and LOW visuals off.
