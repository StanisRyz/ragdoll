class_name Fighter
extends CharacterBody3D

signal death_zone_notified(zone_id: String)
signal reset_completed()
signal combat_hit_received(hit_data: CombatHitData)

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
@onready var combat_identity: FighterCombatIdentity = $Components/FighterCombatIdentity
@onready var action_controller: FighterActionController = $Components/FighterActionController
@onready var attack_controller: FighterAttackController = $Components/FighterAttackController
@onready var dash_controller: FighterDashController = $Components/FighterDashController
@onready var action_animation_bridge: FighterActionAnimationBridge = $Components/FighterActionAnimationBridge
@onready var hurtbox: FighterHurtbox = $Hurtbox
@onready var primary_attack_hitbox: FighterHitbox = $HitboxRoot/PrimaryAttackHitbox

var _player_input_enabled: bool = true
var _locomotion_input_enabled: bool = true
var _facing_rotation_enabled: bool = true
var _combat_actions_enabled: bool = true
var _external_physics_movement_enabled: bool = true
var _locomotion_speed_multiplier: float = 1.0

func _ready() -> void:
	if movement_config == null:
		movement_config = preload("res://resources/fighters/default_fighter_movement_config.tres")
	floor_snap_length = movement_config.ground_snap_length
	floor_max_angle = deg_to_rad(movement_config.maximum_floor_angle)
	motor.configure(self, movement_config)
	state_controller.configure(self, movement_config)
	animation_bridge.configure(self, character_visual)
	fall_detector.configure(self)
	combat_identity.configure(self)
	action_controller.configure(self)
	hurtbox.set_owner_fighter(self)
	primary_attack_hitbox.set_owner_fighter(self)
	attack_controller.configure(self, action_controller, primary_attack_hitbox)
	dash_controller.configure(self, action_controller)
	action_animation_bridge.configure(self, character_visual, action_controller)
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
	_player_input_enabled = enabled
	_locomotion_input_enabled = enabled
	_facing_rotation_enabled = enabled
	_combat_actions_enabled = enabled
	_external_physics_movement_enabled = enabled
	if not enabled:
		clear_move_intent()
		cancel_current_actions()
	state_controller.force_refresh()

func is_movement_enabled() -> bool:
	return _player_input_enabled and _locomotion_input_enabled

func set_player_input_enabled(enabled: bool) -> void:
	_player_input_enabled = enabled
	if not enabled:
		clear_move_intent()

func is_player_input_enabled() -> bool:
	return _player_input_enabled

func set_locomotion_input_enabled(enabled: bool) -> void:
	_locomotion_input_enabled = enabled
	if not enabled:
		clear_move_intent()

func is_locomotion_input_enabled() -> bool:
	return _locomotion_input_enabled

func set_facing_rotation_enabled(enabled: bool) -> void:
	_facing_rotation_enabled = enabled

func is_facing_rotation_enabled() -> bool:
	return _facing_rotation_enabled

func set_combat_actions_enabled(enabled: bool) -> void:
	_combat_actions_enabled = enabled
	if not enabled:
		cancel_current_actions()

func are_combat_actions_enabled() -> bool:
	return _combat_actions_enabled

func set_external_physics_movement_enabled(enabled: bool) -> void:
	_external_physics_movement_enabled = enabled

func is_external_physics_movement_enabled() -> bool:
	return _external_physics_movement_enabled

func set_locomotion_speed_multiplier(multiplier: float) -> void:
	_locomotion_speed_multiplier = maxf(multiplier, 0.0)

func get_locomotion_speed_multiplier() -> float:
	return _locomotion_speed_multiplier

func get_movement_state() -> StringName:
	return state_controller.get_state()

func get_horizontal_speed() -> float:
	return motor.get_horizontal_speed()

func is_grounded() -> bool:
	return is_on_floor()

func is_ground_close() -> bool:
	if ground_probe == null:
		return false
	ground_probe.force_raycast_update()
	return ground_probe.is_colliding()

func get_move_intent() -> Vector3:
	return motor.get_move_intent()

func get_horizontal_velocity() -> Vector3:
	return motor.get_horizontal_velocity()

func get_facing_direction() -> Vector3:
	return motor.get_facing_direction()

func get_camera_target() -> Node3D:
	return camera_target

func get_motor() -> FighterMotor:
	return motor

func has_active_action() -> bool:
	return action_controller != null and action_controller.has_active_action()

func cancel_current_actions() -> void:
	if attack_controller != null:
		attack_controller.cancel_attack(&"cancel_current_actions")
	if dash_controller != null:
		dash_controller.cancel_dash(&"cancel_current_actions")
	if action_controller != null:
		action_controller.cancel_action(&"cancel_current_actions")
	if motor != null:
		motor.set_action_velocity(Vector3.ZERO)
	set_locomotion_speed_multiplier(1.0)
	set_facing_rotation_enabled(true)

func request_attack() -> bool:
	if attack_controller == null:
		return false
	return attack_controller.request_attack()

func request_dash() -> bool:
	if dash_controller == null:
		return false
	return dash_controller.request_dash()

func get_character_visual() -> CharacterVisual:
	return character_visual

func notify_death_zone(zone_id: String) -> void:
	death_zone_notified.emit(zone_id)
	cancel_current_actions()
	set_movement_enabled(false)
	fall_detector.notify_death_zone(zone_id)

func notify_combat_hit_received(hit_data: CombatHitData) -> void:
	combat_hit_received.emit(hit_data.duplicate_safe())

func reset_to_transform(target_transform: Transform3D) -> void:
	clear_move_intent()
	cancel_current_actions()
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
	if primary_attack_hitbox != null:
		primary_attack_hitbox.debug_visualization_enabled = enabled

func refresh_locomotion_animation() -> void:
	if animation_bridge != null:
		animation_bridge.refresh_after_definition_change()
