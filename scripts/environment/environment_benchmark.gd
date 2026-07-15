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

func _ready() -> void:
	_update_camera(0.0)

func _process(delta: float) -> void:
	_time += delta
	_switch_timer += delta
	_update_camera(_time)
	if _switch_timer >= 8.0:
		_switch_timer = 0.0
		quality_controller.toggle_profile()
	label.text = "EnvironmentBenchmark | FPS %d | profile %s | %s" % [
		Engine.get_frames_per_second(),
		quality_controller.get_active_profile_id(),
		visual_arena.get_status_text(),
	]

func _update_camera(time: float) -> void:
	var position := Vector3(cos(time * orbit_speed) * orbit_radius, orbit_height, sin(time * orbit_speed) * orbit_radius)
	camera.global_position = position
	camera.look_at(Vector3.ZERO, Vector3.UP)

