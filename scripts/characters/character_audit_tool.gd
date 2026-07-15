class_name CharacterAuditTool
extends RefCounted

const CHARACTER_MODEL_PATHS: Dictionary = {
	"barbarian": "res://assets/characters/kaykit/adventurers/Barbarian.glb",
	"knight": "res://assets/characters/kaykit/adventurers/Knight.glb",
	"mage": "res://assets/characters/kaykit/adventurers/Mage.glb",
	"ranger": "res://assets/characters/kaykit/adventurers/Ranger.glb",
	"rogue": "res://assets/characters/kaykit/adventurers/Rogue.glb",
	"rogue_hooded": "res://assets/characters/kaykit/adventurers/Rogue_Hooded.glb",
}

const ANIMATION_LIBRARY_PATHS: Dictionary = {
	"Rig_Medium_General": "res://assets/characters/kaykit/animations/Rig_Medium_General.glb",
	"Rig_Medium_MovementBasic": "res://assets/characters/kaykit/animations/Rig_Medium_MovementBasic.glb",
}

const SOCKET_TO_KEYWORDS: Dictionary = {
	"right_hand": ["hand.r", "r_hand", "right_hand", "handright"],
	"left_hand": ["hand.l", "l_hand", "left_hand", "handleft"],
	"back": ["spine.002", "spine.001", "chest", "spine"],
	"head": ["head"],
}

const BODY_KEYWORDS: Dictionary = {
	"hips": ["hips", "pelvis"],
	"spine": ["spine"],
	"head": ["head"],
	"right_arm": ["upperarm.r", "arm.r", "shoulder.r"],
	"left_arm": ["upperarm.l", "arm.l", "shoulder.l"],
	"right_leg": ["thigh.r", "leg.r", "upperleg.r"],
	"left_leg": ["thigh.l", "leg.l", "upperleg.l"],
}

static func audit_all() -> Dictionary:
	var characters: Dictionary = {}
	for character_id: String in CHARACTER_MODEL_PATHS.keys():
		characters[character_id] = audit_character(character_id, CHARACTER_MODEL_PATHS[character_id])
	var animations: Dictionary = {}
	for library_name: String in ANIMATION_LIBRARY_PATHS.keys():
		animations[library_name] = audit_animation_library(library_name, ANIMATION_LIBRARY_PATHS[library_name], characters)
	return {
		"characters": characters,
		"animations": animations,
		"compatibility": validate_compatibility(characters),
	}

static func audit_character(character_id: String, scene_path: String) -> Dictionary:
	var result: Dictionary = {
		"id": character_id,
		"scene_path": scene_path,
		"errors": PackedStringArray(),
		"warnings": PackedStringArray(),
	}
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		result.errors.append("Could not load model scene.")
		return result
	var root: Node = packed.instantiate()
	result["root_node_path"] = root.name
	var skeleton: Skeleton3D = _find_first_node_of_type(root, "Skeleton3D") as Skeleton3D
	if skeleton == null:
		result.errors.append("Missing Skeleton3D.")
		root.free()
		return result
	var animation_player: AnimationPlayer = _find_first_node_of_type(root, "AnimationPlayer") as AnimationPlayer
	result["skeleton_path"] = str(root.get_path_to(skeleton))
	result["bone_count"] = skeleton.get_bone_count()
	result["bone_names"] = _collect_bone_names(skeleton)
	result["root_bone"] = skeleton.get_bone_name(0) if skeleton.get_bone_count() > 0 else ""
	result["key_bone_hierarchy"] = _collect_key_bone_hierarchy(skeleton)
	result["socket_bones"] = _resolve_socket_bones(skeleton)
	result["body_bones"] = _resolve_body_bones(skeleton)
	result["rest_signatures"] = _collect_rest_signatures(skeleton)
	result["height"] = _compute_height(root)
	result["bottom_y"] = _compute_bottom_y(root)
	result["forward_direction"] = _estimate_forward_direction(root)
	result["has_animation_player"] = animation_player != null
	result["animation_libraries"] = _collect_animation_libraries(animation_player)
	result["materials"] = _collect_materials(root)
	result["textures"] = _collect_textures(root)
	root.free()
	return result

