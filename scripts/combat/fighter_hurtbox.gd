class_name FighterHurtbox
extends Area3D

signal hit_confirmed(hit_data: CombatHitData)

@export var hurtbox_id: StringName = &"body"
@export var owner_fighter_path: NodePath = NodePath("..")

var owner_fighter: Fighter

func _ready() -> void:
	collision_layer = 8
	collision_mask = 4
	monitoring = true
	monitorable = true
	owner_fighter = get_node_or_null(owner_fighter_path) as Fighter

func set_owner_fighter(next_owner: Fighter) -> void:
	owner_fighter = next_owner

func receive_hit(hit_data: CombatHitData) -> bool:
	if owner_fighter == null or hit_data == null:
		return false
	var source: Fighter = hit_data.source_fighter
	if source == null or source == owner_fighter:
		return false
	if owner_fighter.combat_identity == null:
		return false
	if not owner_fighter.combat_identity.can_receive_from(source.combat_identity):
		return false
	var confirmed: CombatHitData = hit_data.duplicate_safe()
	confirmed.target_fighter = owner_fighter
	confirmed.hurtbox_id = hurtbox_id
	hit_confirmed.emit(confirmed)
	owner_fighter.notify_combat_hit_received(confirmed)
	return true
