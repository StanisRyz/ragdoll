extends Node3D

@onready var visual_arena: ArenaVisualLayers = $ArenaMedievalForest
@onready var arena: ArenaRoot = $ArenaMedievalForest/Physics/ArenaGraybox
@onready var camera: Camera3D = $FreeCamera
@onready var validator: ArenaValidator = $ArenaValidator
@onready var quality_controller: EnvironmentQualityController = $ArenaMedievalForest/QualityController
@onready var report_label: Label = $CanvasLayer/ReportLabel
@onready var status_label: Label = $CanvasLayer/StatusLabel
@onready var camera_label: Label = $CanvasLayer/CameraLabel

func _ready() -> void:
	validator.validation_completed.connect(_on_validation_completed)
	quality_controller.profile_changed.connect(_on_profile_changed)
	validator.validate_arena()
	_update_status()

func _process(_delta: float) -> void:
	if camera.has_method("get_status_text"):
		camera_label.text = camera.get_status_text()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_toggle_quality_profile"):
		quality_controller.toggle_profile()
	elif event.is_action_pressed("debug_toggle_graybox_visuals"):
		visual_arena.toggle_graybox_visuals()
		_update_status()
	elif event.is_action_pressed("debug_toggle_environment_visuals"):
		visual_arena.toggle_environment_visuals()
		_update_status()
	elif event.is_action_pressed("debug_toggle_background"):
		visual_arena.toggle_background()
		_update_status()
	elif event.is_action_pressed("debug_toggle_arena_markers"):
		visual_arena.toggle_debug_markers()
		_update_status()

func _on_validation_completed(errors: PackedStringArray, warnings: PackedStringArray) -> void:
	var lines: PackedStringArray = ["Visual ArenaValidator: %d errors, %d warnings" % [errors.size(), warnings.size()]]
	lines.append_array(errors)
	lines.append_array(warnings)
	report_label.text = "\n".join(lines)
	for message: String in errors:
		push_error("Visual ArenaValidator: %s" % message)
	for message: String in warnings:
		push_warning("Visual ArenaValidator: %s" % message)

func _on_profile_changed(_profile_id: StringName) -> void:
	_update_status()

func _update_status() -> void:
	status_label.text = "Q: quality %s | G: graybox | V: KayKit | B: background | M: markers | %s" % [
		quality_controller.get_active_profile_id(),
		visual_arena.get_status_text(),
	]

