extends Node3D

const PROBE_SCENE: PackedScene = preload("res://scenes/arena/ArenaPhysicsProbe.tscn")

@onready var arena: ArenaRoot = $ArenaGraybox
@onready var camera: Camera3D = $FreeCamera
@onready var validator: ArenaValidator = $ArenaValidator
@onready var report_label: Label = $CanvasLayer/ReportLabel
@onready var status_label: Label = $CanvasLayer/StatusLabel

var _probe: RigidBody3D
var _bot_spawn_index: int = 0

func _ready() -> void:
	validator.validation_completed.connect(_on_validation_completed)
	for zone: ArenaDeathZone in arena.get_death_zones():
		zone.body_entered_death_zone.connect(_on_death_zone_entered)
	validator.validate_arena()
	status_label.text = "WASD/Space/Ctrl: fly | Shift: fast | RMB: cursor | Tab: anchors | 1/2: probe | X: remove | R: reset | M: markers"

func _process(_delta: float) -> void:
	$CanvasLayer/CameraLabel.text = camera.get_status_text()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_spawn_player_probe"):
		_spawn_probe(arena.get_player_spawn_point())
	elif event.is_action_pressed("debug_spawn_bot_probe"):
		var bots: Array[ArenaSpawnPoint] = arena.get_bot_spawn_points()
		if not bots.is_empty():
			_spawn_probe(bots[_bot_spawn_index % bots.size()])
			_bot_spawn_index += 1
	elif event.is_action_pressed("debug_remove_probe"):
		_remove_probe()
	elif event.is_action_pressed("debug_reset_probe") and _probe != null:
		_probe.global_transform = arena.get_player_spawn_point().get_spawn_transform().translated(Vector3.UP * 6.0)
		_probe.reset_motion()
	elif event.is_action_pressed("debug_toggle_arena_markers"):
		arena.set_debug_visualization_enabled(not arena.get_node("DebugVisualization").visible)

func _spawn_probe(spawn: ArenaSpawnPoint) -> void:
	_remove_probe()
	if spawn == null:
		return
	_probe = PROBE_SCENE.instantiate() as RigidBody3D
	add_child(_probe)
	_probe.global_transform = spawn.get_spawn_transform().translated(Vector3.UP * 6.0)
	status_label.text = "Probe created above %s." % spawn.spawn_id

func _remove_probe() -> void:
	if _probe != null:
		_probe.queue_free()
		_probe = null

func _on_death_zone_entered(zone_id: String, body: PhysicsBody3D) -> void:
	if body == _probe:
		status_label.text = "Probe entered DeathZone: %s" % zone_id

func _on_validation_completed(errors: PackedStringArray, warnings: PackedStringArray) -> void:
	var lines: PackedStringArray = ["ArenaValidator: %d errors, %d warnings" % [errors.size(), warnings.size()]]
	lines.append_array(errors)
	lines.append_array(warnings)
	report_label.text = "\n".join(lines)
	for message: String in errors:
		push_error("ArenaValidator: %s" % message)
	for message: String in warnings:
		push_warning("ArenaValidator: %s" % message)
