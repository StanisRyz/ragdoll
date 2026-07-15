class_name EnvironmentQualityController
extends Node

signal profile_changed(profile_id: StringName)

@export var visual_root_path: NodePath
@export var low_profile: EnvironmentQualityProfile
@export var standard_profile: EnvironmentQualityProfile
@export var active_profile_id: StringName = &"standard"

var _active_profile: EnvironmentQualityProfile

func _ready() -> void:
	apply_profile_id(active_profile_id)

func apply_profile_id(profile_id: StringName) -> void:
	active_profile_id = profile_id
	_active_profile = _resolve_profile(profile_id)
	_apply_active_profile()
	profile_changed.emit(active_profile_id)

func toggle_profile() -> void:
	apply_profile_id(&"low" if active_profile_id == &"standard" else &"standard")

func get_active_profile_id() -> StringName:
	return active_profile_id

func _resolve_profile(profile_id: StringName) -> EnvironmentQualityProfile:
	if profile_id == &"low" and low_profile != null:
		return low_profile
	if standard_profile != null:
		return standard_profile
	return low_profile

func _apply_active_profile() -> void:
	var root: Node = get_node_or_null(visual_root_path)
	if root == null:
		root = get_parent()
	_apply_profile_to_branch(root)

func _apply_profile_to_branch(node: Node) -> void:
	if node.has_method("apply_quality_profile"):
		node.apply_quality_profile(_active_profile)
	for child: Node in node.get_children():
		_apply_profile_to_branch(child)

