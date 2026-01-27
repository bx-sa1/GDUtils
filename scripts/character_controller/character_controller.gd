class_name CharacterController extends CharacterBody3D

@export var debug = false
@export_category("References")
@export var head: Node3D
@export var body: CollisionShape3D
@export_category("Settings")
@export var strafe: bool = true
@export var max_step_height: float = 0.2
@export var hold_distance: float = 3
@export var hold_lerp: float = 0.3
@export var crouch_height: float = 1.0
@export var crouch_speed_scale: float = 0.5
@export var ladder_group: String = "ladder"
@export var coyote_jump_time: float = 0.1
@export var buffer_jump_time: float = 0.2
@export_category("Movement")
@export_range(0, 100, 0.001, "suffix:m/s") var max_speed: float = 10
@export_range(0, 100, 0.001, "suffix:m/s") var stop_speed: float = 3.125
@export_range(0, 100, 0.001, "suffix:m/s") var jump_height: float = 1.5
@export_range(0, 1, 0.001, "suffix:s") var friction_time: float = 0.166

var forward_direction := Vector3.ZERO
var _last_forward := Vector3.ZERO
var _last_floor_max_angle = floor_max_angle
var _timers: Dictionary[String, Timer]
var _last_ladder_collision: Dictionary = {}
var _last_ledge_collision: Dictionary = {}
var jumping = false
var crouching = false

var current_holding: RigidBody3D
var current_holding_freeze_mode: RigidBody3D.FreezeMode
var speed_modifier: float = 1.0

@onready var _normal_height: float = get_height()

const LEDGE_THRESHOLD := 0.1

func add_timer(name: String, start_time: float) -> Timer:
	if _timers.has(name):
		_timers[name].wait_time = start_time
	else:
		var timer = Timer.new()
		timer.one_shot = true
		timer.autostart = false
		timer.wait_time = start_time
		_timers[name] = timer
		add_child(timer)
	return _timers[name]

func remove_timer(name: String):
	remove_child(_timers[name])
	_timers[name].queue_free()

func get_timer(name: String) -> Timer:
	return _timers.get(name)

func move_and_slide_ext(gravity: bool, stepup: bool, push: bool) -> bool:
	var delta = get_physics_process_delta_time() if Engine.is_in_physics_frame() else get_process_delta_time()

	up_direction = -get_gravity().normalized()
	if gravity and not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()

	_last_ledge_collision = {}
	_last_ladder_collision = {}
	for i in get_slide_collision_count():
		var sc = get_slide_collision(i)

		var on_ledge = check_ledge(sc)
		if on_ledge:
			_last_ledge_collision = on_ledge

		var on_ladder = check_ladder(sc)
		if on_ladder:
			_last_ladder_collision = on_ladder

		if stepup and on_ledge:
			if on_ledge.ledge_height < max_step_height:
				print_debug("Step height is ", on_ledge.ledge_height)
				global_position += up_direction * (on_ledge.ledge_height + LEDGE_THRESHOLD) + sc.get_remainder()
				velocity = get_last_motion()/delta
				_last_ledge_collision = {}

		if push:
			push_contact_bodies(sc)

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


func check_jump(jump_action: String) -> void:
	var coyote_jump_timer = get_timer("coyote_jump")
	var buffer_jump_timer = get_timer("buffer_jump")
	if not coyote_jump_timer or not buffer_jump_timer:
		coyote_jump_timer = add_timer("coyote_jump", coyote_jump_time)
		buffer_jump_timer = add_timer("buffer_jump", buffer_jump_time)

	if is_on_floor():
		jumping = false
		coyote_jump_timer.start()
	if Input.is_action_just_pressed(jump_action):
		buffer_jump_timer.start()

	if coyote_jump_timer.time_left > 0 and buffer_jump_timer.time_left > 0:
		jump()
		buffer_jump_timer.stop()
		jumping = true

	var vel_vert = velocity.dot(up_direction) * up_direction
	var vel_horiz = velocity - vel_vert
	if Input.is_action_just_released(jump_action) and jumping:
		vel_vert *= 0.5
		velocity = vel_vert + vel_horiz
		coyote_jump_timer.stop()

