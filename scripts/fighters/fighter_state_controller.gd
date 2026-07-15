class_name FighterStateController
extends Node

signal state_changed(previous_state: StringName, next_state: StringName)

var fighter: Fighter
var config: FighterMovementConfig
var _state: StringName = &"IDLE"

func configure(owner_fighter: Fighter, movement_config: FighterMovementConfig) -> void:
	fighter = owner_fighter
	config = movement_config

func _physics_process(_delta: float) -> void:
	if fighter == null or config == null:
		return
	var next_state: StringName = _resolve_state()
	set_state(next_state)

func set_state(next_state: StringName) -> void:
	if next_state == _state:
		return
	var previous: StringName = _state
	_state = next_state
	state_changed.emit(previous, next_state)

func force_refresh() -> void:
	if fighter != null and config != null:
		set_state(_resolve_state())

func get_state() -> StringName:
	return _state

func _resolve_state() -> StringName:
	if not fighter.is_movement_enabled():
		return &"DISABLED"
	if not fighter.is_grounded():
		return &"AIRBORNE"
	var speed: float = fighter.get_horizontal_speed()
	if speed >= config.run_animation_threshold:
		return &"RUNNING"
	if speed >= config.walk_animation_threshold:
		return &"WALKING"
	return &"IDLE"
