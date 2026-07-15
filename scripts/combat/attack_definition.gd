class_name AttackDefinition
extends Resource

@export var id: StringName = &"basic_sweep"
@export var display_name: String = "Basic Sweep"
@export var windup_duration: float = 0.12
@export var active_duration: float = 0.16
@export var recovery_duration: float = 0.22
@export var cooldown: float = 0.18
@export var movement_multiplier: float = 0.35
@export var rotation_allowed: bool = false
@export var maximum_targets: int = 3
@export var hitbox_offset: Vector3 = Vector3(0.0, 0.95, -0.75)
@export var hitbox_size: Vector3 = Vector3(1.7, 1.25, 1.0)
@export var base_impulse: float = 6.0
@export var vertical_impulse: float = 2.0
@export var animation_action: StringName = &"attack"
@export var tags: PackedStringArray = PackedStringArray(["melee", "sweep", "fallback_animation"])
