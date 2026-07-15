class_name FighterActionAnimationBridge
extends Node

var fighter: Fighter
var character_visual: CharacterVisual
var action_controller: FighterActionController

func configure(owner_fighter: Fighter, visual: CharacterVisual, controller: FighterActionController) -> void:
	fighter = owner_fighter
	character_visual = visual
	action_controller = controller
	if not action_controller.action_started.is_connected(_on_action_started):
		action_controller.action_started.connect(_on_action_started)
	if not action_controller.action_finished.is_connected(_on_action_finished):
		action_controller.action_finished.connect(_on_action_finished)
	if not action_controller.action_cancelled.is_connected(_on_action_cancelled):
		action_controller.action_cancelled.connect(_on_action_cancelled)
	if not character_visual.definition_applied.is_connected(_on_definition_applied):
		character_visual.definition_applied.connect(_on_definition_applied)

func _on_action_started(action: StringName) -> void:
	var animation_action: StringName = &""
	if action == FighterActionController.ACTION_PRIMARY_ATTACK and fighter.attack_controller != null and fighter.attack_controller.attack_definition != null:
		animation_action = fighter.attack_controller.attack_definition.animation_action
	elif action == FighterActionController.ACTION_DASH and fighter.dash_controller != null and fighter.dash_controller.dash_definition != null:
		animation_action = fighter.dash_controller.dash_definition.animation_action
	if animation_action.is_empty():
		return
	var controller: CharacterAnimationController = character_visual.get_animation_controller()
	if controller.has_action(animation_action):
		controller.force_action(animation_action)

func _on_action_finished(_action: StringName) -> void:
	fighter.refresh_locomotion_animation()

func _on_action_cancelled(_action: StringName, _reason: StringName) -> void:
	fighter.refresh_locomotion_animation()

func _on_definition_applied(_definition: CharacterDefinition) -> void:
	if action_controller != null and action_controller.has_active_action():
		_on_action_started(action_controller.get_action_state())
