@tool
@abstract
class_name MovementStrategy extends Resource

class MovementState:
	var velocity: Velocity
	var wishdir: Vector3
	var forward: Vector3
	var updir: Vector3
	var is_on_floor: bool
	var is_on_wall: bool
	var current_holding: Node

@abstract
func apply(state: MovementState, delta: float) -> Velocity
