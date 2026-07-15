extends Node

@onready var error_label: Label = $CanvasLayer/ErrorLabel

func _ready() -> void:
	call_deferred("_load_start_scene")

func _load_start_scene() -> void:
	var result: Dictionary = SceneRouter.change_to_path(AppConfig.START_SCENE_PATH)
	if not bool(result.get("ok", false)):
		error_label.text = "Bootstrap failed to load the debug playground:\n%s" % String(result.get("error", "Unknown error"))
		error_label.visible = true
