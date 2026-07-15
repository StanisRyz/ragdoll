class_name CharacterDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""
@export var model_scene: PackedScene
@export var visual_scale: float = 1.0
@export var vertical_offset: float = 0.0
@export var forward_rotation_degrees: float = 0.0
@export var animation_set: CharacterAnimationSet
@export var default_loadout: CharacterLoadout
@export var enabled: bool = true

