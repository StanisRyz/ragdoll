extends Node
## Small technical configuration surface shared by boot and debug-only code.

const TARGET_FPS: int = 60
const DESIGN_VIEWPORT_SIZE: Vector2i = Vector2i(1280, 720)
const START_SCENE_PATH: String = "res://scenes/arena/ArenaGrayboxTest.tscn"

var debug_mode: bool = OS.is_debug_build()
var debug_overlay_visible: bool = true

func is_editor_tool_context() -> bool:
	return Engine.is_editor_hint()

func is_web_build() -> bool:
	return OS.has_feature("web")

func toggle_debug_overlay() -> bool:
	debug_overlay_visible = not debug_overlay_visible
	return debug_overlay_visible
