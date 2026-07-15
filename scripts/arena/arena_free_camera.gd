extends Camera3D

@export var move_speed: float = 12.0
@export var fast_multiplier: float = 2.5
@export var mouse_sensitivity: float = 0.003
@export var arena_path: NodePath

var _anchor_index: int = -1
var _anchor_name: String = "free"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _process(delta: float) -> void:
	var input_vector: Vector3 = Vector3(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("debug_camera_down", "debug_camera_up"),
		Input.get_axis("move_forward", "move_backward")
	)
	var speed: float = move_speed * (fast_multiplier if Input.is_action_pressed("debug_camera_fast") else 1.0)
	global_position += global_transform.basis * input_vector.normalized() * speed * delta

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_camera_capture"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_VISIBLE
	if event.is_action_pressed("debug_next_anchor"):
		_apply_next_anchor()
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		rotation.x = clampf(rotation.x - event.relative.y * mouse_sensitivity, -1.45, 1.45)

func get_status_text() -> String:
	return "Camera: %s | %s" % [_anchor_name, global_position.round()]

func _apply_next_anchor() -> void:
	var arena: ArenaRoot = get_node_or_null(arena_path) as ArenaRoot
	if arena == null or arena.get_camera_anchors().is_empty():
		return
	var anchors: Array[ArenaCameraAnchor] = arena.get_camera_anchors()
	_anchor_index = (_anchor_index + 1) % anchors.size()
	global_transform = anchors[_anchor_index].get_camera_transform()
	_anchor_name = anchors[_anchor_index].anchor_id
