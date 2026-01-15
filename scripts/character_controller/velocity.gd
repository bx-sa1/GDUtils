class_name Velocity extends RefCounted

var vertical: Vector3 = Vector3.ZERO
var horizontal: Vector3 = Vector3.ZERO

func _init(velocity: Vector3 = Vector3.INF, up_direction: Vector3 = Vector3.ZERO) -> void:
	if velocity == Vector3.INF or up_direction == Vector3.ZERO:
		return

	vertical = velocity.project(up_direction)
	horizontal = velocity - vertical

func sum() -> Vector3:
	return vertical + horizontal
