class_name CharacterLoadoutItem
extends Resource

@export var visual_id: StringName
@export var accessory_prefab: PackedScene
@export_enum("right_hand", "left_hand", "back", "head") var socket: String = "right_hand"
@export var local_position: Vector3 = Vector3.ZERO
@export var local_rotation_degrees: Vector3 = Vector3.ZERO
@export var local_scale: Vector3 = Vector3.ONE

func get_transform() -> Transform3D:
	var basis := Basis.from_euler(Vector3(
		deg_to_rad(local_rotation_degrees.x),
		deg_to_rad(local_rotation_degrees.y),
		deg_to_rad(local_rotation_degrees.z)
	))
	basis = basis.scaled(local_scale)
	return Transform3D(basis, local_position)

