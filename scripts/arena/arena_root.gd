class_name ArenaRoot
extends Node3D

const REQUIRED_CONTAINERS: PackedStringArray = ["Geometry", "StaticCollision", "SpawnPoints", "HazardSockets", "CameraAnchors", "DeathZones", "Decoration", "DebugVisualization"]

var _player_spawn: ArenaSpawnPoint
var _player_spawn_count: int = 0
var _bot_spawns: Array[ArenaSpawnPoint] = []
var _hazard_sockets: Array[ArenaHazardSocket] = []
var _camera_anchors: Array[ArenaCameraAnchor] = []
var _death_zones: Array[ArenaDeathZone] = []

func _ready() -> void:
	_collect_references()

func get_player_spawn_point() -> ArenaSpawnPoint:
	return _player_spawn

func get_player_spawn_count() -> int:
	return _player_spawn_count

func get_bot_spawn_points() -> Array[ArenaSpawnPoint]:
	return _bot_spawns.duplicate()

func get_hazard_sockets() -> Array[ArenaHazardSocket]:
	return _hazard_sockets.duplicate()

func get_hazard_socket_by_id(socket_id: String) -> ArenaHazardSocket:
	for socket: ArenaHazardSocket in _hazard_sockets:
		if socket.socket_id == socket_id:
			return socket
	return null

func get_camera_anchors() -> Array[ArenaCameraAnchor]:
	return _camera_anchors.duplicate()

func get_camera_anchor_by_id(anchor_id: String) -> ArenaCameraAnchor:
	for anchor: ArenaCameraAnchor in _camera_anchors:
		if anchor.anchor_id == anchor_id:
			return anchor
	return null

func get_death_zones() -> Array[ArenaDeathZone]:
	return _death_zones.duplicate()

func set_debug_visualization_enabled(enabled: bool) -> void:
	for spawn: ArenaSpawnPoint in _all_spawns():
		spawn.debug_visualization_enabled = enabled
	for socket: ArenaHazardSocket in _hazard_sockets:
		socket.debug_visualization_enabled = enabled
	for anchor: ArenaCameraAnchor in _camera_anchors:
		anchor.debug_visualization_enabled = enabled
	for zone: ArenaDeathZone in _death_zones:
		zone.debug_visualization_enabled = enabled
	$DebugVisualization.visible = enabled

func validate_structure() -> Dictionary:
	var errors: PackedStringArray = []
	for container_name: String in REQUIRED_CONTAINERS:
		if get_node_or_null(container_name) == null:
			errors.append("Missing required arena container: %s" % container_name)
	return {"errors": errors, "warnings": PackedStringArray()}

func _collect_references() -> void:
	_player_spawn = null
	_player_spawn_count = 0
	_bot_spawns.clear()
	_hazard_sockets.clear()
	_camera_anchors.clear()
	_death_zones.clear()
	var spawn_container: Node = get_node_or_null("SpawnPoints")
	if spawn_container != null:
		for child: Node in spawn_container.get_children():
			if child is ArenaSpawnPoint:
				if child.spawn_type == ArenaSpawnPoint.SpawnType.PLAYER:
					_player_spawn_count += 1
					_player_spawn = child
				else:
					_bot_spawns.append(child)
	var socket_container: Node = get_node_or_null("HazardSockets")
	if socket_container != null:
		for child: Node in socket_container.get_children():
			if child is ArenaHazardSocket:
				_hazard_sockets.append(child)
	var anchor_container: Node = get_node_or_null("CameraAnchors")
	if anchor_container != null:
		for child: Node in anchor_container.get_children():
			if child is ArenaCameraAnchor:
				_camera_anchors.append(child)
	var zone_container: Node = get_node_or_null("DeathZones")
	if zone_container != null:
		for child: Node in zone_container.get_children():
			if child is ArenaDeathZone:
				_death_zones.append(child)

func _all_spawns() -> Array[ArenaSpawnPoint]:
	var spawns: Array[ArenaSpawnPoint] = _bot_spawns.duplicate()
	if _player_spawn != null:
		spawns.append(_player_spawn)
	return spawns
