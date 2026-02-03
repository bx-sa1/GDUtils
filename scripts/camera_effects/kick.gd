class_name Kick extends CameraEffect

@export var enable_weapon_kick: bool = true
@export var weapon_kick_decay: float = 0.5

var _weapon_kick_angles: Vector3 = Vector3.ZERO

func _calculate(camera: Camera3D, body: CharacterBody3D, delta: float) -> Result:
	var angle = Vector3.ZERO

	_weapon_kick_angles = _weapon_kick_angles.move_toward(Vector3.ZERO, weapon_kick_decay * delta)
	angle += _weapon_kick_angles

	return Result.new(Vector3.ZERO, angle)

func _on_weapon_kick(yaw: float, pitch: float):
	_weapon_kick_angles.x += deg_to_rad(pitch)
	_weapon_kick_angles.y += deg_to_rad(yaw)
