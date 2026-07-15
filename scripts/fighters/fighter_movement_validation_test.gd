extends Node3D

const CATALOG: CharacterDefinitionCatalog = preload("res://resources/characters/kaykit/character_catalog.tres")
const FIGHTER_SCENE: PackedScene = preload("res://scenes/fighters/Fighter.tscn")

@export var quit_on_finish: bool = true
var completed: bool = false
var exit_code: int = 0

var _errors: PackedStringArray = []
var _warnings: PackedStringArray = []

func _ready() -> void:
	print("FighterMovementValidationTest: ready")
	call_deferred("_run")

func _run() -> void:
	print("FighterMovementValidationTest: running")
	for definition: CharacterDefinition in CATALOG.get_enabled_definitions():
		_validate_definition(definition)
	print("FighterMovementValidationTest: %d errors, %d warnings" % [_errors.size(), _warnings.size()])
	for error: String in _errors:
		push_error(error)
	for warning: String in _warnings:
		push_warning(warning)
	exit_code = 1 if not _errors.is_empty() else 0
	completed = true
	if quit_on_finish:
		get_tree().quit(exit_code)

func _validate_definition(definition: CharacterDefinition) -> void:
	var fighter: Fighter = FIGHTER_SCENE.instantiate() as Fighter
	if fighter == null:
		_errors.append("%s could not instantiate Fighter scene." % definition.id)
		return
	add_child(fighter)
	fighter.set_character_definition(definition)
	fighter.reset_to_transform(Transform3D(Basis.IDENTITY, Vector3(0, 0.95, 0)))
	_step_fighter(fighter, 90)
	if fighter.get_movement_state() != &"IDLE":
		_errors.append("%s did not settle to IDLE." % definition.id)
	fighter.set_move_intent(Vector3.FORWARD)
	_step_fighter(fighter, 24)
	if fighter.get_movement_state() != &"WALKING" and fighter.get_movement_state() != &"RUNNING":
		_errors.append("%s did not enter locomotion state." % definition.id)
	if fighter.get_horizontal_speed() <= 0.5:
		_errors.append("%s did not accelerate." % definition.id)
	if fighter.get_horizontal_speed() > fighter.movement_config.maximum_speed + 0.25:
		_errors.append("%s exceeded maximum speed." % definition.id)
	var facing_before: Vector3 = fighter.motor.get_facing_direction()
	fighter.set_move_intent(Vector3.RIGHT)
	_step_fighter(fighter, 18)
	if fighter.motor.get_facing_direction().distance_to(facing_before) <= 0.05:
		_errors.append("%s did not rotate toward changed intent." % definition.id)
	fighter.clear_move_intent()
	_step_fighter(fighter, 36)
	if fighter.get_horizontal_speed() > fighter.movement_config.stop_speed_epsilon + 0.1:
		_errors.append("%s kept sliding after stopping." % definition.id)
	fighter.set_movement_enabled(false)
	fighter.set_move_intent(Vector3.FORWARD)
	var locked_position: Vector3 = fighter.global_position
	_step_fighter(fighter, 12)
	if fighter.global_position.distance_to(locked_position) > 0.1:
		_errors.append("%s moved while movement disabled." % definition.id)
	fighter.notify_death_zone("validation")
	_step_fighter(fighter, 2)
	if fighter.get_movement_state() != &"DISABLED":
		_errors.append("%s did not enter DISABLED after death zone." % definition.id)
	fighter.reset_to_transform(Transform3D(Basis.IDENTITY, Vector3(0, 0.95, 0)))
	_step_fighter(fighter, 90)
	if fighter.get_movement_state() != &"IDLE":
		_errors.append("%s did not return to IDLE after reset." % definition.id)
	var controller: CharacterAnimationController = fighter.get_character_visual().get_animation_controller()
	if not controller.has_action(&"airborne"):
		_errors.append("%s missing airborne animation action." % definition.id)
	_check_animation_runtime(definition, fighter)
	fighter.queue_free()

func _check_animation_runtime(definition: CharacterDefinition, fighter: Fighter) -> void:
	var player: AnimationPlayer = fighter.get_character_visual().get_animation_controller().animation_player
	if player == null:
		_errors.append("%s has no runtime animation player." % definition.id)
		return
	for action_id: StringName in [&"idle", &"walk", &"run"]:
		var action: CharacterAnimationAction = definition.animation_set.get_action(action_id)
		var clip_key := StringName("%s/%s" % [action.library_name, action.clip_name])
		if not player.has_animation(clip_key) or player.get_animation(clip_key).loop_mode == Animation.LOOP_NONE:
			_errors.append("%s action %s is not looped at runtime." % [definition.id, action_id])
	for action_id: StringName in [&"land", &"hit", &"eliminated"]:
		var action: CharacterAnimationAction = definition.animation_set.get_action(action_id)
		var clip_key := StringName("%s/%s" % [action.library_name, action.clip_name])
		if player.has_animation(clip_key) and player.get_animation(clip_key).loop_mode != Animation.LOOP_NONE:
			_errors.append("%s action %s should remain one-shot." % [definition.id, action_id])

func _step_fighter(fighter: Fighter, count: int) -> void:
	for _index: int in count:
		fighter.motor._physics_process(1.0 / 60.0)
		fighter.state_controller._physics_process(1.0 / 60.0)
		fighter.fall_detector._physics_process(1.0 / 60.0)
