class_name CharacterController extends CharacterBody3D

@export var debug = false
@export_category("References")
@export var head: Node3D
@export var body: CollisionShape3D
@export_category("Actions")
@export var move_left_action: String = "ui_left"
@export var move_right_action: String = "ui_right"
@export var move_forward_action: String = "ui_up"
@export var move_back_action: String = "ui_down"
@export var jump_action: String = "ui_select"
@export_category("Settings")
@export var focus_length: float = 10
@export var look_sensitivity: float = 1.0
@export_range(0, 90) var pitch_lower_limit: float = 89
@export_range(0, 90) var pitch_upper_limit: float = 89
@export var strafe: bool = true
@export var max_step_height: float = 0.2
@export var gravity_accel: float = 98.1
@export var gravity: bool = true
@export var hold_distance: float = 3
@export var hold_lerp: float = 0.3
@export_category("Movement Settings")
## Max move speed
@export_range(0, 100, 0.001, "suffix:m/s") var move_speed: float = 10
## Min stop speed
@export_range(0, 100, 0.001, "suffix:m/s") var stop_speed: float = 3.125
@export_range(0, 1, 0.001, "suffix:s") var ground_accel: float = 0.2
@export_range(0, 1, 0.001, "suffix:s") var air_accel: float = 1.0
@export_range(0, 1, 0.001, "suffix:s") var ground_friction: float = 0.166
@export_category("Jump Settings")
@export var jump_height: float = 30.0
@export var buffer_jump_time: float = 0.2
@export var coyote_jump_time: float = 0.1

var _forward := Vector3.ZERO
var _last_forward := Vector3.ZERO

var _yaw: float
var _pitch: float
var mouse_captured: bool = false

var current_holding: RigidBody3D
var current_holding_freeze_mode: RigidBody3D.FreezeMode
var coyote_jump_counter: float = 0.0
var buffer_jump_counter: float = 0.0

const MIN_STEP_HEIGHT := 0.1

## Rotate the head and/or body based on mouse movement and return what is currently being looked at
func look(event: InputEvent) -> void:
	if not mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and head:
		_yaw += -event.relative.x * look_sensitivity * 0.1
		_pitch += -event.relative.y * look_sensitivity * 0.1
		_pitch = clampf(_pitch, -pitch_lower_limit, pitch_upper_limit)

		var rot = Vector3(deg_to_rad(_pitch), deg_to_rad(_yaw), 0)
		if strafe:
			head.transform.basis = Basis(Vector3.RIGHT, rot.x)
			transform.basis = Basis(Vector3.UP, rot.y)
		else:
			head.transform.basis = Basis.from_euler(rot)

func get_looking_at() -> Node:
	var origin = head.global_position
	var dir = -head.global_basis.z
	var params = PhysicsRayQueryParameters3D.create(origin, origin+dir*focus_length)
	params.exclude = [self.get_rid()]
	if debug:
		DebugDraw.draw_ray(get_tree(), origin, origin+dir*focus_length, 0.01, 0.015, Color(0,1,0,1), 1)
	var hit = get_world_3d().direct_space_state.intersect_ray(params)
	var res = hit.get("collider")
	if res:
		return res
	else:
		return null

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

func move_current_holding() -> void:
	if not current_holding:
		return

	var current_position = current_holding.global_position
	var new_position = head.global_transform.translated_local(Vector3.FORWARD*hold_distance).origin
	current_holding.move_and_collide((new_position - current_position) * hold_lerp)
	current_holding.global_basis = Basis(current_holding.global_basis.get_rotation_quaternion().slerp(head.global_basis.get_rotation_quaternion(), hold_lerp))


func move(delta: float) -> void:
	var wishdir = get_wishdir()
	var wishspeed = move_speed
	_forward = get_forward(wishdir)

	if gravity:
		velocity += -up_direction * gravity_accel * delta

	var _vel = Velocity.new(velocity, up_direction)
	_vel = jump(_vel, delta)
	_vel = friction(_vel, delta)
	if is_on_floor():
		_vel = accelerate(_vel, wishdir, wishspeed, ground_accel, delta)
	else:
		_vel = accelerate(_vel, wishdir, wishspeed, air_accel, delta)

	velocity = _vel.sum()
	move_and_slide()

	push_contact_bodies()
	if is_on_floor():
		handle_step()

	rotate_body_to_forward()

func friction(vel: Velocity, delta: float) -> Velocity:
	var speed = vel.horizontal.length()
	# if speed < 1.0:
	# 	velocity.horizontal = Vector3.ZERO
	# 	return velocity

	var drop = 0.0
	if is_on_floor:
		var control = stop_speed if speed <= stop_speed else speed
		drop += (control / ground_friction) * delta

	# var newspeed = speed - drop
	# if newspeed < 0.0:
	# 	newspeed = 0.0
	# newspeed /= speed
	# velocity.horizontal *= newspeed
	# return velocity
	vel.horizontal = vel.horizontal.move_toward(Vector3.ZERO, drop)
	return vel

