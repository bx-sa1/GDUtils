class_name Bob extends CameraEffect

@export var enable_head_bob: bool = true
@export var head_bob_frequency: float = 6.0
@export var head_bob_amplitude: float = 0.005
@export var head_bob_pitch: float = 0.05
@export var head_bob_roll: float = 0.025

var _head_bob_phase: float = 0.0

func _calculate(camera: Camera3D, body: CharacterBody3D, delta: float) -> Result:
	var angle = Vector3.ZERO
	var offset = Vector3.ZERO
	var speed = body.velocity.length()

	if speed > 0.1 and body.is_on_floor():
		_head_bob_phase += delta * speed
	else:
		_head_bob_phase = 0.0
	var bob = sin(2.0 * PI * head_bob_frequency + _head_bob_phase)
	angle.x -= bob * speed * deg_to_rad(head_bob_pitch)
	angle.z -= bob * speed * deg_to_rad(head_bob_roll)
	offset += bob * body.up_direction * speed * head_bob_amplitude

	return Result.new(offset, angle)