func check_crouch(crouch_action: String) -> void:
	if Input.is_action_pressed(crouch_action) and not is_on_ladder() and not is_on_ledge():
		crouching = true
	elif crouching and is_on_ceiling():
		crouching = true
	else:
		crouching = false

	var height
	if crouching:
		speed_modifier = crouch_speed_scale
		height = crouch_height
	else:
		speed_modifier = 1.0
		height = _normal_height

	if get_height() != height:
		if body.shape is BoxShape3D:
			body.shape.extents.y = height
		elif body.shape is SphereShape3D:
			body.shape.radius = height
		elif body.shape is CapsuleShape3D:
			body.shape.height = height
		else:
			print_debug("Unknown shape type!")

func jump() -> void:
	var a = PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY)
	var s = jump_height
	var u = velocity.project(up_direction).length()
	var v = sqrt(u + 2 * a * s)
	velocity += up_direction * v


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

func check_ledge(slide_collision: KinematicCollision3D) -> Dictionary:
	#check if touching wall
	if slide_collision.get_angle(0, up_direction) <= floor_max_angle:
		return {}

	var cp_offset = -slide_collision.get_normal() * slide_collision.get_remainder().length()
	var top = global_position + up_direction * (get_height()/2)
	var bottom = global_position - up_direction * (get_height()/2)

	var dist_to_wall = (slide_collision.get_position() - bottom).slide(up_direction)
	var from = top + dist_to_wall + cp_offset
	var to = bottom + dist_to_wall + cp_offset

	var params = PhysicsRayQueryParameters3D.create(from, to)
	params.exclude = [self.get_rid()]

	var hit = get_world_3d().direct_space_state.intersect_ray(params)
	if not hit or (hit.position - params.from).length() <= LEDGE_THRESHOLD:
		return {}

	if debug:
		DebugDraw.draw_ray(get_tree(), from, hit.position, 0.01, 0.02, Color(1,0,0,1), 10)
	return {

		"ledge_height": (hit.position - params.to).length()
		}

func check_ladder(slide_collision: KinematicCollision3D) -> Dictionary:
	if not slide_collision.get_collider() is Node3D:
		return {}

	if not slide_collision.get_collider().is_in_group(ladder_group):
		return {}

	return {
		"position": slide_collision.get_position(),
		"normal": slide_collision.get_normal(),
		"collider": slide_collision.get_collider()
		}

func push_contact_bodies(slide_collision: KinematicCollision3D) -> bool:
	var c = slide_collision.get_collider()
	if not c is RigidBody3D:
		return false

	c.apply_central_impulse(-slide_collision.get_normal() * 0.8)
	c.apply_impulse(-slide_collision.get_normal() * 0.01, slide_collision.get_position())
	return true

func is_near_floor() -> bool:
	var bottom = global_position - up_direction * (get_height()/2)
	var params: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(bottom, bottom - up_direction * max_step_height)
	params.exclude = [self.get_rid()]
	var hit = get_world_3d().direct_space_state.intersect_ray(params)
	if hit:
		return true

	return false

func get_height() -> float:
	if body.shape is BoxShape3D:
		return body.shape.extents.y * 2
	elif body.shape is SphereShape3D:
		return body.shape.radius * 2
	elif body.shape is CapsuleShape3D:
		return body.shape.height
	elif body.shape is ConvexPolygonShape3D:
		var vertices = body.shape.get_vertices()
		var min_y = vertices[0].y
		var max_y = vertices[0].y
		for vertex in vertices:
			min_y = min(min_y, vertex.y)
			max_y = max(max_y, vertex.y)
			return max_y - min_y
	else:
		print_debug("Unknown shape type!")
		return 0.0
	return 0.0


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

func is_jumping():
	return jumping

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
