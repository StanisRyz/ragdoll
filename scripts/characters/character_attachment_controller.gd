class_name CharacterAttachmentController
extends Node

var _sockets: Dictionary = {}
var _installed_items: Dictionary = {}
var _warnings: PackedStringArray = []

func configure(sockets: Dictionary) -> void:
	clear_loadout()
	_sockets = sockets

func apply_loadout(loadout: CharacterLoadout) -> PackedStringArray:
	clear_loadout()
	_warnings.clear()
	if loadout == null:
		return _warnings
	for item: CharacterLoadoutItem in loadout.items:
		if item == null:
			continue
		if _installed_items.has(item.visual_id):
			_warnings.append("Duplicate loadout item: %s" % item.visual_id)
			continue
		var socket_node: Node3D = _sockets.get(item.socket, null) as Node3D
		if socket_node == null:
			_warnings.append("Missing attachment socket %s for item %s." % [item.socket, item.visual_id])
			continue
		if item.accessory_prefab == null:
			_warnings.append("Missing prefab for item %s." % item.visual_id)
			continue
		var accessory: Node3D = item.accessory_prefab.instantiate() as Node3D
		if accessory == null:
			_warnings.append("Accessory prefab is not Node3D: %s." % item.visual_id)
			continue
		socket_node.add_child(accessory)
		accessory.transform = item.get_transform()
		_installed_items[item.visual_id] = accessory
	return _warnings

func clear_loadout() -> void:
	for item: Node in _installed_items.values():
		if is_instance_valid(item):
			item.queue_free()
	_installed_items.clear()

func get_installed_item_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for item_id: StringName in _installed_items.keys():
		ids.append(String(item_id))
	return ids

func get_warnings() -> PackedStringArray:
	return _warnings.duplicate()

