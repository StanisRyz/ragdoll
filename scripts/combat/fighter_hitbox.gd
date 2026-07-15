class_name FighterHitbox
extends Area3D

signal target_hit(hit_data: CombatHitData)

@export var hitbox_id: StringName = &"primary"
@export var owner_fighter_path: NodePath = NodePath("../..")
@export var debug_visualization_enabled: bool = true:
	set(value):
		debug_visualization_enabled = value
		_update_debug_visualization()

var owner_fighter: Fighter
var attack_definition: AttackDefinition
var activation_id: int = 0
var attack_direction: Vector3 = Vector3.FORWARD
var hit_targets: Array[Fighter] = []

func _ready() -> void:
	collision_layer = 4
	collision_mask = 8
	monitorable = false
	area_entered.connect(_on_area_entered)
	owner_fighter = get_node_or_null(owner_fighter_path) as Fighter
	set_enabled(false)
	_update_debug_visualization()

func set_owner_fighter(next_owner: Fighter) -> void:
	owner_fighter = next_owner

func configure_for_attack(definition: AttackDefinition) -> void:
	attack_definition = definition
	if definition == null:
		return
	position = definition.hitbox_offset
	var shape_node: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null and shape_node.shape is BoxShape3D:
		(shape_node.shape as BoxShape3D).size = definition.hitbox_size
	var debug_mesh: MeshInstance3D = get_node_or_null("DebugVisualization") as MeshInstance3D
	if debug_mesh != null and debug_mesh.mesh is BoxMesh:
		(debug_mesh.mesh as BoxMesh).size = definition.hitbox_size

func begin_activation(next_activation_id: int, direction: Vector3, definition: AttackDefinition) -> void:
	activation_id = next_activation_id
	attack_direction = direction.normalized() if direction.length() > 0.001 else Vector3.FORWARD
	hit_targets.clear()
	configure_for_attack(definition)
	set_enabled(true)

func end_activation() -> void:
	set_enabled(false)

func set_enabled(enabled: bool) -> void:
	monitoring = enabled
	visible = enabled or debug_visualization_enabled
	_update_debug_visualization()

func is_enabled() -> bool:
	return monitoring

func get_hit_count() -> int:
	return hit_targets.size()

func reset_hits() -> void:
	hit_targets.clear()

func _on_area_entered(area: Area3D) -> void:
	if not monitoring or owner_fighter == null or attack_definition == null:
		return
	var hurtbox: FighterHurtbox = area as FighterHurtbox
	if hurtbox == null or hurtbox.owner_fighter == null:
		return
	var target: Fighter = hurtbox.owner_fighter
	if target == owner_fighter:
		return
	if hit_targets.has(target):
		return
	if attack_definition.maximum_targets > 0 and hit_targets.size() >= attack_definition.maximum_targets:
		return
	if owner_fighter.combat_identity == null or not owner_fighter.combat_identity.can_interact_with(target.combat_identity):
		return
	var hit_data := CombatHitData.new()
	hit_data.source_fighter = owner_fighter
	hit_data.target_fighter = target
	hit_data.attack_id = attack_definition.id
	hit_data.activation_id = activation_id
	hit_data.hitbox_id = hitbox_id
	hit_data.hurtbox_id = hurtbox.hurtbox_id
	hit_data.contact_position = area.global_position
	hit_data.attack_direction = attack_direction
	hit_data.base_impulse = attack_definition.base_impulse
	hit_data.vertical_impulse = attack_definition.vertical_impulse
	hit_data.source_velocity = owner_fighter.get_horizontal_velocity()
	hit_data.tags = attack_definition.tags.duplicate()
	if hurtbox.receive_hit(hit_data):
		hit_targets.append(target)
		target_hit.emit(hit_data.duplicate_safe())

func _update_debug_visualization() -> void:
	var debug_mesh: MeshInstance3D = get_node_or_null("DebugVisualization") as MeshInstance3D
	if debug_mesh != null:
		debug_mesh.visible = debug_visualization_enabled
