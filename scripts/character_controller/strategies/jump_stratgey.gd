@tool
class_name JumpStrategy extends MovementStrategy

@export var jump_action: StringName = "jump"
@export var jump_height: float = 30.0
@export var jump_buffer_time: float = 0.2
@export var cayote_buffer_time: float = 0.1

var jump_buffer: InputBuffer = InputBuffer.new(jump_buffer_time)
var cayote_buffer := InputBuffer.new(cayote_buffer_time)
func apply(character: CharacterController, delta: float, velocity: Velocity, wishdir: Vector3, forward: Vector3, updir: Vector3, is_on_floor: bool, is_on_wall: bool) -> Velocity:
	if cayote_buffer.update(delta, is_on_floor) and\
		jump_buffer.update(delta, Input.is_action_just_pressed(jump_action)):
		velocity.vertical = updir * jump_height
		jump_buffer.reset()

	if Input.is_action_just_released(jump_action) and velocity.vertical.length() > 0:
		velocity.vertical *= 0.5
		cayote_buffer.reset()

	return velocity
