class_name CombatDummy
extends Node3D

signal dummy_hit(hit_data: CombatHitData)

@onready var fighter: Fighter = $Fighter
@onready var status_label: Label3D = $StatusLabel

var hit_count: int = 0
var last_hit_data: CombatHitData

func _ready() -> void:
	fighter.combat_identity.combatant_id = StringName(name)
	fighter.combat_identity.team_id = 1
	fighter.set_player_input_enabled(false)
	fighter.set_locomotion_input_enabled(false)
	fighter.combat_hit_received.connect(_on_fighter_hit)
	_update_label()

func reset_dummy(target_transform: Transform3D) -> void:
	hit_count = 0
	last_hit_data = null
	fighter.reset_to_transform(target_transform)
	fighter.set_player_input_enabled(false)
	fighter.set_locomotion_input_enabled(false)
	_update_label()

func set_team_id(team_id: int) -> void:
	fighter.combat_identity.team_id = team_id
	_update_label()

func get_last_hit_summary() -> String:
	return last_hit_data.to_debug_string() if last_hit_data != null else "<none>"

func _on_fighter_hit(hit_data: CombatHitData) -> void:
	hit_count += 1
	last_hit_data = hit_data.duplicate_safe()
	dummy_hit.emit(last_hit_data)
	_update_label()

func _update_label() -> void:
	if status_label == null or fighter == null or fighter.combat_identity == null:
		return
	status_label.text = "%s\nteam %d\nhits %d" % [name, fighter.combat_identity.team_id, hit_count]
