class_name CharacterController extends CharacterBody3D

@export var debug = false
@export_category("References")
@export var head: Node3D
@export var body: CollisionShape3D
@export var visual: Node3D
@export_category("Settings")
@export var mass: float = 72
@export var strafe: bool = true
@export var max_step_height: float = 0.2
@export var hold_distance: float = 3
@export var hold_lerp: float = 0.3
@export var ladder_group: String = "ladder"
@export var crouch_height: float = 1.0
@export_category("Movement")
@export_range(0, 100, 0.001, "suffix:m/s") var max_speed: float = 10
@export_range(0, 100, 0.001, "suffix:m/s") var stop_speed: float = 3.125

var _last_forward := Vector3.ZERO
var _last_floor_max_angle = floor_max_angle
var _last_ladder_collision: Dictionary = {}
var _last_ledge_collision: Dictionary = {}
var _last_shape: WeakRef
var crouching = false

var current_holding: RigidBody3D
var current_holding_freeze_mode: RigidBody3D.FreezeMode
var _speed_modifier: float = 1.0


@onready var _normal_height: float = get_height()

const LEDGE_THRESHOLD := 0.1

func slide_and_step(gravity: bool, stepup: bool, push: bool) -> bool:
	var delta = get_physics_process_delta_time() if Engine.is_in_physics_frame() else get_process_delta_time()

	up_direction = -get_gravity().normalized()
	if gravity:
		velocity += get_gravity() * delta

	var vel: Vector3 = velocity
	var fraction: float = 1.0
	var steps: int = 0
	var i: int = 0
	while steps < 4:
		velocity = vel * fraction
		if not move_and_slide():
			return false
		if is_on_floor_only():
			return false

		for c in get_slide_collision_count():
			var sc = get_slide_collision(c)
			var motion = sc.get_travel() + sc.get_remainder()
			var current_fraction = fraction * (sc.get_travel().length()/motion.length())
			# handle step up
			if stepup and is_near_floor() and sc.get_angle(0, up_direction) >= floor_max_angle:
				var step = check_ledge(max_step_height, sc)
				if step:
					var step_height = max_step_height * (1.0 - step.down_fraction)
					if debug:
						print_debug("Forward Fraction: %s" % step.forward_fraction)
						print_debug("Step Height: %s" % step_height)
					if step.forward_fraction >= 1.0:
						global_transform = step.final_transform
						velocity = vel
						continue
					elif step.forward_fraction > current_fraction:
						global_transform = step.final_transform
						fraction -= current_fraction
						steps += 1

			if push:
				push_contact_bodies(sc)

		if steps == i:
			break
		else:
			i += 1

	return true

func set_holding(body: RigidBody3D) -> void:
	if current_holding:
		current_holding.freeze = false
		current_holding.freeze_mode = current_holding_freeze_mode
		current_holding = null
	else:
		current_holding = body
		current_holding.freeze = true
		current_holding_freeze_mode = current_holding.freeze_mode
		current_holding.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

func move_holding() -> void:
	if not current_holding:
		return

	var current_position = current_holding.global_position
	var new_position = head.global_transform.translated_local(Vector3.FORWARD*hold_distance).origin
	current_holding.move_and_collide((new_position - current_position) * hold_lerp)
	current_holding.global_basis = Basis(current_holding.global_basis.get_rotation_quaternion().slerp(head.global_basis.get_rotation_quaternion(), hold_lerp))


func can_crouch() -> bool:
	if is_on_ladder() or is_on_ledge():
		return false
	return true

func can_standup() -> bool:
	if not crouching:
		return false

	var last_height = get_height()
	set_height(_normal_height)
	var params := PhysicsShapeQueryParameters3D.new()
	params.transform = global_transform
	params.shape = body.shape
	params.exclude = [self.get_rid()]
	set_height(last_height)
	var hit = get_world_3d().direct_space_state.get_rest_info(params)
	if hit:
		var adot = up_direction.dot(hit.normal)
		var angle = acos(adot)
		if adot < 0 and angle <= floor_max_angle:
			return false

	return true


func jump(_jump_height: float) -> void:
	var a = PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY)
	var s = _jump_height
	var u = pow(velocity.project(up_direction).length(), 2)
	var v = sqrt(2 * a * s)
	var pb = (mass * velocity) + (mass * v * up_direction)
	var va = pb.length() / (mass*2)
	velocity = pb.normalized() * va


