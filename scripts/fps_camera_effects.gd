class_name FPSCameraEffects extends Camera3D

@export var controller: CharacterController
@export_category("Head Bob")
@export var enable_head_bob: bool = true
@export var head_bob_frequency: float = 6.0
@export var head_bob_amplitude: float = 0.005
@export var head_bob_pitch: float = 0.05
@export var head_bob_roll: float = 0.025
@export_category("Head Tilt")
@export var enable_head_tilt: bool = true
@export var head_tilt_pitch: float = 0.1
@export var head_tilt_roll: float = 0.25
@export var max_head_tilt_pitch: float = 1.0
@export var max_head_tilt_roll: float = 2.5
@export_category("Weapon Kick")
@export var enable_weapon_kick: bool = true
@export var weapon_kick_decay: float = 0.5

var offset: Vector3
var angle: Vector3

var _head_bob_phase: float = 0.0
var _weapon_kick_angles: Vector3 = Vector3.ZERO

func _process(delta: float) -> void:
	_calculate(delta)

func _calculate(delta: float) -> void:
	var dir = controller.velocity.normalized()
	var speed = controller.velocity.length()
	offset = Vector3.ZERO
	angle = Vector3.ZERO

	if enable_head_tilt:
		var cam_forward = -global_basis.z
		var cam_right = global_basis.x

		var pitch_dot = dir.dot(cam_forward)
		var head_pitch = clampf(pitch_dot * speed * head_tilt_pitch, -max_head_tilt_pitch, max_head_tilt_pitch)
		angle.x -= deg_to_rad(head_pitch)

		var roll_dot = dir.dot(cam_right)
		var head_roll = clampf(roll_dot * speed * head_tilt_roll, -max_head_tilt_roll, max_head_tilt_roll)
		angle.z -= deg_to_rad(head_roll)

	if enable_head_bob:
		if speed > 0.1 and controller.is_on_floor():
			_head_bob_phase += delta * speed
		else:
			_head_bob_phase = 0.0
		var bob = sin(2.0 * PI * head_bob_frequency + _head_bob_phase)
		angle.x -= bob * speed * deg_to_rad(head_bob_pitch)
		angle.z -= bob * speed * deg_to_rad(head_bob_roll)
		offset += bob * controller.up_direction * speed * head_bob_amplitude

	if enable_weapon_kick:
		_weapon_kick_angles = _weapon_kick_angles.move_toward(Vector3.ZERO, weapon_kick_decay * delta)
		angle += _weapon_kick_angles

	position = offset
	rotation = angle

func _on_weapon_kick(yaw: float, pitch: float):
	_weapon_kick_angles.x += deg_to_rad(pitch)
	_weapon_kick_angles.y += deg_to_rad(yaw)
