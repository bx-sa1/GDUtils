class_name Velocity extends RefCounted

var vertical: Vector3 = Vector3.ZERO
var horizontal: Vector3 = Vector3.ZERO

func sum() -> Vector3:
	return vertical + horizontal
