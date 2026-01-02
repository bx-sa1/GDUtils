@tool
@abstract
class_name MovementStrategy extends Resource

@abstract
func apply(character: CharacterController, delta: float, velocity: Velocity, wishdir: Vector3, forward: Vector3, updir: Vector3, is_on_floor: bool, is_on_wall: bool) -> Velocity
