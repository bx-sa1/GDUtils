@tool
class_name HoldStrategy extends MovementStrategy

@export var hold_distance: float = 3
@export var hold_lerp: float = 0.3
@export var mass: float = 60

func apply(character: CharacterController, delta: float, velocity: Velocity, wishdir: Vector3, forward: Vector3, updir: Vector3, is_on_floor: bool, is_on_wall: bool) -> Velocity:
	var current_holding: RigidBody3D = character.current_holding
	if current_holding:
		var head = character.head
		var current_position = current_holding.global_position
		var new_position = head.global_transform.translated_local(Vector3.FORWARD*hold_distance).origin
		current_holding.move_and_collide((new_position - current_position) * hold_lerp)
		current_holding.global_basis = Basis(current_holding.global_basis.get_rotation_quaternion().slerp(head.global_basis.get_rotation_quaternion(), hold_lerp))

		var mass_ratio: float = mass/(mass + current_holding.mass)
		velocity.vertical = mass_ratio * velocity.vertical
		velocity.horizontal = mass_ratio * velocity.horizontal
	return velocity
