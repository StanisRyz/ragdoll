class_name ArenaCameraRig
extends Node3D

@export var config: ArenaCameraConfig
@export var follow_target_path: NodePath

@onready var follow_root: Node3D = $FollowRoot
@onready var look_target: Node3D = $LookTarget
@onready var spring_arm: SpringArm3D = $FollowRoot/SpringArm3D
@onready var camera: Camera3D = $FollowRoot/SpringArm3D/Camera3D

var follow_target: Fighter

func _ready() -> void:
	if config == null:
		config = preload("res://resources/camera/default_arena_camera_config.tres")
	spring_arm.spring_length = config.spring_arm_length
	camera.fov = clampf((config.minimum_fov + config.maximum_fov) * 0.5, config.minimum_fov, config.maximum_fov)
	if not follow_target_path.is_empty():
		set_follow_target(get_node_or_null(follow_target_path) as Fighter)

func _process(delta: float) -> void:
	if follow_target == null or config == null:
		return
	var target_position: Vector3 = follow_target.camera_target.global_position if follow_target.camera_target != null else follow_target.global_position
	var look_ahead: Vector3 = follow_target.get_velocity() * config.velocity_look_ahead
	look_ahead.y = 0.0
	var biased_target: Vector3 = target_position + look_ahead
	biased_target = biased_target.lerp(Vector3.ZERO, config.arena_center_bias)
	look_target.global_position = look_target.global_position.lerp(biased_target, clampf(config.look_smoothing * delta, 0.0, 1.0))
	var yaw_basis := Basis(Vector3.UP, deg_to_rad(config.yaw_degrees))
	var flat_back: Vector3 = yaw_basis * Vector3.BACK
	var desired_position: Vector3 = target_position + flat_back.normalized() * config.follow_distance + Vector3.UP * config.follow_height
	follow_root.global_position = follow_root.global_position.lerp(desired_position, clampf(config.position_smoothing * delta, 0.0, 1.0))
	follow_root.look_at(look_target.global_position, Vector3.UP)
	follow_root.rotation_degrees.x = config.pitch_degrees

func set_follow_target(target: Fighter) -> void:
	follow_target = target

func get_camera() -> Camera3D:
	return camera

func get_flat_forward() -> Vector3:
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	return forward.normalized() if forward.length() > 0.001 else Vector3.FORWARD

func get_flat_right() -> Vector3:
	var right := camera.global_transform.basis.x
	right.y = 0.0
	return right.normalized() if right.length() > 0.001 else Vector3.RIGHT

