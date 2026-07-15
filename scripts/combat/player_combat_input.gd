class_name PlayerCombatInput
extends Node

@export var fighter_path: NodePath = NodePath("..")
@export var input_enabled: bool = true

@onready var fighter: Fighter = get_node(fighter_path) as Fighter

func _unhandled_input(event: InputEvent) -> void:
	if fighter == null or not input_enabled or not fighter.is_player_input_enabled():
		return
	if event.is_action_pressed("primary_action"):
		fighter.request_attack()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
	elif event.is_action_pressed("secondary_action"):
		fighter.request_dash()
		var viewport: Viewport = get_viewport()
		if viewport != null:
			viewport.set_input_as_handled()
