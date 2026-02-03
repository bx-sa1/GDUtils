@abstract
class_name CameraEffect extends Node

class Result:
	var offset: Vector3
	var angle: Vector3

	func _init(offset, angle) -> void:
		self.offset = offset
		self.angle = angle

@export var enabled: bool = true

@abstract func _calculate(camera: Camera3D, body: CharacterBody3D, delta: float) -> Result
