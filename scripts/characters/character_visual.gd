class_name CharacterVisual
extends Node3D

signal definition_applied(definition: CharacterDefinition)
signal character_error(message: String)

@export var definition: CharacterDefinition

@onready var model_root: Node3D = $ModelRoot
@onready var attachment_root: Node3D = $AttachmentRoot
@onready var debug_visualization: Node3D = $DebugVisualization
@onready var animation_controller: CharacterAnimationController = $CharacterAnimationController
@onready var attachment_controller: CharacterAttachmentController = $CharacterAttachmentController

var _model_instance: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _diagnostics: Dictionary = {}
var _sockets: Dictionary = {}

func _ready() -> void:
	if definition != null:
		apply_definition(definition)

func apply_definition(next_definition: CharacterDefinition) -> bool:
	clear_character()
	definition = next_definition
	_diagnostics = {"errors": PackedStringArray(), "warnings": PackedStringArray()}
	if definition == null:
		_add_error("CharacterVisual received null definition.")
		return false
	if definition.model_scene == null:
		_add_error("%s has no model scene." % definition.id)
		return false
	_model_instance = definition.model_scene.instantiate() as Node3D
	if _model_instance == null:
		_add_error("%s model root is not Node3D." % definition.id)
		return false
	model_root.add_child(_model_instance)
	_model_instance.position.y = definition.vertical_offset
	_model_instance.rotation_degrees.y = definition.forward_rotation_degrees
	_model_instance.scale = Vector3.ONE * definition.visual_scale
	_skeleton = _find_first_node_of_type(_model_instance, "Skeleton3D") as Skeleton3D
	if _skeleton == null:
		_add_error("%s model has no Skeleton3D." % definition.id)
		return false
	_animation_player = _find_or_create_animation_player(_model_instance)
	_attach_shared_animation_libraries()
	animation_controller.configure(_animation_player, definition.animation_set)
	_create_attachment_sockets()
	attachment_controller.configure(_sockets)
	attachment_controller.apply_loadout(definition.default_loadout)
	_build_diagnostics()
	definition_applied.emit(definition)
	return true

func get_definition() -> CharacterDefinition:
	return definition

func get_skeleton() -> Skeleton3D:
	return _skeleton

func get_animation_controller() -> CharacterAnimationController:
	return animation_controller

func get_available_actions() -> PackedStringArray:
	return animation_controller.get_available_actions()

func get_character_height() -> float:
	return float(_diagnostics.get("height", 0.0))

func get_diagnostics() -> Dictionary:
	return _diagnostics.duplicate(true)

func set_debug_visualization_enabled(enabled: bool) -> void:
	debug_visualization.visible = enabled

func clear_character() -> void:
	if attachment_controller != null:
		attachment_controller.clear_loadout()
	_sockets.clear()
	_skeleton = null
	_animation_player = null
	if _model_instance != null and is_instance_valid(_model_instance):
		_model_instance.queue_free()
	_model_instance = null

func apply_loadout(loadout: CharacterLoadout) -> PackedStringArray:
	if attachment_controller == null:
		return PackedStringArray(["Attachment controller is missing."])
	return attachment_controller.apply_loadout(loadout)

func get_socket_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for socket_id: String in _sockets.keys():
		ids.append(socket_id)
	return ids

func _attach_shared_animation_libraries() -> void:
	if _animation_player == null or definition.animation_set == null:
		return
	for library_scene: PackedScene in definition.animation_set.animation_libraries:
		if library_scene == null:
			continue
		var library_root: Node = library_scene.instantiate()
		var source_player: AnimationPlayer = _find_first_node_of_type(library_root, "AnimationPlayer") as AnimationPlayer
		if source_player == null:
			library_root.free()
			continue
		for animation_name: String in source_player.get_animation_list():
			var animation: Animation = source_player.get_animation(animation_name)
			if animation == null:
				continue
			var library_name: StringName = _infer_library_name(library_scene.resource_path)
			var library: AnimationLibrary
			if _animation_player.has_animation_library(library_name):
				library = _animation_player.get_animation_library(library_name)
			else:
				library = AnimationLibrary.new()
				_animation_player.add_animation_library(library_name, library)
			if not library.has_animation(animation_name):
				library.add_animation(animation_name, animation)
		library_root.free()

func _infer_library_name(path: String) -> StringName:
	return StringName(path.get_file().get_basename())

func _create_attachment_sockets() -> void:
	_sockets.clear()
	var socket_bones: Dictionary = {
		"right_hand": "handslot.r",
		"left_hand": "handslot.l",
		"back": "chest",
		"head": "head",
	}
	for socket_id: String in socket_bones.keys():
		var bone_name: String = socket_bones[socket_id]
		if _skeleton.find_bone(bone_name) < 0:
			_diagnostics.warnings.append("Missing bone for socket %s: %s" % [socket_id, bone_name])
			continue
		var socket := BoneAttachment3D.new()
		socket.name = "%sSocket" % socket_id.to_pascal_case()
		socket.bone_name = bone_name
		_skeleton.add_child(socket)
		_sockets[socket_id] = socket

func _find_or_create_animation_player(root: Node) -> AnimationPlayer:
	var player: AnimationPlayer = _find_first_node_of_type(root, "AnimationPlayer") as AnimationPlayer
	if player != null:
		return player
	player = AnimationPlayer.new()
	player.name = "CharacterAnimationPlayer"
	root.add_child(player)
	return player

func _build_diagnostics() -> void:
	var errors: PackedStringArray = _diagnostics.get("errors", PackedStringArray())
	var warnings: PackedStringArray = _diagnostics.get("warnings", PackedStringArray())
	_diagnostics = {
		"id": definition.id if definition != null else &"",
		"display_name": definition.display_name if definition != null else "",
		"skeleton_path": str(_model_instance.get_path_to(_skeleton)) if _model_instance != null and _skeleton != null else "",
		"bone_count": _skeleton.get_bone_count() if _skeleton != null else 0,
		"height": _compute_height(),
		"available_actions": get_available_actions(),
		"missing_required_actions": definition.animation_set.get_missing_required_actions() if definition != null and definition.animation_set != null else PackedStringArray(),
		"loadout": definition.default_loadout.id if definition != null and definition.default_loadout != null else &"",
		"installed_items": attachment_controller.get_installed_item_ids(),
		"sockets": get_socket_ids(),
		"errors": errors,
		"warnings": warnings,
	}
	_diagnostics.warnings.append_array(attachment_controller.get_warnings())

func _compute_height() -> float:
	if _model_instance == null:
		return 0.0
	var bounds := AABB()
	var initialized: bool = false
	for mesh: MeshInstance3D in _collect_mesh_instances(_model_instance):
		if mesh.mesh == null:
			continue
		var transformed: AABB = mesh.global_transform * mesh.mesh.get_aabb()
		if initialized:
			bounds = bounds.merge(transformed)
		else:
			bounds = transformed
			initialized = true
	return bounds.size.y

func _collect_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		meshes.append(root)
	for child: Node in root.get_children():
		meshes.append_array(_collect_mesh_instances(child))
	return meshes

func _find_first_node_of_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child: Node in node.get_children():
		var found: Node = _find_first_node_of_type(child, type_name)
		if found != null:
			return found
	return null

func _add_error(message: String) -> void:
	_diagnostics.errors.append(message)
	character_error.emit(message)
	push_error(message)
