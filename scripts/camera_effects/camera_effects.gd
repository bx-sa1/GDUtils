class_name CameraEffects extends Node

@export var camera: Camera3D
@export var body: CharacterBody3D

var offset: Vector3
var angle: Vector3

func _process(delta: float) -> void:
	offset = Vector3.ZERO
	angle = Vector3.ZERO

	for effect in get_children():
		assert(is_instance_of(effect, CameraEffect))
		if not effect.enabled:
			continue
		var res = effect._calculate(camera, body, delta)
		offset += res.offset
		angle += res.angle

	camera.position = offset
	camera.rotation = angle
