class_name Fighter
extends CharacterBody3D

signal death_zone_notified(zone_id: String)
signal reset_completed()

@export var movement_config: FighterMovementConfig
@export var initial_definition: CharacterDefinition

@onready var character_visual: CharacterVisual = $CharacterVisual
@onready var ground_probe: RayCast3D = $GroundProbe
@onready var camera_target: Node3D = $CameraTarget
@onready var debug_visualization: Node3D = $DebugVisualization
@onready var motor: FighterMotor = $Components/FighterMotor
@onready var state_controller: FighterStateController = $Components/FighterStateController
@onready var animation_bridge: FighterAnimationBridge = $Components/FighterAnimationBridge
@onready var fall_detector: FighterFallDetector = $Components/FighterFallDetector

var _movement_enabled: bool = true

func _ready() -> void:
	if movement_config == null:
		movement_config = preload("res://resources/fighters/default_fighter_movement_config.tres")
	motor.configure(self, movement_config)
	state_controller.configure(self, movement_config)
	animation_bridge.configure(self, character_visual)
	fall_detector.configure(self)
	if initial_definition != null:
		set_character_definition(initial_definition)

func set_character_definition(definition: CharacterDefinition) -> void:
	character_visual.apply_definition(definition)
	animation_bridge.refresh_after_definition_change()

func get_character_definition() -> CharacterDefinition:
	return character_visual.get_definition()

func set_move_intent(world_direction: Vector3) -> void:
	motor.set_move_intent(world_direction)

func clear_move_intent() -> void:
	motor.clear_move_intent()

func set_movement_enabled(enabled: bool) -> void:
	_movement_enabled = enabled
	if not enabled:
		clear_move_intent()
	state_controller.force_refresh()

func is_movement_enabled() -> bool:
	return _movement_enabled

func get_movement_state() -> StringName:
	return state_controller.get_state()

func get_horizontal_speed() -> float:
	return motor.get_horizontal_speed()

func is_grounded() -> bool:
	if is_on_floor():
		return true
	if ground_probe != null:
		ground_probe.force_raycast_update()
		return ground_probe.is_colliding()
	return false

func get_character_visual() -> CharacterVisual:
	return character_visual

func notify_death_zone(zone_id: String) -> void:
	death_zone_notified.emit(zone_id)
	fall_detector.notify_death_zone(zone_id)

func reset_to_transform(target_transform: Transform3D) -> void:
	clear_move_intent()
	velocity = Vector3.ZERO
	global_transform = target_transform
	rotation.x = 0.0
	rotation.z = 0.0
	motor.reset_motion()
	fall_detector.reset()
	set_movement_enabled(true)
	state_controller.set_state(&"IDLE")
	animation_bridge.refresh_after_definition_change()
	reset_physics_interpolation()
	reset_completed.emit()

func set_debug_visualization_enabled(enabled: bool) -> void:
	debug_visualization.visible = enabled
	character_visual.set_debug_visualization_enabled(enabled)
