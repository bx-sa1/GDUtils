@tool
class_name JumpStrategy extends MovementStrategy

@export var jump_action: StringName = "jump"
@export var jump_height: float = 30.0
@export var jump_buffer_time: float = 0.2
@export var cayote_buffer_time: float = 0.1

var jump_buffer: InputBuffer = InputBuffer.new(jump_buffer_time)
var cayote_buffer := InputBuffer.new(cayote_buffer_time)

var is_jumping := false

func apply(state: MovementState, delta: float) -> Velocity:
	var velocity = state.velocity
	var cb = cayote_buffer.update(delta, state.is_on_floor)
	var jb = jump_buffer.update(delta, Input.is_action_just_pressed(jump_action))
	if cb and jb:
		velocity.vertical = state.updir * jump_height
		jump_buffer.reset()
		is_jumping = true

	if Input.is_action_just_released(jump_action) and velocity.vertical.length() > 0:
		velocity.vertical *= 0.5
		cayote_buffer.reset()
		is_jumping = false

	return velocity
