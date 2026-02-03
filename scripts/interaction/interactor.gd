class_name Interactor extends Node3D
enum InteractorType{
	SCREEN,
	SPACE,
	}

@export var debug := false
@export var type: InteractorType = InteractorType.SCREEN
@export var interact_action: String = "interact"
@export var focus_length: float = 10
@export_flags_3d_physics var collision_mask: int = ~0

var current_focus: Interactable
var force_interact: bool = true

signal pickedup(interactable: Interactable)
signal held(interactable: Interactable)

func _process(delta: float) -> void:
	var focus: Interactable = _check_focus()
	if focus and debug:
		print_debug("Focusing %s" % focus.name)
	_update_focus(focus)
	if focus and (Input.is_action_just_pressed(interact_action) or force_interact):
		if focus.enabled:
			focus.interact()
		if focus.holdable:
			held.emit(focus)
		if focus.pickup:
			pickedup.emit(focus)
		force_interact = false

func _update_focus(focus: Interactable) -> void:
	if current_focus: current_focus.unfocus()
	current_focus = focus
	if current_focus: current_focus.focus()

func _check_focus() -> Interactable:
	match type:
		InteractorType.SCREEN:
			return _check_focus_screen()
		InteractorType.SPACE:
			return _check_focus_space()
		_:
			assert(false)
			return null

func _check_focus_screen() -> Interactable:
	var camera = get_viewport().get_camera_3d()
	var viewport_size = get_viewport().get_size()

	var origin = camera.project_ray_origin(viewport_size/2)
	var dir = camera.project_ray_normal(viewport_size/2)

	var params = PhysicsRayQueryParameters3D.create(origin, origin + dir * focus_length, collision_mask)
	var hit = get_world_3d().direct_space_state.intersect_ray(params)
	if hit:
		var interactable = hit.collider.find_children("", "Interactable").pop_back()
		if interactable:
			return interactable

	return null

func _check_focus_space() -> Interactable:
	var sphere_rid = PhysicsServer3D.sphere_shape_create()
	PhysicsServer3D.shape_set_data(sphere_rid, focus_length)

	var params = PhysicsShapeQueryParameters3D.new()
	params.transform = global_transform
	params.collision_mask = collision_mask
	params.shape_rid = sphere_rid

	var hits = get_world_3d().direct_space_state.intersect_shape(params)
	var closest = null
	for hit in hits:
		var dist = (hit.collider.global_position - global_position).length()
		if not closest or dist < (closest.global_position - global_position).length():
			closest = hit.collider

	if closest:
		var interactable = closest.find_children("", "Interactable").pop_back()
		if interactable:
			PhysicsServer3D.free_rid(sphere_rid)
			return interactable

	PhysicsServer3D.free_rid(sphere_rid)
	return null
