class_name CharacterAnimationAction
extends Resource

@export var action_id: StringName
@export var library_name: StringName
@export var clip_name: StringName
@export var required: bool = false
@export var expected_loop_mode: int = Animation.LOOP_NONE
@export var blend_time: float = 0.12
@export var playback_speed: float = 1.0

func is_available() -> bool:
	return not clip_name.is_empty()

