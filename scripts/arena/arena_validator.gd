class_name ArenaValidator
extends Node

signal validation_completed(errors: PackedStringArray, warnings: PackedStringArray)

@export var arena_path: NodePath
@export var validation_config: ArenaValidationConfig

func validate_arena() -> Dictionary:
	var errors: PackedStringArray = []
	var warnings: PackedStringArray = []
	var arena: ArenaRoot = get_node_or_null(arena_path) as ArenaRoot
	if arena == null:
		errors.append("ArenaValidator could not find ArenaRoot.")
		return _finish(errors, warnings)
	var structure: Dictionary = arena.validate_structure()
	errors.append_array(structure.get("errors", PackedStringArray()))
	var all_spawns: Array[ArenaSpawnPoint] = arena.get_bot_spawn_points()
	var player: ArenaSpawnPoint = arena.get_player_spawn_point()
	if player == null or arena.get_player_spawn_count() != 1:
		errors.append("Arena must have exactly one player spawn point.")
	else:
		all_spawns.append(player)
	if arena.get_bot_spawn_points().size() < validation_config.minimum_bot_spawn_count:
		errors.append("Arena needs at least %d bot spawns." % validation_config.minimum_bot_spawn_count)
	_validate_unique_ids(all_spawns, "spawn", errors)
	_validate_unique_ids(arena.get_hazard_sockets(), "hazard socket", errors)
	_validate_unique_ids(arena.get_camera_anchors(), "camera anchor", errors)
	_validate_spawn_positions(all_spawns, errors, warnings)
	_validate_death_zones(arena.get_death_zones(), errors)
	_validate_required_anchors(arena.get_camera_anchors(), errors)
	_validate_collision_layers(arena, errors)
	return _finish(errors, warnings)

func _validate_unique_ids(items: Array, label: String, errors: PackedStringArray) -> void:
	var ids: Dictionary = {}
	for item: Node in items:
		var item_id: String = ""
		if item is ArenaSpawnPoint:
			item_id = item.spawn_id
		elif item is ArenaHazardSocket:
			item_id = item.socket_id
		elif item is ArenaCameraAnchor:
			item_id = item.anchor_id
		if item_id.is_empty() or ids.has(item_id):
			errors.append("Duplicate or empty %s ID: %s" % [label, item_id])
		ids[item_id] = true

func _validate_spawn_positions(spawns: Array[ArenaSpawnPoint], errors: PackedStringArray, warnings: PackedStringArray) -> void:
	for first_index: int in spawns.size():
		var first: ArenaSpawnPoint = spawns[first_index]
		var position: Vector3 = first.global_position
		if absf(position.x) > 12.0 - validation_config.minimum_edge_margin or absf(position.z) > 12.0 - validation_config.minimum_edge_margin:
			errors.append("Spawn %s is too close to an open edge." % first.spawn_id)
		if position.y < 0.2:
			warnings.append("Spawn %s should sit slightly above the floor." % first.spawn_id)
		for second_index: int in range(first_index + 1, spawns.size()):
			var second: ArenaSpawnPoint = spawns[second_index]
			if position.distance_to(second.global_position) < validation_config.minimum_spawn_distance:
				errors.append("Spawns %s and %s are too close." % [first.spawn_id, second.spawn_id])

func _validate_death_zones(zones: Array[ArenaDeathZone], errors: PackedStringArray) -> void:
	if zones.is_empty():
		errors.append("Arena needs at least one DeathZone.")
		return
	for zone: ArenaDeathZone in zones:
		if zone.position.y > validation_config.maximum_death_zone_height:
			errors.append("DeathZone %s is not sufficiently below the arena." % zone.zone_id)
		if zone.collision_layer != 32:
			errors.append("DeathZone %s must use the DeathZones layer." % zone.zone_id)

func _validate_required_anchors(anchors: Array[ArenaCameraAnchor], errors: PackedStringArray) -> void:
	var found: Dictionary = {}
	for anchor: ArenaCameraAnchor in anchors:
		found[anchor.anchor_id] = true
	for required_id: String in ["overview", "gameplay_candidate", "top_down_debug"]:
		if not found.has(required_id):
			errors.append("Missing required camera anchor: %s" % required_id)

func _validate_collision_layers(arena: ArenaRoot, errors: PackedStringArray) -> void:
	for body: Node in arena.get_node("StaticCollision").get_children():
		if body is CollisionObject3D and body.collision_layer != 1:
			errors.append("Static arena collision %s must use the World layer." % body.name)

func _finish(errors: PackedStringArray, warnings: PackedStringArray) -> Dictionary:
	validation_completed.emit(errors, warnings)
	return {"errors": errors, "warnings": warnings}
