extends Node3D

@onready var status_label: Label = $CanvasLayer/StatusLabel

func _ready() -> void:
	status_label.text = "Debug Playground | F10: restart | F11: overlay"

func _unhandled_input(event: InputEvent) -> void:
	if not AppConfig.debug_mode:
		return
	if event.is_action_pressed("debug_restart"):
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
		var result: Dictionary = SceneRouter.reload_current_scene()
		if not bool(result.get("ok", false)):
			status_label.text = "Restart failed: %s" % String(result.get("error", "Unknown error"))
