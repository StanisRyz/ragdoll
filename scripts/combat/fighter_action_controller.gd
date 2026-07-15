class_name FighterActionController
extends Node

signal action_started(action: StringName)
signal action_finished(action: StringName)
signal action_cancelled(action: StringName, reason: StringName)

const ACTION_NONE: StringName = &"NONE"
const ACTION_PRIMARY_ATTACK: StringName = &"PRIMARY_ATTACK"
const ACTION_DASH: StringName = &"DASH"

var fighter: Fighter
var current_action: StringName = ACTION_NONE

func configure(owner_fighter: Fighter) -> void:
	fighter = owner_fighter

func can_start_action(action: StringName) -> bool:
	if fighter == null:
		return false
	if not fighter.are_combat_actions_enabled():
		return false
	if fighter.get_movement_state() == &"DISABLED":
		return false
	if current_action != ACTION_NONE:
		return false
	return action == ACTION_PRIMARY_ATTACK or action == ACTION_DASH

func start_action(action: StringName) -> bool:
	if not can_start_action(action):
		return false
	current_action = action
	action_started.emit(action)
	return true

func finish_action(action: StringName) -> void:
	if current_action != action:
		return
	current_action = ACTION_NONE
	action_finished.emit(action)

func cancel_action(reason: StringName = &"cancelled") -> void:
	if current_action == ACTION_NONE:
		return
	var previous: StringName = current_action
	current_action = ACTION_NONE
	action_cancelled.emit(previous, reason)

func has_active_action() -> bool:
	return current_action != ACTION_NONE

func get_action_state() -> StringName:
	return current_action
