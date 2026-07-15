extends Node
## Minimal scene-changing service. It owns no gameplay state or visual transitions.

func change_to_path(scene_path: String) -> Dictionary:
	if scene_path.is_empty():
		return _failure("Scene path is empty.")
	if not ResourceLoader.exists(scene_path, "PackedScene"):
		return _failure("Scene resource does not exist: %s" % scene_path)
	var packed_scene: PackedScene = load(scene_path) as PackedScene
	if packed_scene == null:
		return _failure("Resource is not a PackedScene: %s" % scene_path)
	return change_to_packed(packed_scene)

func change_to_packed(packed_scene: PackedScene) -> Dictionary:
	if packed_scene == null:
		return _failure("PackedScene is null.")
	var error: Error = get_tree().change_scene_to_packed(packed_scene)
	if error != OK:
		return _failure("Godot could not change scene (error %d)." % error)
	return {"ok": true, "error": ""}

func reload_current_scene() -> Dictionary:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null or current_scene.scene_file_path.is_empty():
		return _failure("There is no reloadable current scene.")
	return change_to_path(current_scene.scene_file_path)

func _failure(message: String) -> Dictionary:
	push_error(message)
	return {"ok": false, "error": message}
