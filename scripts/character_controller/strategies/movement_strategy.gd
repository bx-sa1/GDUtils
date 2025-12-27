@tool
@abstract
class_name MovementStrategy extends Resource

@export var always_active: bool = _init_always_active()
@export var default_active: bool = _init_default_active()
var active_p: Callable = Callable()

func is_active():
	if always_active:
		return true
	if active_p.is_valid():
		return active_p.call()
	return default_active

func apply(character: CharacterController, delta: float, velocity: Velocity, wishdir: Vector3, forward: Vector3, updir: Vector3, is_on_floor: bool, is_on_wall: bool) -> Velocity:
	return velocity

func _init_always_active() -> bool:
	return false

func _init_default_active() -> bool:
	return true
