@tool
class_name JumpStrategy extends MovementStrategy

@export var jump_height: float = 0.3

func _init_default_active() -> bool:
	return false

func apply(character: CharacterController, delta: float, velocity: Velocity, wishdir: Vector3, forward: Vector3, updir: Vector3, is_on_floor: bool, is_on_wall: bool) -> Velocity:
	velocity.vertical = updir * jump_height
	return velocity
