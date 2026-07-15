extends Control
## Reusable runtime diagnostics; missing monitors degrade to "n/a" rather than erroring.

@onready var metrics_label: Label = $Panel/MetricsLabel

func _ready() -> void:
	set_process(true)

func _process(_delta: float) -> void:
	visible = AppConfig.debug_mode and AppConfig.debug_overlay_visible
	if not visible:
		return
	metrics_label.text = _build_metrics_text()

func _unhandled_input(event: InputEvent) -> void:
	if AppConfig.debug_mode and event.is_action_pressed("debug_toggle_overlay"):
		AppConfig.toggle_debug_overlay()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()

func _build_metrics_text() -> String:
	var current_scene_name: String = "<none>"
	var current_scene: Node = get_tree().current_scene
	if current_scene != null:
		current_scene_name = current_scene.name
	var object_count: Variant = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var run_mode: String = "Web" if AppConfig.is_web_build() else "Desktop"
	if AppConfig.is_editor_tool_context():
		run_mode = "Editor"
	return "FPS: %d / target %d\nScene: %s\nWindow: %s\nRenderer: %s\nMode: %s\nNodes: %s\nDebug: %s" % [
		Engine.get_frames_per_second(),
		AppConfig.TARGET_FPS,
		current_scene_name,
		DisplayServer.window_get_size(),
		ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"),
		run_mode,
		node_count_text(object_count),
		("on" if AppConfig.debug_mode else "off")
	]

func node_count_text(value: Variant) -> String:
	return str(value) if value != null else "n/a"
