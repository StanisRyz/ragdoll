class_name FighterFallDetector
extends Node

signal fighter_fell(zone_id: String)

@export var emergency_fall_y: float = -8.0

var fighter: Fighter
var _confirmed: bool = false

func configure(owner_fighter: Fighter) -> void:
	fighter = owner_fighter

func _physics_process(_delta: float) -> void:
	if fighter == null or _confirmed:
		return
	if fighter.global_position.y <= emergency_fall_y:
		_confirm_fall("emergency_y")

func notify_death_zone(zone_id: String) -> void:
	if not _confirmed:
		_confirm_fall(zone_id)

func reset() -> void:
	_confirmed = false

func _confirm_fall(zone_id: String) -> void:
	_confirmed = true
	fighter.set_movement_enabled(false)
	fighter.state_controller.set_state(&"DISABLED")
	fighter_fell.emit(zone_id)

