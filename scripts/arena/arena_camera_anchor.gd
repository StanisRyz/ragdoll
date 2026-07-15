class_name ArenaCameraAnchor
extends Node3D

@export var anchor_id: String = ""
@export var debug_visualization_enabled: bool = true:
	set(value):
		debug_visualization_enabled = value
		_update_debug_visualization()

func _ready() -> void:
	add_to_group("arena_camera_anchors")
	_update_debug_visualization()

func get_camera_transform() -> Transform3D:
	return global_transform

func _update_debug_visualization() -> void:
	var debug_node: Node3D = get_node_or_null("DebugVisualization") as Node3D
	if debug_node != null:
		debug_node.visible = debug_visualization_enabled
