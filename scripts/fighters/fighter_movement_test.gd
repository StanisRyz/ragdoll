extends Node3D

const CATALOG: CharacterDefinitionCatalog = preload("res://resources/characters/kaykit/character_catalog.tres")

@onready var visual_arena: ArenaVisualLayers = $ArenaMedievalForest
@onready var arena: ArenaRoot = $ArenaMedievalForest/Physics/ArenaGraybox
@onready var player_fighter_root: Node3D = $PlayerFighter
@onready var fighter: Fighter = $PlayerFighter/Fighter
@onready var input_adapter: PlayerFighterInput = $PlayerFighter/Fighter/PlayerFighterInput
@onready var camera_rig: ArenaCameraRig = $ArenaCameraRig
@onready var validator: ArenaValidator = $ArenaValidator
@onready var label: Label = $CanvasLayer/StatusLabel

var _definitions: Array[CharacterDefinition] = []
var _definition_index: int = 0
var _last_event: String = "started"

func _ready() -> void:
	_definitions = CATALOG.get_enabled_definitions()
	if not _definitions.is_empty():
		fighter.set_character_definition(_definitions[0])
	var spawn: ArenaSpawnPoint = arena.get_player_spawn_point()
	if spawn != null:
		fighter.reset_to_transform(spawn.get_spawn_transform())
	for zone: ArenaDeathZone in arena.get_death_zones():
		zone.body_entered_death_zone.connect(_on_death_zone_entered)
	camera_rig.set_follow_target(fighter)
	input_adapter.set_camera_rig(camera_rig)
	fighter.fall_detector.fighter_fell.connect(_on_fighter_fell)
	fighter.reset_completed.connect(func() -> void: _last_event = "reset")
	validator.validate_arena()

func _process(_delta: float) -> void:
	var controller: CharacterAnimationController = fighter.get_character_visual().get_animation_controller()
	label.text = "\n".join(PackedStringArray([
		"FighterMovementTest | R reset | C character | Q quality | F fighter debug | V character debug | M arena markers",
		"Character: %s" % (fighter.get_character_definition().id if fighter.get_character_definition() != null else &""),
		"State: %s | speed %.2f | velocity %s | grounded %s | enabled %s" % [fighter.get_movement_state(), fighter.get_horizontal_speed(), fighter.get_velocity(), fighter.is_grounded(), fighter.is_movement_enabled()],
		"Intent: %s | facing %s" % [fighter.motor.movement_intent, fighter.motor.get_facing_direction()],
		"Action: %s | clip %s" % [controller.get_current_action(), controller.get_current_clip_name()],
		"Camera: %s | Last: %s" % [camera_rig.get_camera().global_position, _last_event],
	]))

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_R:
			_reset_to_spawn()
		KEY_C:
			_cycle_character()
		KEY_Q:
			$ArenaMedievalForest/QualityController.toggle_profile()
		KEY_F:
			fighter.set_debug_visualization_enabled(not fighter.debug_visualization.visible)
		KEY_V:
			fighter.get_character_visual().set_debug_visualization_enabled(not fighter.get_character_visual().debug_visualization.visible)
		KEY_M:
			visual_arena.toggle_debug_markers()

func _reset_to_spawn() -> void:
	var spawn: ArenaSpawnPoint = arena.get_player_spawn_point()
	if spawn != null:
		fighter.reset_to_transform(spawn.get_spawn_transform())
		_last_event = "manual reset"

func _cycle_character() -> void:
	if _definitions.is_empty():
		return
	_definition_index = wrapi(_definition_index + 1, 0, _definitions.size())
	fighter.set_character_definition(_definitions[_definition_index])
	_last_event = "character %s" % _definitions[_definition_index].id

func _on_death_zone_entered(zone_id: String, body: PhysicsBody3D) -> void:
	if body == fighter:
		fighter.notify_death_zone(zone_id)

func _on_fighter_fell(zone_id: String) -> void:
	_last_event = "fell: %s" % zone_id
