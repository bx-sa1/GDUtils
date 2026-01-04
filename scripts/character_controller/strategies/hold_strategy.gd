@tool
class_name HoldStrategy extends MovementStrategy

@export var hold_distance: float = 3
@export var hold_lerp: float = 0.3
@export var mass: float = 60

func apply(state: MovementState, delta: float) -> Velocity:
	var velocity = state.velocity
	var current_holding: RigidBody3D = state.current_holding
	if current_holding:
		var mass_ratio: float = mass/(mass + current_holding.mass)
		velocity.vertical = mass_ratio * velocity.vertical
		velocity.horizontal = mass_ratio * velocity.horizontal
	return velocity
