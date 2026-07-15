class_name CombatHitData
extends RefCounted

var source_fighter: Fighter
var target_fighter: Fighter
var attack_id: StringName
var activation_id: int = 0
var hitbox_id: StringName
var hurtbox_id: StringName
var contact_position: Vector3 = Vector3.ZERO
var attack_direction: Vector3 = Vector3.FORWARD
var base_impulse: float = 0.0
var vertical_impulse: float = 0.0
var source_velocity: Vector3 = Vector3.ZERO
var tags: PackedStringArray = PackedStringArray()

func duplicate_safe() -> CombatHitData:
	var copy := CombatHitData.new()
	copy.source_fighter = source_fighter
	copy.target_fighter = target_fighter
	copy.attack_id = attack_id
	copy.activation_id = activation_id
	copy.hitbox_id = hitbox_id
	copy.hurtbox_id = hurtbox_id
	copy.contact_position = contact_position
	copy.attack_direction = attack_direction
	copy.base_impulse = base_impulse
	copy.vertical_impulse = vertical_impulse
	copy.source_velocity = source_velocity
	copy.tags = tags.duplicate()
	return copy

func to_debug_string() -> String:
	var source_id: String = source_fighter.name if source_fighter != null else "<none>"
	var target_id: String = target_fighter.name if target_fighter != null else "<none>"
	return "%s -> %s | attack=%s activation=%d hitbox=%s hurtbox=%s impulse=%.2f/%.2f" % [
		source_id,
		target_id,
		attack_id,
		activation_id,
		hitbox_id,
		hurtbox_id,
		base_impulse,
		vertical_impulse,
	]
