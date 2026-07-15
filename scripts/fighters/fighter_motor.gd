class_name FighterMotor
extends Node

var fighter: Fighter
var config: FighterMovementConfig
var movement_intent: Vector3 = Vector3.ZERO
var locomotion_velocity: Vector3 = Vector3.ZERO
var action_velocity: Vector3 = Vector3.ZERO
var external_impulse_velocity: Vector3 = Vector3.ZERO
var horizontal_velocity: Vector3 = Vector3.ZERO
var vertical_velocity: float = 0.0
var facing_direction: Vector3 = Vector3.FORWARD

func configure(owner_fighter: Fighter, movement_config: FighterMovementConfig) -> void:
	fighter = owner_fighter
	config = movement_config

func _physics_process(delta: float) -> void:
	if fighter == null or config == null:
		return
	var control_multiplier: float = 1.0 if fighter.is_grounded() else config.air_control
	if not fighter.is_locomotion_input_enabled():
		movement_intent = Vector3.ZERO
	var target_horizontal: Vector3 = movement_intent * config.maximum_speed * fighter.get_locomotion_speed_multiplier()
	var rate: float = config.acceleration if not movement_intent.is_zero_approx() else config.deceleration
	rate *= control_multiplier
	locomotion_velocity = locomotion_velocity.move_toward(target_horizontal, rate * delta)
	if movement_intent.is_zero_approx() and locomotion_velocity.length() <= config.stop_speed_epsilon:
		locomotion_velocity = Vector3.ZERO
	if fighter.is_grounded() and vertical_velocity < 0.0:
		vertical_velocity = -config.ground_snap_length
	else:
		vertical_velocity = maxf(vertical_velocity - config.gravity * delta, -config.maximum_fall_speed)
	var external_velocity: Vector3 = external_impulse_velocity if fighter.is_external_physics_movement_enabled() else Vector3.ZERO
	horizontal_velocity = locomotion_velocity + action_velocity + external_velocity
	fighter.velocity = Vector3(horizontal_velocity.x, vertical_velocity, horizontal_velocity.z)
	fighter.move_and_slide()
	vertical_velocity = fighter.velocity.y
	horizontal_velocity = Vector3(fighter.velocity.x, 0.0, fighter.velocity.z)
	locomotion_velocity = horizontal_velocity - action_velocity - external_velocity
	_update_facing(delta)

func set_move_intent(world_direction: Vector3) -> void:
	var flat_direction := Vector3(world_direction.x, 0.0, world_direction.z)
	movement_intent = flat_direction.normalized() if flat_direction.length() > 0.001 else Vector3.ZERO

func clear_move_intent() -> void:
	movement_intent = Vector3.ZERO

func reset_motion() -> void:
	movement_intent = Vector3.ZERO
	locomotion_velocity = Vector3.ZERO
	action_velocity = Vector3.ZERO
	external_impulse_velocity = Vector3.ZERO
	horizontal_velocity = Vector3.ZERO
	vertical_velocity = 0.0
	if fighter != null:
		fighter.velocity = Vector3.ZERO

func get_horizontal_speed() -> float:
	return horizontal_velocity.length()

func get_move_intent() -> Vector3:
	return movement_intent

func get_horizontal_velocity() -> Vector3:
	return horizontal_velocity

func get_facing_direction() -> Vector3:
	return facing_direction

func set_action_velocity(next_velocity: Vector3) -> void:
	action_velocity = Vector3(next_velocity.x, 0.0, next_velocity.z)

func get_action_velocity() -> Vector3:
	return action_velocity

func set_external_impulse_velocity(next_velocity: Vector3) -> void:
	external_impulse_velocity = Vector3(next_velocity.x, 0.0, next_velocity.z)

func _update_facing(delta: float) -> void:
	if not fighter.is_facing_rotation_enabled():
		return
	var desired: Vector3 = horizontal_velocity.normalized()
	if desired.length() <= 0.001:
		return
	facing_direction = facing_direction.slerp(desired, clampf(config.rotation_speed * delta, 0.0, 1.0)).normalized()
	fighter.basis = Basis.looking_at(facing_direction, Vector3.UP)
