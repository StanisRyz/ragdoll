class_name FighterAttackController
extends Node

signal attack_phase_changed(phase: StringName)
signal attack_hit_confirmed(hit_data: CombatHitData)

const PHASE_READY: StringName = &"READY"
const PHASE_WINDUP: StringName = &"WINDUP"
const PHASE_ACTIVE: StringName = &"ACTIVE"
const PHASE_RECOVERY: StringName = &"RECOVERY"
const PHASE_COOLDOWN: StringName = &"COOLDOWN"

@export var attack_definition: AttackDefinition

var fighter: Fighter
var action_controller: FighterActionController
var hitbox: FighterHitbox
var phase: StringName = PHASE_READY
var phase_timer: float = 0.0
var cooldown_timer: float = 0.0
var activation_id: int = 0
var attack_direction: Vector3 = Vector3.FORWARD

func configure(owner_fighter: Fighter, controller: FighterActionController, primary_hitbox: FighterHitbox) -> void:
	fighter = owner_fighter
	action_controller = controller
	hitbox = primary_hitbox
	if attack_definition == null:
		attack_definition = preload("res://resources/combat/basic_sweep_attack.tres")
	if hitbox != null:
		hitbox.configure_for_attack(attack_definition)
		if not hitbox.target_hit.is_connected(_on_hitbox_target_hit):
			hitbox.target_hit.connect(_on_hitbox_target_hit)

func _physics_process(delta: float) -> void:
	if fighter == null or attack_definition == null:
		return
	if cooldown_timer > 0.0:
		cooldown_timer = maxf(cooldown_timer - delta, 0.0)
	if phase == PHASE_READY or phase == PHASE_COOLDOWN:
		if phase == PHASE_COOLDOWN and cooldown_timer <= 0.0:
			_set_phase(PHASE_READY)
		return
	phase_timer -= delta
	if phase_timer > 0.0:
		return
	match phase:
		PHASE_WINDUP:
			_enter_active()
		PHASE_ACTIVE:
			_exit_active()
			_set_phase(PHASE_RECOVERY, attack_definition.recovery_duration)
		PHASE_RECOVERY:
			if action_controller != null:
				action_controller.finish_action(FighterActionController.ACTION_PRIMARY_ATTACK)
			fighter.set_locomotion_input_enabled(true)
			fighter.set_facing_rotation_enabled(true)
			cooldown_timer = attack_definition.cooldown
			_set_phase(PHASE_COOLDOWN)

func request_attack() -> bool:
	if fighter == null or action_controller == null or attack_definition == null:
		return false
	if phase != PHASE_READY or cooldown_timer > 0.0:
		return false
	if not action_controller.start_action(FighterActionController.ACTION_PRIMARY_ATTACK):
		return false
	activation_id += 1
	attack_direction = fighter.get_facing_direction()
	fighter.set_locomotion_input_enabled(true)
	fighter.set_locomotion_speed_multiplier(attack_definition.movement_multiplier)
	fighter.set_facing_rotation_enabled(attack_definition.rotation_allowed)
	_set_phase(PHASE_WINDUP, attack_definition.windup_duration)
	return true

func cancel_attack(reason: StringName = &"cancelled") -> void:
	if phase == PHASE_READY:
		return
	if hitbox != null:
		hitbox.end_activation()
	fighter.set_locomotion_speed_multiplier(1.0)
	fighter.set_facing_rotation_enabled(true)
	phase_timer = 0.0
	cooldown_timer = 0.0
	_set_phase(PHASE_READY)
	if action_controller != null and action_controller.get_action_state() == FighterActionController.ACTION_PRIMARY_ATTACK:
		action_controller.cancel_action(reason)

func get_phase() -> StringName:
	return phase

func get_phase_timer() -> float:
	return phase_timer

func get_cooldown_timer() -> float:
	return cooldown_timer

func get_activation_id() -> int:
	return activation_id

func _enter_active() -> void:
	if hitbox != null:
		hitbox.begin_activation(activation_id, attack_direction, attack_definition)
	_set_phase(PHASE_ACTIVE, attack_definition.active_duration)

func _exit_active() -> void:
	if hitbox != null:
		hitbox.end_activation()

func _set_phase(next_phase: StringName, duration: float = 0.0) -> void:
	if phase == next_phase and is_equal_approx(phase_timer, duration):
		return
	phase = next_phase
	phase_timer = duration
	if phase == PHASE_READY:
		fighter.set_locomotion_speed_multiplier(1.0)
	attack_phase_changed.emit(phase)

func _on_hitbox_target_hit(hit_data: CombatHitData) -> void:
	attack_hit_confirmed.emit(hit_data.duplicate_safe())
