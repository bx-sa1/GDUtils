class_name CharacterController extends CharacterBody3D

@export var debug = false
@export_category("References")
@export var head: Node3D
@export var body: CollisionShape3D
@export var coyote_jump_timer: Timer
@export var buffer_jump_timer: Timer
@export_category("Settings")
@export var strafe: bool = true
@export var max_step_height: float = 0.2
@export var hold_distance: float = 3
@export var hold_lerp: float = 0.3
@export_category("Movement")
@export_range(0, 100, 0.001, "suffix:m/s") var max_speed: float = 10
@export_range(0, 100, 0.001, "suffix:m/s") var stop_speed: float = 3.125
@export_range(0, 100, 0.001, "suffix:m/s") var jump_height: float = 1.5
@export_range(0, 1, 0.001, "suffix:s") var friction_time: float = 0.166

var forward_direction := Vector3.ZERO
var _last_forward := Vector3.ZERO
var _last_floor_max_angle = floor_max_angle

var current_holding: RigidBody3D
var current_holding_freeze_mode: RigidBody3D.FreezeMode

const MIN_STEP_HEIGHT := 0.1

func move_and_slide_ext(gravity: bool, stepup: bool, stepdown: bool, push: bool) -> bool:
	var delta = get_physics_process_delta_time() if Engine.is_in_physics_frame() else get_process_delta_time()

	if gravity and not is_on_floor():
		velocity += -up_direction * PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY) * delta

	move_and_slide()

	for i in get_slide_collision_count():
		var sc = get_slide_collision(i)
		if stepup and is_near_floor():
			if handle_step_up(delta, sc): continue
		if push:
			if push_contact_bodies(sc): continue

	return false

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


func check_jump(jump_action: String) -> bool:
	if is_on_floor():
		coyote_jump_timer.start()
	if Input.is_action_just_pressed(jump_action):
		buffer_jump_timer.start()

	if coyote_jump_timer.time_left > 0 and buffer_jump_timer.time_left > 0:
		var addvel = 2 * up_direction * PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY) * jump_height
		addvel = addvel.normalized() * sqrt(addvel.length())
		velocity += addvel
		buffer_jump_timer.stop()

	var vel_vert = velocity.dot(up_direction) * up_direction
	var vel_horiz = velocity - vel_vert
	if Input.is_action_just_released(jump_action) and vel_vert.length() > 0:
		vel_vert *= 0.5
		velocity = vel_vert + vel_horiz
		coyote_jump_timer.stop()

	return true

func friction(delta: float):
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
	if friction_time > 0.0 and is_on_floor():
		var control = stop_speed if speed <= stop_speed else speed
		drop += (control / friction_time) * delta

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

func rotate_body_to_forward() -> void:
	var visual_forward = body.global_basis.z
	var target_angle := visual_forward.signed_angle_to(forward_direction, up_direction)
	body.rotate(up_direction, target_angle)

func push_contact_bodies(slide_collision: KinematicCollision3D) -> bool:
	var c = slide_collision.get_collider()
	if not c is RigidBody3D:
		return false

	c.apply_central_impulse(-slide_collision.get_normal() * 0.8)
	c.apply_impulse(-slide_collision.get_normal() * 0.01, slide_collision.get_position())
	return true


func handle_step_up(delta: float, slide_collision: KinematicCollision3D) -> bool:
	#hack for capsule colliders so they don't slide back down when trying to step up
	floor_max_angle = _last_floor_max_angle
	var angle = slide_collision.get_angle(0, up_direction)
	if angle - rad_to_deg(floor_max_angle) >= 5:
		_last_floor_max_angle = floor_max_angle
		floor_max_angle = angle
	elif angle <= deg_to_rad(floor_max_angle):
		# is not a wall collision
		return false


	# #move up
	var transform = global_transform
	var motion = max_step_height * up_direction
	var dtrace = KinematicCollision3D.new()
	var collided = test_move(transform, motion, dtrace)
	if collided:
		if debug:
			DebugDraw.draw_ray(get_tree(), transform.origin, transform.origin + dtrace.get_travel(), 0.01, 0.02, Color(1,0,0,1), 3)
		return false

	# move towards velocity
	transform = transform.translated(motion)
	motion = slide_collision.get_remainder()
	var strace = KinematicCollision3D.new()
	collided = test_move(transform, motion, strace)
	if collided:
		if debug:
			DebugDraw.draw_ray(get_tree(), transform.origin, transform.origin + strace.get_travel(), 0.01, 0.02, Color(0,1,0,1), 2)

		# try move towards velocity projected onto collision normal plane
		var wall_collision_normal := strace.get_normal()
		transform = transform.translated(wall_collision_normal * 10)
		motion = slide_collision.get_remainder().slide(wall_collision_normal)
		strace = KinematicCollision3D.new()
		collided = test_move(transform, motion, strace)
		if collided:
			if debug:
				DebugDraw.draw_ray(get_tree(), transform.origin, transform.origin + strace.get_travel(), 0.01, 0.02, Color(0,0,1,1), 1)

			return false

	#move down
	transform = transform.translated(motion)
	motion = (max_step_height*-up_direction)
	# motion = strace.get_travel().project(motion)
	dtrace = KinematicCollision3D.new()
	collided = test_move(transform, motion, dtrace)
	if collided:
		var step_height = dtrace.get_remainder().length()
		global_position -= dtrace.get_remainder()
		if debug:
			if debug:
				DebugDraw.draw_ray(get_tree(), transform.origin, transform.origin + dtrace.get_travel(), 0.05, 0.06, Color(0,0,0,1), delta)
			print_debug("Step height is ", step_height)
		return true
	else:
		DebugDraw.draw_ray(get_tree(), transform.origin, transform.origin + motion, 0.01, 0.02, Color(0,0,1,1), 1)


	return false

func is_near_floor() -> bool:
	if is_on_floor():
		return true

	var params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(global_position, global_position - up_direction * 100)
	params.hit_from_inside = true
	var hit = get_world_3d().direct_space_state.intersect_ray(params)
	if not hit:
		return false

	params.from = hit.position
	params.to = hit.position - up_direction * max_step_height
	params.hit_from_inside = false
	hit = get_world_3d().direct_space_state.intersect_ray(params)
	if hit:
		if debug:
			print_debug("Is near floor")
		return true

	return false


func get_forward(wishdir: Vector3) -> Vector3:
	if strafe:
		return -head.global_basis.z.slide(up_direction)
	else:
		if wishdir.length() > 0:
			_last_forward = wishdir
		return _last_forward

func get_wishvel(input_axis: Vector2) -> Vector3:
	var wishdir = ((global_basis if strafe else head.global_basis) * Vector3(input_axis.x, 0.0, input_axis.y))
	wishdir = wishdir.slide(up_direction)
	var wishvel = wishdir * max_speed
	return wishvel
