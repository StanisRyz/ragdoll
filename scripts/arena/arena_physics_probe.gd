extends RigidBody3D

func reset_motion() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	sleeping = false
