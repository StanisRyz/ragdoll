class_name ArenaSpawnPoint
extends Node3D

enum SpawnType { PLAYER, BOT }

@export var spawn_id: String = ""
@export var spawn_type: SpawnType = SpawnType.BOT
@export var debug_visualization_enabled: bool = true:
	set(value):
		debug_visualization_enabled = value
		_update_debug_visualization()

func _ready() -> void:
	add_to_group("arena_spawn_points")
	_update_debug_visualization()

func get_spawn_transform() -> Transform3D:
	return global_transform

func _update_debug_visualization() -> void:
	var debug_node: Node3D = get_node_or_null("DebugVisualization") as Node3D
	if debug_node != null:
		debug_node.visible = debug_visualization_enabled
