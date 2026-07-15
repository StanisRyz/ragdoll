class_name ArenaHazardSocket
extends Node3D

enum HazardType { SPINNER, FAN, CRANE_WEIGHT, COLLAPSING_SECTION, GENERIC }

@export var socket_id: String = ""
@export var hazard_type: HazardType = HazardType.GENERIC
@export var debug_visualization_enabled: bool = true:
	set(value):
		debug_visualization_enabled = value
		_update_debug_visualization()

func _ready() -> void:
	add_to_group("arena_hazard_sockets")
	_update_debug_visualization()

func get_socket_transform() -> Transform3D:
	return global_transform

func _update_debug_visualization() -> void:
	var debug_node: Node3D = get_node_or_null("DebugVisualization") as Node3D
	if debug_node != null:
		debug_node.visible = debug_visualization_enabled
