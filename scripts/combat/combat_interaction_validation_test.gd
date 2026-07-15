extends Node3D

const CATALOG: CharacterDefinitionCatalog = preload("res://resources/characters/kaykit/character_catalog.tres")
const FIGHTER_SCENE: PackedScene = preload("res://scenes/fighters/Fighter.tscn")

@export var quit_on_finish: bool = true

var completed: bool = false
var exit_code: int = 0
var _errors: PackedStringArray = []
var _warnings: PackedStringArray = []

func _ready() -> void:
	print("CombatInteractionValidationTest: ready")
	call_deferred("_run")

func _run() -> void:
	print("CombatInteractionValidationTest: running")
	_create_floor()
	await _validate_attack_flow()
	await _validate_dash_flow()
	_validate_character_definitions()
	print("CombatInteractionValidationTest: %d errors, %d warnings" % [_errors.size(), _warnings.size()])
	for error: String in _errors:
		push_error(error)
	for warning: String in _warnings:
		push_warning(warning)
	exit_code = 1 if not _errors.is_empty() else 0
	completed = true
	if quit_on_finish:
		get_tree().quit(exit_code)

func _validate_attack_flow() -> void:
	var source: Fighter = _spawn_fighter("Source", Vector3(0, 0.2, 0), 0)
	var enemy: Fighter = _spawn_fighter("Enemy", Vector3(0, 0.2, -0.85), 1)
	var friendly: Fighter = _spawn_fighter("Friendly", Vector3(0.65, 0.2, -0.85), 0)
	await _wait_frames(8)
	if source.primary_attack_hitbox.is_enabled():
		_errors.append("Hitbox is enabled outside ACTIVE before attack.")
	if not source.request_attack():
		_errors.append("Source could not start primary attack.")
	if source.request_dash():
		_errors.append("Dash started during attack.")
	if source.primary_attack_hitbox.is_enabled():
		_errors.append("Hitbox enabled during WINDUP.")
	if source.request_attack():
		_errors.append("Recovery/windup allowed repeated attack request.")
	await _wait_frames(10)
	if source.attack_controller.get_phase() != FighterAttackController.PHASE_ACTIVE:
		_errors.append("Attack did not enter ACTIVE phase.")
	if not source.primary_attack_hitbox.is_enabled():
		_errors.append("Hitbox did not enable in ACTIVE.")
	await _wait_frames(8)
	if enemy_hit_count(enemy) != 1:
		_errors.append("Enemy target did not receive exactly one hit in activation.")
	if enemy_hit_count(source) != 0:
		_errors.append("Source hit itself.")
	if enemy_hit_count(friendly) != 0:
		_errors.append("Friendly target was not filtered.")
	if source.primary_attack_hitbox.get_hit_count() != 1:
		_errors.append("Hitbox hit count should be one after enemy hit.")
	await _wait_frames(10)
	if source.primary_attack_hitbox.is_enabled():
		_errors.append("Hitbox remained enabled outside ACTIVE.")
	if source.request_attack():
		_errors.append("Recovery or cooldown allowed immediate repeated attack.")
	await _wait_frames(36)
	if not source.request_attack():
		_errors.append("New activation could not start after cooldown.")
	await _wait_frames(18)
	if enemy_hit_count(enemy) != 2:
		_errors.append("New activation did not allow hitting the enemy again.")
	source.reset_to_transform(Transform3D(Basis.IDENTITY, Vector3(0, 0.2, 0)))
	if source.attack_controller.get_phase() != FighterAttackController.PHASE_READY:
		_errors.append("Reset did not cancel attack.")
	source.request_attack()
	await _wait_frames(4)
	source.notify_death_zone("validation")
	if source.attack_controller.get_phase() != FighterAttackController.PHASE_READY:
		_errors.append("DeathZone did not cancel attack.")
	source.queue_free()
	enemy.queue_free()
	friendly.queue_free()

