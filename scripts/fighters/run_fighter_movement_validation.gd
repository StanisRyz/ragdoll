extends SceneTree

const VALIDATION_SCENE: PackedScene = preload("res://scenes/fighters/FighterMovementValidationTest.tscn")

var _validation: Node

func _initialize() -> void:
	_validation = VALIDATION_SCENE.instantiate()
	_validation.set("quit_on_finish", false)
	root.add_child(_validation)

func _process(_delta: float) -> bool:
	if _validation != null and _validation.get("completed"):
		var code: int = _validation.get("exit_code")
		quit(code)
	return false
