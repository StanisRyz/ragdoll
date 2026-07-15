class_name PlayerFighterInput
extends Node

@export var fighter_path: NodePath = NodePath("..")
@export var camera_rig_path: NodePath
@export var input_enabled: bool = true

@onready var fighter: Fighter = get_node(fighter_path) as Fighter
var camera_rig: ArenaCameraRig

func _ready() -> void:
	camera_rig = get_node_or_null(camera_rig_path) as ArenaCameraRig

func _physics_process(_delta: float) -> void:
	if fighter == null:
		return
	if not input_enabled or not fighter.is_player_input_enabled() or not fighter.is_locomotion_input_enabled():
		fighter.clear_move_intent()
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_vector.length() <= 0.001:
		fighter.clear_move_intent()
		return
	var forward: Vector3 = Vector3.FORWARD
	var right: Vector3 = Vector3.RIGHT
	if camera_rig != null:
		forward = camera_rig.get_flat_forward()
		right = camera_rig.get_flat_right()
	var intent: Vector3 = (right * input_vector.x + forward * -input_vector.y)
	fighter.set_move_intent(intent.normalized())

func set_camera_rig(rig: ArenaCameraRig) -> void:
	camera_rig = rig
