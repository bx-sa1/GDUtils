class_name CharacterController extends CharacterBody3D

enum MovementType {
	NORMAL,
	STRAFE,
	FLY
	}
@export var debug = false
@export_category("References")
@export var head: Node3D
@export var body: CollisionShape3D
@export_category("Settings")
@export var focus_length: float = 10
@export var look_sensitivity: float = 1.0
@export_range(0, 90) var pitch_lower_limit: float = 89
@export_range(0, 90) var pitch_upper_limit: float = 89
@export var movement_type = MovementType.STRAFE
@export var max_step_height: float = 0.2
@export var gravity_accel: float = 98.1
@export var gravity: bool = true
@export var hold_distance: float = 3
@export var hold_lerp: float = 0.3
@export_category("Components")
@export var strategies: Array[MovementStrategy]

var _forward := Vector3.ZERO
var _last_forward := Vector3.ZERO

var _yaw: float
var _pitch: float
var mouse_captured: bool = false

var current_focus: Node3D
var current_holding: RigidBody3D
var current_holding_freeze_mode: RigidBody3D.FreezeMode
var is_moving := false
var is_stopping := false
var is_falling := false

const MIN_STEP_HEIGHT := 0.1

signal interacted_with(collider: Node)

func get_strategy(type: Variant) -> MovementStrategy:
	for c in strategies:
		if is_instance_of(c, type):
			return c
	return null



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
		match movement_type:
			MovementType.NORMAL:
				head.transform.basis = Basis.from_euler(rot)
			MovementType.STRAFE:
				head.transform.basis = Basis(Vector3.RIGHT, rot.x)
				transform.basis = Basis(Vector3.UP, rot.y)
			MovementType.FLY:
				transform.basis = Basis.from_euler(rot)

func check_focus(origin: Vector3, dir: Vector3, interact: bool) -> void:
	var params = PhysicsRayQueryParameters3D.create(origin, origin+dir*focus_length)
	var hit = get_world_3d().direct_space_state.intersect_ray(params)
	var res = hit.get("collider")
	if res != current_focus:
		if current_focus and current_focus.has_meta("InteractableTrait"):
			var interactable: InteractableTrait = current_focus.get_meta("InteractableTrait")
			interactable.on_focus()
		current_focus = res
		if debug: print_debug("Focus changed to ", current_focus)
		if current_focus and current_focus.has_meta("InteractableTrait"):
			var interactable: InteractableTrait = current_focus.get_meta("InteractableTrait")
			interactable.on_unfocus()
	if interact:
		_interact()
		interacted_with.emit(current_focus)

func _interact() -> void:
	if current_focus and current_focus.has_meta("InteractableTrait"):
		var interactable: InteractableTrait = current_focus.get_meta("InteractableTrait")
		interactable.on_interact(self)
		if interactable.holdable:
			if current_holding:
				current_holding.freeze = false
				current_holding.freeze_mode = current_holding_freeze_mode
				current_holding = null
			else:
				current_holding = current_focus
				current_holding.freeze = true
				current_holding_freeze_mode = current_holding.freeze_mode
				current_holding.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

func move(delta: float, input_axis := Vector2.ZERO) -> void:
	var wishdir = _calc_wishdir(input_axis)
	_forward = _calc_forward(wishdir)

	if gravity:
		velocity += -up_direction * gravity_accel * delta

	var _velocity = Velocity.new()
	_velocity.vertical = velocity.project(up_direction)
	_velocity.horizontal = velocity - _velocity.vertical
	for strat in strategies:
		var state := MovementStrategy.MovementState.new()
		state.velocity = _velocity
		state.wishdir = wishdir
		state.forward = _forward
		state.updir = up_direction
		state.is_on_floor = is_on_floor()
		state.is_on_wall = is_on_wall()
		state.current_holding = current_holding
		_velocity = strat.apply(state, delta)
	velocity = _velocity.sum()
	move_and_slide()

	if current_holding:
		var current_position = current_holding.global_position
		var new_position = head.global_transform.translated_local(Vector3.FORWARD*hold_distance).origin
		current_holding.move_and_collide((new_position - current_position) * hold_lerp)
		current_holding.global_basis = Basis(current_holding.global_basis.get_rotation_quaternion().slerp(head.global_basis.get_rotation_quaternion(), hold_lerp))

	_push_contact_bodies()
	if is_on_floor():
		_handle_step()

	var visual_forward = body.global_basis.z
	var target_angle := visual_forward.signed_angle_to(_forward, up_direction)
	body.rotate(up_direction, target_angle)

	is_moving = _velocity.horizontal.length() > 0 and wishdir.length() > 0
	is_stopping = _velocity.horizontal.length() > 0 and wishdir.length() == 0
	is_falling = _velocity.vertical.length() > 0 and _velocity.vertical.dot(up_direction) == -1

func _push_contact_bodies() -> void:
	for i in get_slide_collision_count():
		var sc := get_slide_collision(i)
		var c := sc.get_collider()
		if not c is RigidBody3D:
			continue
		c.apply_central_impulse(-sc.get_normal() * 0.8)
		c.apply_impulse(-sc.get_normal() * 0.01, sc.get_position())


func _handle_step():
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

func _calc_forward(wishdir: Vector3) -> Vector3:
	match movement_type:
		MovementType.STRAFE:
			return _project_ground_plane(-head.global_basis.z)
		MovementType.NORMAL:
			if wishdir.length() > 0:
				_last_forward = wishdir
			return _last_forward
		MovementType.FLY:
			return -head.global_basis.z
		_:
			assert(false)
			return Vector3.ZERO

func _calc_wishdir(input_axis: Vector2) -> Vector3:
	var wishdir = (head.global_basis * Vector3(input_axis.x, 0.0, input_axis.y)).normalized()
	match movement_type:
		MovementType.NORMAL, MovementType.STRAFE:
			wishdir = _project_ground_plane(wishdir)
	return wishdir
