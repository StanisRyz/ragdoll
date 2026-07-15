extends Node3D

const CATALOG: CharacterDefinitionCatalog = preload("res://resources/characters/kaykit/character_catalog.tres")
const DUMMY_SCENE: PackedScene = preload("res://scenes/combat/CombatDummy.tscn")

@onready var visual_arena: ArenaVisualLayers = $ArenaMedievalForest
@onready var arena: ArenaRoot = $ArenaMedievalForest/Physics/ArenaGraybox
@onready var fighter: Fighter = $PlayerFighter/Fighter
@onready var input_adapter: PlayerFighterInput = $PlayerFighter/Fighter/PlayerFighterInput
@onready var camera_rig: ArenaCameraRig = $ArenaCameraRig
@onready var validator: ArenaValidator = $ArenaValidator
@onready var dummies_root: Node3D = $CombatDummies

var _definitions: Array[CharacterDefinition] = []
var _definition_index: int = 0

func _ready() -> void:
	_definitions = CATALOG.get_enabled_definitions()
	if not _definitions.is_empty():
		fighter.set_character_definition(_definitions[0])
	fighter.combat_identity.combatant_id = &"player"
	fighter.combat_identity.team_id = 0
	var spawn: ArenaSpawnPoint = arena.get_player_spawn_point()
	if spawn != null:
		fighter.reset_to_transform(spawn.get_spawn_transform())
	for zone: ArenaDeathZone in arena.get_death_zones():
		zone.body_entered_death_zone.connect(_on_death_zone_entered)
	camera_rig.set_follow_target(fighter)
	input_adapter.set_camera_rig(camera_rig)
	_spawn_dummies()
	validator.validate_arena()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_R:
			_reset_scene()
		KEY_C:
			_cycle_character()
		KEY_F:
			var enabled: bool = not fighter.debug_visualization.visible
			fighter.set_debug_visualization_enabled(enabled)
			for child: Node in dummies_root.get_children():
				if child is CombatDummy:
					child.fighter.set_debug_visualization_enabled(enabled)
		KEY_M:
			visual_arena.toggle_debug_markers()

func _spawn_dummies() -> void:
	for child: Node in dummies_root.get_children():
		child.queue_free()
	var spawns: Array[ArenaSpawnPoint] = arena.get_bot_spawn_points()
	for index: int in mini(3, spawns.size()):
		var dummy: CombatDummy = DUMMY_SCENE.instantiate() as CombatDummy
		dummy.name = "CombatDummy%d" % (index + 1)
		dummies_root.add_child(dummy)
		dummy.reset_dummy(spawns[index].get_spawn_transform())
		if index == 2:
			dummy.set_team_id(0)

func _reset_scene() -> void:
	var spawn: ArenaSpawnPoint = arena.get_player_spawn_point()
	if spawn != null:
		fighter.reset_to_transform(spawn.get_spawn_transform())
	var spawns: Array[ArenaSpawnPoint] = arena.get_bot_spawn_points()
	for index: int in dummies_root.get_child_count():
		var dummy: CombatDummy = dummies_root.get_child(index) as CombatDummy
		if dummy != null and index < spawns.size():
			dummy.reset_dummy(spawns[index].get_spawn_transform())
			dummy.set_team_id(0 if index == 2 else 1)

func _cycle_character() -> void:
	if _definitions.is_empty():
		return
	_definition_index = wrapi(_definition_index + 1, 0, _definitions.size())
	fighter.set_character_definition(_definitions[_definition_index])

func _on_death_zone_entered(zone_id: String, body: PhysicsBody3D) -> void:
	if body == fighter:
		fighter.notify_death_zone(zone_id)