func _validate_dash_flow() -> void:
	var dasher: Fighter = _spawn_fighter("Dasher", Vector3(3, 0.2, 0), 0)
	dasher.set_move_intent(Vector3.RIGHT)
	await _wait_frames(6)
	if not dasher.request_dash():
		_errors.append("Dash did not start.")
	if dasher.request_attack():
		_errors.append("Attack started during dash.")
	var start_position: Vector3 = dasher.global_position
	await _wait_frames(16)
	if dasher.dash_controller.is_dashing():
		_errors.append("Dash did not finish after duration.")
	var dash_distance: float = dasher.global_position.distance_to(start_position)
	var expected_distance: float = dasher.dash_controller.dash_definition.speed * dasher.dash_controller.dash_definition.duration
	if dash_distance > expected_distance + 0.9:
		_errors.append("Dash exceeded expected distance: %.2f > %.2f." % [dash_distance, expected_distance])
	dasher.reset_to_transform(Transform3D(Basis.IDENTITY, Vector3(9.4, 0.2, 0)))
	dasher.set_move_intent(Vector3.RIGHT)
	await _wait_frames(4)
	var wall_start: Vector3 = dasher.global_position
	dasher.request_dash()
	await _wait_frames(16)
	if dasher.global_position.x > 10.35:
		_errors.append("Dash passed through world edge collision.")
	if dasher.global_position.distance_to(wall_start) > expected_distance + 0.9:
		_errors.append("Wall dash exceeded expected distance tolerance.")
	dasher.request_dash()
	await _wait_frames(2)
	dasher.reset_to_transform(Transform3D(Basis.IDENTITY, Vector3(3, 0.2, 0)))
	if dasher.get_motor().get_action_velocity().length() > 0.001:
		_errors.append("Reset did not clear action velocity.")
	dasher.queue_free()

func _validate_character_definitions() -> void:
	for definition: CharacterDefinition in CATALOG.get_enabled_definitions():
		var fighter: Fighter = FIGHTER_SCENE.instantiate() as Fighter
		add_child(fighter)
		fighter.set_character_definition(definition)
		if fighter.combat_identity == null or fighter.action_controller == null or fighter.attack_controller == null or fighter.dash_controller == null:
			_errors.append("%s missing combat components." % definition.id)
		if fighter.hurtbox == null or fighter.primary_attack_hitbox == null:
			_errors.append("%s missing hitbox/hurtbox." % definition.id)
		fighter.queue_free()

func _spawn_fighter(node_name: String, position: Vector3, team_id: int) -> Fighter:
	var fighter: Fighter = FIGHTER_SCENE.instantiate() as Fighter
	fighter.name = node_name
	add_child(fighter)
	fighter.global_position = position
	fighter.combat_identity.combatant_id = StringName(node_name)
	fighter.combat_identity.team_id = team_id
	fighter.set_player_input_enabled(false)
	fighter.set_meta("validation_hit_count", 0)
	fighter.combat_hit_received.connect(_count_hit.bind(fighter))
	return fighter

func enemy_hit_count(fighter: Fighter) -> int:
	if fighter.has_meta("validation_hit_count"):
		return int(fighter.get_meta("validation_hit_count"))
	return 0

func _count_hit(_hit_data: CombatHitData, fighter: Fighter) -> void:
	var count: int = 0
	if fighter.has_meta("validation_hit_count"):
		count = int(fighter.get_meta("validation_hit_count"))
	fighter.set_meta("validation_hit_count", count + 1)

func _create_floor() -> void:
	var body := StaticBody3D.new()
	body.name = "ValidationFloor"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(24, 0.4, 24)
	shape.shape = box
	body.add_child(shape)
	body.global_position = Vector3(0, -0.2, 0)
	var wall := StaticBody3D.new()
	wall.name = "ValidationWall"
	wall.collision_layer = 1
	wall.collision_mask = 0
	add_child(wall)
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(0.5, 3.0, 8.0)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.global_position = Vector3(10.75, 1.2, 0)

func _wait_frames(count: int) -> void:
	for _index: int in count:
		await get_tree().physics_frame
