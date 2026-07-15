class_name FighterAnimationBridge
extends Node

var fighter: Fighter
var character_visual: CharacterVisual
var _last_locomotion_action: StringName = &""

func configure(owner_fighter: Fighter, visual: CharacterVisual) -> void:
	fighter = owner_fighter
	character_visual = visual
	fighter.state_controller.state_changed.connect(_on_state_changed)
	if not character_visual.definition_applied.is_connected(_on_definition_applied):
		character_visual.definition_applied.connect(_on_definition_applied)
	var controller: CharacterAnimationController = character_visual.get_animation_controller()
	if not controller.one_shot_finished.is_connected(_on_one_shot_finished):
		controller.one_shot_finished.connect(_on_one_shot_finished)
	refresh_after_definition_change()

func refresh_after_definition_change() -> void:
	_last_locomotion_action = &""
	_play_for_state(fighter.get_movement_state())

func _on_definition_applied(_definition: CharacterDefinition) -> void:
	refresh_after_definition_change()

func _on_state_changed(previous_state: StringName, next_state: StringName) -> void:
	if previous_state == &"AIRBORNE" and next_state != &"AIRBORNE":
		if character_visual.get_animation_controller().has_action(&"land"):
			character_visual.get_animation_controller().force_action(&"land")
			_last_locomotion_action = &""
			return
	_play_for_state(next_state)

func _play_for_state(state: StringName) -> void:
	if fighter.has_active_action():
		return
	var action: StringName = _action_for_state(state)
	if action.is_empty() or action == _last_locomotion_action:
		return
	var controller: CharacterAnimationController = character_visual.get_animation_controller()
	if controller.play_action(action):
		_last_locomotion_action = action
		_sync_speed(action)

func _action_for_state(state: StringName) -> StringName:
	match state:
		&"IDLE":
			return &"idle"
		&"WALKING":
			return &"walk"
		&"RUNNING":
			return &"run"
		&"AIRBORNE":
			return &"airborne"
	return &""

func _sync_speed(action: StringName) -> void:
	if action == &"walk":
		character_visual.get_animation_controller().set_playback_speed(clampf(fighter.get_horizontal_speed() / 3.0, 0.75, 1.35))
	elif action == &"run":
		character_visual.get_animation_controller().set_playback_speed(clampf(fighter.get_horizontal_speed() / 6.0, 0.8, 1.45))

func _on_one_shot_finished(_action_id: StringName, _clip_name: StringName) -> void:
	_play_for_state(fighter.get_movement_state())
