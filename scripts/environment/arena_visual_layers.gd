class_name ArenaVisualLayers
extends Node3D

@export var arena_path: NodePath
@export var graybox_visual_root_path: NodePath
@export var environment_visuals_path: NodePath
@export var background_path: NodePath

var _graybox_visuals_enabled: bool = true
var _environment_visuals_enabled: bool = true
var _background_enabled: bool = true
var _debug_markers_enabled: bool = false

func get_arena_root() -> ArenaRoot:
	return get_node_or_null(arena_path) as ArenaRoot

func set_graybox_visuals_enabled(enabled: bool) -> void:
	_graybox_visuals_enabled = enabled
	var root: Node = get_node_or_null(graybox_visual_root_path)
	if root != null:
		_set_mesh_visibility(root, enabled)

func set_environment_visuals_enabled(enabled: bool) -> void:
	_environment_visuals_enabled = enabled
	var root: Node3D = get_node_or_null(environment_visuals_path) as Node3D
	if root != null:
		root.visible = enabled

func set_background_enabled(enabled: bool) -> void:
	_background_enabled = enabled
	var root: Node3D = get_node_or_null(background_path) as Node3D
	if root != null:
		root.visible = enabled

func set_debug_markers_enabled(enabled: bool) -> void:
	_debug_markers_enabled = enabled
	var arena: ArenaRoot = get_arena_root()
	if arena != null:
		arena.set_debug_visualization_enabled(enabled)

func toggle_graybox_visuals() -> bool:
	set_graybox_visuals_enabled(not _graybox_visuals_enabled)
	return _graybox_visuals_enabled

func toggle_environment_visuals() -> bool:
	set_environment_visuals_enabled(not _environment_visuals_enabled)
	return _environment_visuals_enabled

func toggle_background() -> bool:
	set_background_enabled(not _background_enabled)
	return _background_enabled

func toggle_debug_markers() -> bool:
	set_debug_markers_enabled(not _debug_markers_enabled)
	return _debug_markers_enabled

func get_status_text() -> String:
	return "graybox=%s | kaykit=%s | background=%s | markers=%s" % [
		"on" if _graybox_visuals_enabled else "off",
		"on" if _environment_visuals_enabled else "off",
		"on" if _background_enabled else "off",
		"on" if _debug_markers_enabled else "off",
	]

func _set_mesh_visibility(node: Node, enabled: bool) -> void:
	if node is MeshInstance3D:
		node.visible = enabled
	for child: Node in node.get_children():
		_set_mesh_visibility(child, enabled)

