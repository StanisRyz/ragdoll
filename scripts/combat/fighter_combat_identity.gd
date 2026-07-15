class_name FighterCombatIdentity
extends Node

@export var combatant_id: StringName = &"fighter"
@export var team_id: int = 0
@export var can_receive_hits: bool = true
@export var friendly_fire_enabled: bool = false

func configure(owner_fighter: Fighter) -> void:
	if combatant_id == &"fighter" and owner_fighter != null:
		combatant_id = StringName(owner_fighter.name)

func can_interact_with(other: FighterCombatIdentity) -> bool:
	if other == null:
		return false
	if other == self:
		return false
	if not other.can_receive_hits:
		return false
	if team_id == other.team_id and not friendly_fire_enabled and not other.friendly_fire_enabled:
		return false
	return true

func can_receive_from(source: FighterCombatIdentity) -> bool:
	if not can_receive_hits:
		return false
	if source == null or source == self:
		return false
	if source.team_id == team_id and not friendly_fire_enabled and not source.friendly_fire_enabled:
		return false
	return true
