class_name ArenaDeathZone
extends Area3D

signal body_entered_death_zone(zone_id: String, body: PhysicsBody3D)

@export var zone_id: String = "main_death_zone"
@export var debug_visualization_enabled: bool = true:
	set(value):
		debug_visualization_enabled = value
		_update_debug_visualization()

func _ready() -> void:
	add_to_group("arena_death_zones")
	body_entered.connect(_on_body_entered)
	_update_debug_visualization()

func _on_body_entered(body: Node3D) -> void:
	if body is PhysicsBody3D:
		body_entered_death_zone.emit(zone_id, body)

func _update_debug_visualization() -> void:
	var debug_mesh: MeshInstance3D = get_node_or_null("DebugVisualization") as MeshInstance3D
	if debug_mesh != null:
		debug_mesh.visible = debug_visualization_enabled
