class_name FighterMotor
extends Node

var fighter: Fighter
var config: FighterMovementConfig
var movement_intent: Vector3 = Vector3.ZERO
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
	if not fighter.is_movement_enabled():
		movement_intent = Vector3.ZERO
	var target_horizontal: Vector3 = movement_intent * config.maximum_speed
	var rate: float = config.acceleration if not movement_intent.is_zero_approx() else config.deceleration
	rate *= control_multiplier
	horizontal_velocity = horizontal_velocity.move_toward(target_horizontal, rate * delta)
	if movement_intent.is_zero_approx() and horizontal_velocity.length() <= config.stop_speed_epsilon:
		horizontal_velocity = Vector3.ZERO
	if fighter.is_grounded() and vertical_velocity < 0.0:
		vertical_velocity = -config.ground_snap_length
	else:
		vertical_velocity = maxf(vertical_velocity - config.gravity * delta, -config.maximum_fall_speed)
	fighter.velocity = Vector3(horizontal_velocity.x, vertical_velocity, horizontal_velocity.z)
	fighter.move_and_slide()
	vertical_velocity = fighter.velocity.y
	horizontal_velocity = Vector3(fighter.velocity.x, 0.0, fighter.velocity.z)
	_update_facing(delta)

func set_move_intent(world_direction: Vector3) -> void:
	var flat_direction := Vector3(world_direction.x, 0.0, world_direction.z)
	movement_intent = flat_direction.normalized() if flat_direction.length() > 0.001 else Vector3.ZERO

func clear_move_intent() -> void:
	movement_intent = Vector3.ZERO

func reset_motion() -> void:
	movement_intent = Vector3.ZERO
	horizontal_velocity = Vector3.ZERO
	vertical_velocity = 0.0
	if fighter != null:
		fighter.velocity = Vector3.ZERO

func get_horizontal_speed() -> float:
	return horizontal_velocity.length()

func get_facing_direction() -> Vector3:
	return facing_direction

func _update_facing(delta: float) -> void:
	var desired: Vector3 = horizontal_velocity.normalized()
	if desired.length() <= 0.001:
		return
	facing_direction = facing_direction.slerp(desired, clampf(config.rotation_speed * delta, 0.0, 1.0)).normalized()
	fighter.basis = Basis.looking_at(facing_direction, Vector3.UP)
