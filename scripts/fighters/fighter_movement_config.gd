class_name FighterMovementConfig
extends Resource

@export var maximum_speed: float = 7.0
@export var acceleration: float = 24.0
@export var deceleration: float = 28.0
@export var rotation_speed: float = 10.0
@export var gravity: float = 26.0
@export var maximum_fall_speed: float = 35.0
@export_range(0.0, 1.0) var air_control: float = 0.35
@export var ground_snap_length: float = 0.35
@export var maximum_floor_angle: float = 50.0
@export var walk_animation_threshold: float = 0.25
@export var run_animation_threshold: float = 4.0
@export var stop_speed_epsilon: float = 0.08

