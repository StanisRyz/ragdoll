class_name DashDefinition
extends Resource

@export var id: StringName = &"default_dash"
@export var duration: float = 0.18
@export var speed: float = 12.0
@export_range(0.0, 1.0) var steering: float = 0.0
@export var cooldown: float = 0.35
@export var gravity_multiplier: float = 1.0
@export var movement_lock: bool = true
@export var rotation_allowed: bool = true
@export var animation_action: StringName = &"dash"
