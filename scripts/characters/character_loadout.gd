class_name CharacterLoadout
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var items: Array[CharacterLoadoutItem] = []

func get_item_ids() -> PackedStringArray:
	var ids: PackedStringArray = []
	for item: CharacterLoadoutItem in items:
		if item != null:
			ids.append(String(item.visual_id))
	return ids

