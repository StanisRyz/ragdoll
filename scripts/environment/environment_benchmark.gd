extends Node3D

@export var orbit_radius: float = 24.0
@export var orbit_height: float = 13.0
@export var orbit_speed: float = 0.28

@onready var visual_arena: ArenaVisualLayers = $ArenaMedievalForest
@onready var quality_controller: EnvironmentQualityController = $ArenaMedievalForest/QualityController
@onready var camera: Camera3D = $Camera3D
@onready var label: Label = $CanvasLayer/BenchmarkLabel

var _time: float = 0.0
var _switch_timer: float = 0.0
var _mode_index: int = 0
var _fps_sum: float = 0.0
var _fps_samples: int = 0
var _min_fps: int = 999999

func _ready() -> void:
	_update_camera(0.0)
	_apply_mode()

func _process(delta: float) -> void:
	_time += delta
	_switch_timer += delta
	_update_camera(_time)
	if _switch_timer >= 8.0:
		_switch_timer = 0.0
		_mode_index = wrapi(_mode_index + 1, 0, 4)
		_apply_mode()
	var fps: int = Engine.get_frames_per_second()
	_fps_sum += fps
	_fps_samples += 1
	_min_fps = mini(_min_fps, fps)
	var metrics: Dictionary = _collect_metrics()
	label.text = "EnvironmentBenchmark | FPS %d avg %.1f min %d | nodes %d | meshes %d visible %d | profile %s | visuals %s | %s" % [
		fps,
		_fps_sum / maxf(1.0, float(_fps_samples)),
		_min_fps,
		metrics.nodes,
		metrics.meshes,
		metrics.visible_meshes,
		quality_controller.get_active_profile_id(),
		"on" if _mode_visuals_enabled() else "off",
		visual_arena.get_status_text(),
	]

func _update_camera(time: float) -> void:
	var position := Vector3(cos(time * orbit_speed) * orbit_radius, orbit_height, sin(time * orbit_speed) * orbit_radius)
	camera.global_position = position
	camera.look_at(Vector3.ZERO, Vector3.UP)

func _apply_mode() -> void:
	match _mode_index:
		0:
			quality_controller.apply_profile_id(&"standard")
			visual_arena.set_environment_visuals_enabled(true)
		1:
			quality_controller.apply_profile_id(&"low")
			visual_arena.set_environment_visuals_enabled(true)
		2:
			quality_controller.apply_profile_id(&"standard")
			visual_arena.set_environment_visuals_enabled(false)
		3:
			quality_controller.apply_profile_id(&"low")
			visual_arena.set_environment_visuals_enabled(false)

func _mode_visuals_enabled() -> bool:
	return _mode_index == 0 or _mode_index == 1

func _collect_metrics() -> Dictionary:
	var metrics: Dictionary = {"nodes": 0, "meshes": 0, "visible_meshes": 0}
	_collect_metrics_recursive($ArenaMedievalForest, metrics)
	return metrics

func _collect_metrics_recursive(node: Node, metrics: Dictionary) -> void:
	metrics.nodes += 1
	if node is MeshInstance3D:
		metrics.meshes += 1
		if node.visible and node.is_visible_in_tree():
			metrics.visible_meshes += 1
	for child: Node in node.get_children():
		_collect_metrics_recursive(child, metrics)
