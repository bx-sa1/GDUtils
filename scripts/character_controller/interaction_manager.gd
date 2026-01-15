class_name InteractionManager extends Node3D

@export var debug := false
@export var focus_length: float = 10
@export var focus_radius: float = 2.0

var current_focus
var parent: CharacterController

signal held(node: Node3D)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if get_parent() is not CharacterController:
		warnings.push_back("Must be a child of a CharacterController")

	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	parent = get_parent()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return

	var focus := _check_focus()
	if current_focus:
		var interaction: Interactable = current_focus.find_children("*", "Interactable").pop_back()
		if interaction:
			interaction.unfocus()
	current_focus = focus
	if debug:
		print_debug("Focus changed to ", current_focus)
	if current_focus:
		var interaction: Interactable = current_focus.find_children("*", "Interactable").pop_back()
		if interaction:
			interaction.focus()
			if Input.is_action_just_pressed("interact"):
				interaction.interact(parent)
				if interaction.holdable:
					held.emit(current_focus)

func _check_focus() -> Node3D:
	var origin = global_position
	var dir = -global_basis.z
	var space = get_world_3d().direct_space_state

	var shape_rid = PhysicsServer3D.sphere_shape_create()
	PhysicsServer3D.shape_set_data(shape_rid, focus_radius)

	var params = PhysicsShapeQueryParameters3D.new()
	params.transform = global_transform
	params.motion = dir*focus_length
	params.shape_rid = shape_rid
	params.exclude = [parent.get_rid()]

	var motion = space.cast_motion(params)
	if not motion or (motion[0] == 1.0 and motion[1] == 1.0):
		PhysicsServer3D.free_rid(shape_rid)
		return null

	params.transform.origin += params.motion*motion[1]
	var hits = space.intersect_shape(params)
	if hits.size() == 0:
		PhysicsServer3D.free_rid(shape_rid)
		if debug:
			print_debug("No shapes intersect shape cast")
		return

	var closest: Node3D
	for hit in hits:
		if (not closest or
			(hit.collider.global_position - global_position).length() < (closest.global_position - global_position).length()):
			closest = hit.collider
	if debug:
		print_debug("Closest node to head is ", closest)

	PhysicsServer3D.free_rid(shape_rid)
	return closest
