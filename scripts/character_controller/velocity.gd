class_name Velocity extends RefCounted

var vertical: Vector3 = Vector3.ZERO
var horizontal: Vector3 = Vector3.ZERO

func _init(velocity: Vector3, up_direction: Vector3) -> void:
	vertical = velocity.project(up_direction)
	horizontal = velocity - vertical

func sum() -> Vector3:
	return vertical + horizontal