func friction(delta: float, _friction_time: float):
	var vel = velocity
	if is_on_floor():
		vel = vel.slide(up_direction)

	var speed = vel.length()
	if speed < delta:
		if abs(velocity.dot(up_direction)) < 0.00001:
			velocity = Vector3.ZERO
		else:
			velocity = velocity.project(up_direction)
		return

	var drop = 0.0
	if _friction_time > 0.0:
		var control = stop_speed if speed <= stop_speed else speed
		drop += (control / _friction_time) * delta

	var new_speed = speed - drop
	if new_speed < 0:
		new_speed = 0
	velocity *= (new_speed/speed)

func accelerate(wishdir: Vector3, wishspd: float, _accel_time: float, delta: float):
	var currentspeed = velocity.dot(wishdir)
	var addspeed = wishspd - currentspeed
	if addspeed <= 0:
		return
	var accel = (wishspd / _accel_time) * delta
	if accel > addspeed:
		accel = addspeed
	velocity += accel*wishdir


func check_ledge(max_ledge_height: float, slide_collision: KinematicCollision3D) -> Dictionary:
	var transform = global_transform
	var motion = up_direction * max_ledge_height
	var collision: KinematicCollision3D = KinematicCollision3D.new()
	var down_fraction: float = 1.0
	if test_move(transform, motion, collision):
		down_fraction = collision.get_travel().length()/motion.length()


	var forward_fraction: float = 1.0
	transform = transform.translated(motion*down_fraction)
	motion = slide_collision.get_remainder()
	if test_move(transform, motion, collision):
		forward_fraction = collision.get_travel().length()/motion.length()

	transform = transform.translated(motion*forward_fraction)
	motion = -up_direction * max_ledge_height
	down_fraction = 1.0
	if test_move(transform, motion, collision):
		down_fraction = collision.get_travel().length()/motion.length()

	if down_fraction < 1.0:
			return {
				"down_fraction": down_fraction,
				"forward_fraction": forward_fraction,
				"final_transform": transform.translated(collision.get_travel())
				}

	return {}

func push_contact_bodies(slide_collision: KinematicCollision3D) -> bool:
	var c = slide_collision.get_collider()
	if c is RigidBody3D:
		var momentum = mass * velocity + c.mass * c.linear_velocity
		var total_mass = mass*c.mass
		var new_speed = momentum.length()/total_mass
		c.apply_impulse(c.mass * -slide_collision.get_normal() * new_speed, slide_collision.get_position())
		return true
	else:
		return false

func is_near_floor() -> bool:
	if is_on_floor():
		return true

	var bottom = global_position - up_direction * (get_height()/2)
	var transform = global_transform
	var motion = bottom - up_direction * max_step_height
	if not test_move(transform, motion):
		return false

	return true


func get_height() -> float:
	if body.shape is BoxShape3D:
		return body.shape.extents.y * 2
	elif body.shape is SphereShape3D:
		return body.shape.radius * 2
	elif body.shape is CapsuleShape3D:
		return body.shape.height
	elif body.shape is CylinderShape3D:
		return body.shape.height
	else:
		print_debug("Unknown shape type!")
		return 0.0
	return 0.0

func get_visual_angle_to_forward(axis: Vector3) -> float:
	var forward = get_forward()
	var visual_forward = -visual.global_basis.z
	var target_angle := visual_forward.signed_angle_to(forward, axis)
	return target_angle

func get_forward() -> Vector3:
	if strafe:
		return -head.global_basis.z.slide(up_direction)
	else:
		return _last_forward

func get_wishvel(input_axis: Vector2) -> Vector3:
	var wishdir = ((global_basis if strafe else head.global_basis) * Vector3(input_axis.x, 0.0, input_axis.y))
	wishdir = wishdir.slide(up_direction)
	var wishvel = wishdir * max_speed * _speed_modifier
	if wishdir.length() > 0:
		_last_forward = wishdir
	return wishvel

func set_speed_modifier(s: float) -> void:
	_speed_modifier = s

func set_height(height: float) -> void:
	if body.shape is BoxShape3D:
		body.shape.extents.y = height*0.5
	elif body.shape is SphereShape3D:
		body.shape.radius = height*0.5
	elif body.shape is CapsuleShape3D:
		body.shape.height = height
	elif body.shape is CylinderShape3D:
		body.shape.height = height
	else:
		print_debug("Unknown shape type!")

func get_speed_modifier() -> float:
	return _speed_modifier

func is_crouching():
	return crouching

func is_on_ledge() -> bool:
	return _last_ledge_collision != {}

func can_vault_ledge() -> bool:
	return is_on_ledge() and _last_ledge_collision.ledge_height >= max_step_height

func is_on_ladder() -> bool:
	return _last_ladder_collision != {}

func get_ladder_normal() -> Vector3:
	return _last_ladder_collision.normal if is_on_ladder() else Vector3.ZERO
