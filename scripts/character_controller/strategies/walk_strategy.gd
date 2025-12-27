@tool
class_name WalkStrategy extends MovementStrategy

@export_range(0, 100, 0.01, "suffix:m/s") var move_speed: float = 32
@export_range(0, 100, 0.01, "suffix:m/s") var stop_speed: float = 10
@export_range(0, 1, 0.001, "suffix:s") var move_accel: float = 0.1
@export_range(0, 1, 0.001, "suffox:s") var air_accel: float = 1
@export_range(0, 1, 0.001, "suffix:s") var friction: float = 0.166

func _init_always_active() -> bool:
	return true

func apply(character: CharacterController, delta: float, velocity: Velocity, wishdir: Vector3, forward: Vector3, updir: Vector3, is_on_floor: bool, is_on_wall: bool) -> Velocity:
	velocity = _friction(is_on_floor, velocity, delta)

	var accel_invtime: float
	if is_on_floor:
		accel_invtime = move_accel
	else:
		accel_invtime = air_accel
	velocity = _accelerate(velocity, wishdir, accel_invtime, delta)
	return velocity

func _accelerate(velocity: Velocity, move_dir: Vector3, accel_time: float, delta: float) -> Velocity:
	var currentspeed = velocity.horizontal.dot(move_dir)
	var addspeed = move_speed - currentspeed
	if addspeed <= 0:
		return velocity
	var accel = (move_speed / accel_time) * delta
	if accel > addspeed:
		accel = addspeed
	velocity.horizontal += accel*move_dir
	return velocity

func _friction(is_on_floor: bool, velocity: Velocity, delta: float) -> Velocity:
	var speed = velocity.horizontal.length()
	if speed < 1.0:
		velocity.horizontal = Vector3.ZERO
		return velocity

	var drop = 0.0
	if is_on_floor:
		var control = stop_speed if speed <= stop_speed else speed
		drop += (control / friction) * delta

	var newspeed = speed - drop
	if newspeed < 0.0:
		newspeed = 0.0
	newspeed /= speed
	velocity.horizontal *= newspeed
	return velocity