static func audit_animation_library(library_name: String, scene_path: String, characters: Dictionary) -> Dictionary:
	var result: Dictionary = {
		"library_name": library_name,
		"scene_path": scene_path,
		"clips": {},
		"errors": PackedStringArray(),
		"warnings": PackedStringArray(),
	}
	var packed: PackedScene = load(scene_path) as PackedScene
	if packed == null:
		result.errors.append("Could not load animation library scene.")
		return result
	var root: Node = packed.instantiate()
	var animation_player: AnimationPlayer = _find_first_node_of_type(root, "AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		result.errors.append("Animation library scene has no AnimationPlayer.")
		root.free()
		return result
	var animation_list: PackedStringArray = animation_player.get_animation_list()
	for animation_name: String in animation_list:
		var animation: Animation = animation_player.get_animation(animation_name)
		if animation == null:
			continue
		result.clips[animation_name] = _audit_animation_clip(library_name, animation_name, animation, characters)
	root.free()
	return result

static func validate_compatibility(characters: Dictionary) -> Dictionary:
	var errors: PackedStringArray = []
	var warnings: PackedStringArray = []
	var notes: PackedStringArray = []
	var reference_id: String = ""
	var reference_bones: PackedStringArray = []
	var reference_hierarchy: Dictionary = {}
	for character_id: String in characters.keys():
		var character: Dictionary = characters[character_id]
		if character.get("errors", PackedStringArray()).size() > 0:
			errors.append("%s has audit errors." % character_id)
			continue
		if reference_id.is_empty():
			reference_id = character_id
			reference_bones = character.bone_names
			reference_hierarchy = character.key_bone_hierarchy
			continue
		if character.bone_names != reference_bones:
			warnings.append("%s full bone name list differs from %s; validating shared key bones and sockets instead." % [character_id, reference_id])
		for bone_name: String in reference_hierarchy.keys():
			if not character.key_bone_hierarchy.has(bone_name):
				errors.append("%s is missing key bone %s." % [character_id, bone_name])
			elif character.key_bone_hierarchy[bone_name] != reference_hierarchy[bone_name]:
				errors.append("%s key bone hierarchy differs for %s." % [character_id, bone_name])
		for socket_id: String in SOCKET_TO_KEYWORDS.keys():
			if str(character.socket_bones.get(socket_id, "")).is_empty():
				errors.append("%s is missing attachment socket bone for %s." % [character_id, socket_id])
		for body_id: String in BODY_KEYWORDS.keys():
			if str(character.body_bones.get(body_id, "")).is_empty():
				errors.append("%s is missing body bone group %s." % [character_id, body_id])
	if errors.is_empty():
		notes.append("All audited Adventurers share compatible Rig_Medium key bones, socket bones, and key hierarchy.")
	return {"errors": errors, "warnings": warnings, "notes": notes, "reference_character_id": reference_id}

static func _audit_animation_clip(library_name: String, animation_name: String, animation: Animation, characters: Dictionary) -> Dictionary:
	var track_types: PackedStringArray = []
	var target_paths: PackedStringArray = []
	var has_root_motion: bool = false
	for track_index: int in animation.get_track_count():
		track_types.append(str(animation.track_get_type(track_index)))
		var target_path: String = str(animation.track_get_path(track_index))
		target_paths.append(target_path)
		if target_path.to_lower().contains("root") or target_path.to_lower().contains("hips"):
			has_root_motion = true
	return {
		"library_name": library_name,
		"clip_name": animation_name,
		"length": animation.length,
		"loop_mode": animation.loop_mode,
		"track_count": animation.get_track_count(),
		"track_types": track_types,
		"target_paths": target_paths,
		"has_root_motion": has_root_motion,
		"compatible_character_ids": _resolve_clip_compatible_characters(target_paths, characters),
	}

static func _resolve_clip_compatible_characters(target_paths: PackedStringArray, characters: Dictionary) -> PackedStringArray:
	var compatible: PackedStringArray = []
	for character_id: String in characters.keys():
		var character: Dictionary = characters[character_id]
		if character.get("errors", PackedStringArray()).size() > 0:
			continue
		var bone_names: PackedStringArray = character.get("bone_names", PackedStringArray())
		var paths_ok: bool = true
		for target_path: String in target_paths:
			var bone_name: String = _extract_bone_name_from_track_path(target_path)
			if not bone_name.is_empty() and not bone_names.has(bone_name):
				paths_ok = false
				break
		if paths_ok:
			compatible.append(character_id)
	return compatible

static func _extract_bone_name_from_track_path(target_path: String) -> String:
	var marker: String = "Skeleton3D:"
	if target_path.contains(marker):
		return target_path.get_slice(marker, 1).get_slice("/", 0)
	if target_path.contains(":"):
		var candidate: String = target_path.get_slice(":", 1).get_slice("/", 0)
		if not candidate.contains("."):
			return candidate
	return ""

static func _find_first_node_of_type(node: Node, type_name: String) -> Node:
	if node.is_class(type_name):
		return node
	for child: Node in node.get_children():
		var found: Node = _find_first_node_of_type(child, type_name)
		if found != null:
			return found
	return null

static func _collect_bone_names(skeleton: Skeleton3D) -> PackedStringArray:
	var names: PackedStringArray = []
	for index: int in skeleton.get_bone_count():
		names.append(skeleton.get_bone_name(index))
	return names

static func _collect_key_bone_hierarchy(skeleton: Skeleton3D) -> Dictionary:
	var hierarchy: Dictionary = {}
	for index: int in skeleton.get_bone_count():
		var bone_name: String = skeleton.get_bone_name(index)
		if _is_key_bone_name(bone_name):
			var parent_index: int = skeleton.get_bone_parent(index)
			hierarchy[bone_name] = skeleton.get_bone_name(parent_index) if parent_index >= 0 else ""
	return hierarchy

static func _is_key_bone_name(bone_name: String) -> bool:
	var lower_name: String = bone_name.to_lower()
	for keywords: Array in BODY_KEYWORDS.values():
		for keyword: String in keywords:
			if lower_name.contains(keyword):
				return true
	for keywords: Array in SOCKET_TO_KEYWORDS.values():
		for keyword: String in keywords:
			if lower_name.contains(keyword):
				return true
	return false

static func _resolve_socket_bones(skeleton: Skeleton3D) -> Dictionary:
	var sockets: Dictionary = {}
	for socket_id: String in SOCKET_TO_KEYWORDS.keys():
		sockets[socket_id] = _find_bone_by_keywords(skeleton, SOCKET_TO_KEYWORDS[socket_id])
	return sockets

static func _resolve_body_bones(skeleton: Skeleton3D) -> Dictionary:
	var body_bones: Dictionary = {}
	for body_id: String in BODY_KEYWORDS.keys():
		body_bones[body_id] = _find_bone_by_keywords(skeleton, BODY_KEYWORDS[body_id])
	return body_bones

static func _find_bone_by_keywords(skeleton: Skeleton3D, keywords: Array) -> String:
	for index: int in skeleton.get_bone_count():
		var bone_name: String = skeleton.get_bone_name(index)
		var lower_name: String = bone_name.to_lower()
		for keyword: String in keywords:
			if lower_name.contains(keyword):
				return bone_name
	return ""

static func _collect_rest_signatures(skeleton: Skeleton3D) -> Dictionary:
	var signatures: Dictionary = {}
	for index: int in skeleton.get_bone_count():
		var bone_name: String = skeleton.get_bone_name(index)
		var rest: Transform3D = skeleton.get_bone_rest(index)
		signatures[bone_name] = {
			"origin": rest.origin,
			"basis_x": rest.basis.x,
			"basis_y": rest.basis.y,
			"basis_z": rest.basis.z,
		}
	return signatures

static func _compute_height(root: Node) -> float:
	var bounds: AABB = _compute_mesh_bounds(root)
	return bounds.size.y

static func _compute_bottom_y(root: Node) -> float:
	var bounds: AABB = _compute_mesh_bounds(root)
	return bounds.position.y

static func _compute_mesh_bounds(root: Node) -> AABB:
	var bounds := AABB()
	var initialized: bool = false
	var stack: Array[Dictionary] = [{"node": root, "transform": Transform3D.IDENTITY}]
	while not stack.is_empty():
		var entry: Dictionary = stack.pop_back()
		var node: Node = entry.node
		var parent_transform: Transform3D = entry.transform
		var node_transform: Transform3D = parent_transform
		if node is Node3D:
			node_transform = parent_transform * node.transform
		if node is MeshInstance3D and node.mesh != null:
			var local_bounds: AABB = node.mesh.get_aabb()
			var transformed: AABB = node_transform * local_bounds
			if initialized:
				bounds = bounds.merge(transformed)
			else:
				bounds = transformed
				initialized = true
		for child: Node in node.get_children():
			stack.append({"node": child, "transform": node_transform})
	return bounds

static func _estimate_forward_direction(_root: Node) -> String:
	return "-Z"

static func _collect_animation_libraries(animation_player: AnimationPlayer) -> PackedStringArray:
	var libraries: PackedStringArray = []
	if animation_player == null:
		return libraries
	for library_name: StringName in animation_player.get_animation_library_list():
		libraries.append(str(library_name))
	return libraries

static func _collect_materials(root: Node) -> PackedStringArray:
	var materials: PackedStringArray = []
	for mesh_instance: MeshInstance3D in _collect_mesh_instances(root):
		for surface_index: int in mesh_instance.get_surface_override_material_count():
			var material: Material = mesh_instance.get_surface_override_material(surface_index)
			if material != null and not materials.has(material.resource_path):
				materials.append(material.resource_path)
		if mesh_instance.mesh != null:
			for surface_index: int in mesh_instance.mesh.get_surface_count():
				var material: Material = mesh_instance.mesh.surface_get_material(surface_index)
				if material != null and not materials.has(material.resource_path):
					materials.append(material.resource_path)
	return materials

static func _collect_textures(root: Node) -> PackedStringArray:
	var textures: PackedStringArray = []
	for mesh_instance: MeshInstance3D in _collect_mesh_instances(root):
		if mesh_instance.mesh == null:
			continue
		for surface_index: int in mesh_instance.mesh.get_surface_count():
			var material: BaseMaterial3D = mesh_instance.mesh.surface_get_material(surface_index) as BaseMaterial3D
			if material != null and material.albedo_texture != null:
				var texture_path: String = material.albedo_texture.resource_path
				if not textures.has(texture_path):
					textures.append(texture_path)
	return textures

static func _collect_mesh_instances(root: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		if node is MeshInstance3D:
			meshes.append(node)
		for child: Node in node.get_children():
			stack.append(child)
	return meshes
