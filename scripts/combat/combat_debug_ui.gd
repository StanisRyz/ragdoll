class_name CombatDebugUI
extends Label

@export var fighter_path: NodePath
@export var dummies_root_path: NodePath

var fighter: Fighter
var dummies_root: Node

func _ready() -> void:
	fighter = get_node_or_null(fighter_path) as Fighter
	dummies_root = get_node_or_null(dummies_root_path)

func _process(_delta: float) -> void:
	if fighter == null:
		text = "CombatDebugUI: no fighter"
		return
	var hitbox: FighterHitbox = fighter.primary_attack_hitbox
	var attack: FighterAttackController = fighter.attack_controller
	var dash: FighterDashController = fighter.dash_controller
	var action: FighterActionController = fighter.action_controller
	var last_target: String = "<none>"
	var last_hit: String = "<none>"
	if dummies_root != null:
		for child: Node in dummies_root.get_children():
			if child is CombatDummy and child.last_hit_data != null:
				last_target = child.name
				last_hit = child.last_hit_data.to_debug_string()
	var locks := PackedStringArray([
		"player=%s" % fighter.is_player_input_enabled(),
		"locomotion=%s" % fighter.is_locomotion_input_enabled(),
		"facing=%s" % fighter.is_facing_rotation_enabled(),
		"combat=%s" % fighter.are_combat_actions_enabled(),
		"external=%s" % fighter.is_external_physics_movement_enabled(),
	])
	text = "\n".join(PackedStringArray([
		"CombatInteractionTest | WASD move | LMB attack | RMB dash | R reset | C character | F debug | M arena",
		"locomotion=%s speed=%.2f grounded=%s close_ground=%s" % [fighter.get_movement_state(), fighter.get_horizontal_speed(), fighter.is_grounded(), fighter.is_ground_close()],
		"action=%s attack_phase=%s activation=%d" % [action.get_action_state(), attack.get_phase(), attack.get_activation_id()],
		"attack_timer=%.2f attack_cd=%.2f dash_timer=%.2f dash_cd=%.2f" % [attack.get_phase_timer(), attack.get_cooldown_timer(), dash.get_dash_timer(), dash.get_cooldown_timer()],
		"hitbox=%s hit_count=%d last_target=%s" % [hitbox.is_enabled(), hitbox.get_hit_count(), last_target],
		"last_hit=%s" % last_hit,
		"locks: %s" % ", ".join(locks),
	]))
