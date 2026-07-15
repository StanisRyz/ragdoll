class_name CharacterAnimationController
extends Node

signal one_shot_finished(action_id: StringName, clip_name: StringName)

var animation_set: CharacterAnimationSet
var animation_player: AnimationPlayer
var current_action: StringName
var current_clip_name: StringName
var _one_shot_action: StringName

func configure(player: AnimationPlayer, next_animation_set: CharacterAnimationSet) -> void:
	if animation_player != null and animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.disconnect(_on_animation_finished)
	animation_player = player
	animation_set = next_animation_set
	current_action = &""
	current_clip_name = &""
	if animation_player != null and not animation_player.animation_finished.is_connected(_on_animation_finished):
		animation_player.animation_finished.connect(_on_animation_finished)

func play_action(action_id: StringName, force_one_shot: bool = false) -> bool:
	if animation_player == null or animation_set == null:
		return false
	var action: CharacterAnimationAction = animation_set.get_action(action_id)
	if action == null or not action.is_available():
		return false
	var clip_key: StringName = _resolve_clip_key(action)
	if clip_key.is_empty() or not animation_player.has_animation(clip_key):
		return false
	if current_action == action_id and animation_player.is_playing() and not force_one_shot:
		return true
	animation_player.speed_scale = action.playback_speed
	current_action = action_id
	current_clip_name = clip_key
	_one_shot_action = action_id if force_one_shot or action.expected_loop_mode == Animation.LOOP_NONE else &""
	animation_player.play(clip_key, action.blend_time, action.playback_speed)
	return true

func force_action(action_id: StringName) -> bool:
	current_action = &""
	return play_action(action_id, true)

func has_action(action_id: StringName) -> bool:
	if animation_set == null:
		return false
	var action: CharacterAnimationAction = animation_set.get_action(action_id)
	return action != null and action.is_available()

func stop() -> void:
	if animation_player != null:
		animation_player.stop()
	current_action = &""
	current_clip_name = &""
	_one_shot_action = &""

func set_paused(paused: bool) -> void:
	if animation_player != null:
		if paused:
			animation_player.pause()
		elif not current_clip_name.is_empty():
			animation_player.play(current_clip_name)

func set_playback_speed(speed: float) -> void:
	if animation_player != null:
		animation_player.speed_scale = speed

func get_available_actions() -> PackedStringArray:
	if animation_set == null:
		return PackedStringArray()
	return animation_set.get_available_actions()

func get_current_action() -> StringName:
	return current_action

func get_current_clip_name() -> StringName:
	return current_clip_name

func _resolve_clip_key(action: CharacterAnimationAction) -> StringName:
	var library_prefix: String = String(action.library_name)
	if library_prefix.is_empty():
		return action.clip_name
	return StringName("%s/%s" % [library_prefix, action.clip_name])

func _on_animation_finished(animation_name: StringName) -> void:
	if not _one_shot_action.is_empty() and animation_name == current_clip_name:
		one_shot_finished.emit(_one_shot_action, animation_name)
		_one_shot_action = &""
