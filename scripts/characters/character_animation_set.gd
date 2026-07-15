class_name CharacterAnimationSet
extends Resource

@export var id: StringName
@export var animation_libraries: Array[PackedScene] = []
@export var actions: Array[CharacterAnimationAction] = []

func get_action(action_id: StringName) -> CharacterAnimationAction:
	for action: CharacterAnimationAction in actions:
		if action != null and action.action_id == action_id:
			return action
	return null

func get_available_actions() -> PackedStringArray:
	var available: PackedStringArray = []
	for action: CharacterAnimationAction in actions:
		if action != null and action.is_available():
			available.append(String(action.action_id))
	return available

func get_missing_required_actions() -> PackedStringArray:
	var missing: PackedStringArray = []
	for action: CharacterAnimationAction in actions:
		if action != null and action.required and not action.is_available():
			missing.append(String(action.action_id))
	return missing

