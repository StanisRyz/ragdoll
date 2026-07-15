extends Node3D

const CATALOG: CharacterDefinitionCatalog = preload("res://resources/characters/kaykit/character_catalog.tres")

@onready var character_pivot: Node3D = $CharacterPivot
@onready var character_visual: CharacterVisual = $CharacterPivot/CharacterVisual
@onready var fill_light: OmniLight3D = $FillLight
@onready var label: Label = $CanvasLayer/DiagnosticsLabel

var _definitions: Array[CharacterDefinition] = []
var _actions: PackedStringArray = ["idle", "walk", "run", "fall", "hit"]
var _definition_index: int = 0
var _action_index: int = 0
var _speed_index: int = 1
var _speeds: Array[float] = [0.5, 1.0, 1.5]
var _loadout_enabled: bool = true
var _auto_mode: bool = false
var _auto_timer: float = 0.0

func _ready() -> void:
	_definitions = CATALOG.get_enabled_definitions()
	if not _definitions.is_empty():
		_apply_current_definition()
	_update_label()

func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_LEFT):
		character_pivot.rotate_y(delta * 1.5)
	elif Input.is_key_pressed(KEY_RIGHT):
		character_pivot.rotate_y(-delta * 1.5)
	if _auto_mode:
		_auto_timer += delta
		if _auto_timer >= 2.0:
			_auto_timer = 0.0
			_next_auto_step()
	_update_label()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.physical_keycode:
		KEY_TAB:
			_definition_index = wrapi(_definition_index + 1, 0, _definitions.size())
			_apply_current_definition()
		KEY_1:
			_action_index = wrapi(_action_index - 1, 0, _actions.size())
			_play_current_action()
		KEY_2:
			_action_index = wrapi(_action_index + 1, 0, _actions.size())
			_play_current_action()
		KEY_SPACE:
			_play_current_action()
		KEY_S:
			character_visual.get_animation_controller().stop()
		KEY_P:
			_speed_index = wrapi(_speed_index + 1, 0, _speeds.size())
			character_visual.get_animation_controller().set_playback_speed(_speeds[_speed_index])
		KEY_L:
			_loadout_enabled = not _loadout_enabled
			_apply_loadout_state()
		KEY_F:
			fill_light.visible = not fill_light.visible
		KEY_D:
			character_visual.set_debug_visualization_enabled(not character_visual.debug_visualization.visible)
		KEY_A:
			_auto_mode = not _auto_mode
			_auto_timer = 0.0

func _apply_current_definition() -> void:
	if _definitions.is_empty():
		return
	var definition: CharacterDefinition = _definitions[_definition_index]
	character_visual.apply_definition(definition)
	_loadout_enabled = true
	_action_index = 0
	_play_current_action()

func _play_current_action() -> void:
	if _actions.is_empty():
		return
	character_visual.get_animation_controller().play_action(_actions[_action_index])

func _apply_loadout_state() -> void:
	var definition: CharacterDefinition = character_visual.get_definition()
	if _loadout_enabled and definition != null:
		character_visual.apply_loadout(definition.default_loadout)
	else:
		character_visual.attachment_controller.clear_loadout()

func _next_auto_step() -> void:
	_action_index += 1
	if _action_index >= _actions.size():
		_action_index = 0
		_definition_index = wrapi(_definition_index + 1, 0, _definitions.size())
		_apply_current_definition()
	else:
		_play_current_action()

func _update_label() -> void:
	var diagnostics: Dictionary = character_visual.get_diagnostics()
	var controller: CharacterAnimationController = character_visual.get_animation_controller()
	label.text = "\n".join(PackedStringArray([
		"CharacterShowcase",
		"Tab character | 1/2 action | Space play | S stop | P speed | L loadout | F fill light | D debug | A auto | Arrows rotate",
		"Character: %s / %s" % [diagnostics.get("id", ""), diagnostics.get("display_name", "")],
		"Height: %.3f | Bones: %s | Skeleton: %s" % [diagnostics.get("height", 0.0), diagnostics.get("bone_count", 0), diagnostics.get("skeleton_path", "")],
		"Action: %s | Clip: %s | Available: %s" % [controller.get_current_action(), controller.get_current_clip_name(), ", ".join(diagnostics.get("available_actions", PackedStringArray()))],
		"Missing canonical: %s" % ", ".join(diagnostics.get("missing_required_actions", PackedStringArray())),
		"Loadout: %s | Items: %s | Sockets: %s" % [diagnostics.get("loadout", ""), ", ".join(character_visual.attachment_controller.get_installed_item_ids()), ", ".join(diagnostics.get("sockets", PackedStringArray()))],
		"Speed: %.1f | Loadout on: %s | Auto: %s | Fill light: %s" % [_speeds[_speed_index], _loadout_enabled, _auto_mode, fill_light.visible],
		"Errors: %s" % ", ".join(diagnostics.get("errors", PackedStringArray())),
		"Warnings: %s" % ", ".join(diagnostics.get("warnings", PackedStringArray())),
	]))
