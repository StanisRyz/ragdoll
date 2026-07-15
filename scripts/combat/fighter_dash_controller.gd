class_name FighterDashController
extends Node

signal dash_started()
signal dash_finished()
signal dash_cancelled(reason: StringName)

@export var dash_definition: DashDefinition

var fighter: Fighter
var action_controller: FighterActionController
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_direction: Vector3 = Vector3.FORWARD

func configure(owner_fighter: Fighter, controller: FighterActionController) -> void:
	fighter = owner_fighter
	action_controller = controller
	if dash_definition == null:
		dash_definition = preload("res://resources/combat/default_dash.tres")

func _physics_process(delta: float) -> void:
	if fighter == null or dash_definition == null:
		return
	if cooldown_timer > 0.0:
		cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	if dash_timer <= 0.0:
		return
	dash_timer = maxf(dash_timer - delta, 0.0)
	var intent: Vector3 = fighter.get_move_intent()
	if dash_definition.steering > 0.0 and intent.length() > 0.001:
		dash_direction = dash_direction.slerp(intent.normalized(), dash_definition.steering * delta).normalized()
	fighter.get_motor().set_action_velocity(dash_direction * dash_definition.speed)
	if dash_timer <= 0.0:
		_finish_dash()

func request_dash() -> bool:
	if fighter == null or action_controller == null or dash_definition == null:
		return false
	if cooldown_timer > 0.0 or dash_timer > 0.0:
		return false
	if not action_controller.start_action(FighterActionController.ACTION_DASH):
		return false
	var intent: Vector3 = fighter.get_move_intent()
	dash_direction = intent.normalized() if intent.length() > 0.001 else fighter.get_facing_direction()
	if dash_direction.length() <= 0.001:
		dash_direction = Vector3.FORWARD
	dash_timer = dash_definition.duration
	fighter.set_locomotion_input_enabled(not dash_definition.movement_lock)
	fighter.set_facing_rotation_enabled(dash_definition.rotation_allowed)
	fighter.get_motor().set_action_velocity(dash_direction * dash_definition.speed)
	dash_started.emit()
	return true

func cancel_dash(reason: StringName = &"cancelled") -> void:
	if dash_timer <= 0.0:
		return
	dash_timer = 0.0
	fighter.get_motor().set_action_velocity(Vector3.ZERO)
	fighter.set_locomotion_input_enabled(true)
	fighter.set_facing_rotation_enabled(true)
	if action_controller != null and action_controller.get_action_state() == FighterActionController.ACTION_DASH:
		action_controller.cancel_action(reason)
	dash_cancelled.emit(reason)

func get_dash_timer() -> float:
	return dash_timer

func get_cooldown_timer() -> float:
	return cooldown_timer

func is_dashing() -> bool:
	return dash_timer > 0.0

func _finish_dash() -> void:
	fighter.get_motor().set_action_velocity(Vector3.ZERO)
	fighter.set_locomotion_input_enabled(true)
	fighter.set_facing_rotation_enabled(true)
	cooldown_timer = dash_definition.cooldown
	if action_controller != null:
		action_controller.finish_action(FighterActionController.ACTION_DASH)
	dash_finished.emit()