func accelerate(vel: Velocity, wishdir: Vector3, wishspeed: float, accel_time: float, delta: float) -> Velocity:
	var currentspeed = vel.horizontal.dot(wishdir)
	var addspeed = move_speed - currentspeed
	if addspeed <= 0:
		return vel
	var accel = (move_speed / accel_time) * delta
	if accel > addspeed:
		accel = addspeed
	vel.horizontal += accel*wishdir
	return vel

func jump(vel: Velocity, delta: float) -> Velocity:
	if is_on_floor():
		coyote_jump_counter = coyote_jump_time
	else:
		coyote_jump_counter -= delta
	if Input.is_action_just_pressed(jump_action):
		buffer_jump_counter = buffer_jump_time
	else:
		buffer_jump_counter -= delta

	if coyote_jump_counter > 0 and buffer_jump_counter > 0:
		vel.vertical = up_direction * jump_height
		buffer_jump_counter = 0

	if Input.is_action_just_released(jump_action) and vel.vertical.length() > 0:
		vel.vertical *= 0.5
		coyote_jump_counter = 0

	return vel


func rotate_body_to_forward() -> void:
	var visual_forward = body.global_basis.z
	var target_angle := visual_forward.signed_angle_to(_forward, up_direction)
	body.rotate(up_direction, target_angle)

func push_contact_bodies() -> void:
	for i in get_slide_collision_count():
		var sc := get_slide_collision(i)
		var c := sc.get_collider()
		if not c is RigidBody3D:
			continue
		c.apply_central_impulse(-sc.get_normal() * 0.8)
		c.apply_impulse(-sc.get_normal() * 0.01, sc.get_position())


func handle_step():
	for i in get_slide_collision_count():
		var slide_collision := get_slide_collision(i)
		if not _is_collision_wall(slide_collision):
			continue
		var step_height = _get_step_height(slide_collision)
		if step_height > MIN_STEP_HEIGHT and step_height <= max_step_height:
			if debug:
				print("Step Found: Height = ", step_height)
			global_position += up_direction * step_height
		elif debug:
			print("\"Step\" too high: Height = ", step_height)


func _is_collision_wall(col: KinematicCollision3D) -> bool:
	if col.get_angle(0, up_direction) <= floor_max_angle:
			return _check_collision_is_wall(col)
	return true

func _check_collision_is_wall(col: KinematicCollision3D) -> bool:
	var bottom = _get_bottom()
	var a = _vector_from_bottom_to_collision_point_projected_on_ground_plane(bottom, col)

	var params = PhysicsRayQueryParameters3D.create(bottom, bottom + a)
	params.collision_mask = self.collision_mask
	params.exclude = [self.get_rid()]

	var hit = get_world_3d().direct_space_state.intersect_ray(params)
	if hit and hit.normal.angle_to(up_direction) > floor_max_angle:
		return true

	return false

func _get_bottom() -> Vector3:
	var a = body.global_position + -up_direction*body.shape.height/2
	a += up_direction*0.01
	return a

func _get_top() -> Vector3:
	var a = body.global_position + up_direction*body.shape.height/2
	return a

func _get_step_height(col: KinematicCollision3D) -> float:
	var top = _get_top()
	var bottom = _get_bottom()
	var a = _vector_from_bottom_to_collision_point_projected_on_ground_plane(bottom, col)
	var from = top + a
	var to = bottom + a
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var intersect = get_world_3d().direct_space_state.intersect_ray(params)
	if intersect:
		return (to - intersect.position).length()
	return 0.0


func _vector_from_bottom_to_collision_point_projected_on_ground_plane(bottom: Vector3, col: KinematicCollision3D) -> Vector3:
	var a = col.get_position() - bottom
	a = a - a.project(up_direction)
	return a

func _project_ground_plane(v: Vector3) -> Vector3:
	return (v - v.project(up_direction)).normalized()

func get_forward(wishdir: Vector3) -> Vector3:
	if strafe:
		return _project_ground_plane(-head.global_basis.z)
	else:
		if wishdir.length() > 0:
			_last_forward = wishdir
		return _last_forward

func get_wishdir() -> Vector3:
	var input_axis = Input.get_vector(move_left_action, move_right_action, move_forward_action, move_back_action)
	var wishdir = (head.global_basis * Vector3(input_axis.x, 0.0, input_axis.y)).normalized()
	wishdir = _project_ground_plane(wishdir)
	return wishdir
