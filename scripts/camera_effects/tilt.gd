class_name Tilt extends CameraEffect

@export var head_tilt_pitch: float = 0.1
@export var head_tilt_roll: float = 0.25
@export var max_head_tilt_pitch: float = 1.0
@export var max_head_tilt_roll: float = 2.5

func _calculate(camera: Camera3D, body: CharacterBody3D, delta: float) -> Result:
	var angle = Vector3.ZERO
	var dir = body.velocity.normalized()
	var speed = body.velocity.length()

	var cam_forward = -camera.global_basis.z
	var cam_right = camera.global_basis.x

	var pitch_dot = dir.dot(cam_forward)
	var head_pitch = clampf(pitch_dot * speed * head_tilt_pitch, -max_head_tilt_pitch, max_head_tilt_pitch)
	angle.x -= deg_to_rad(head_pitch)

	var roll_dot = dir.dot(cam_right)
	var head_roll = clampf(roll_dot * speed * head_tilt_roll, -max_head_tilt_roll, max_head_tilt_roll)
	angle.z -= deg_to_rad(head_roll)

	return Result.new(Vector3.ZERO, angle)
