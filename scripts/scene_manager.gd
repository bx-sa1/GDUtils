extends Node

var _scene_stack: Array[Node]
var root

func _ready() -> void:
	root = get_parent()
	_scene_stack.push_back(root.get_child(-1))

func load_scene(scene_name: String) -> Node:
	var new_scene = load(scene_name)
	if not new_scene:
		push_error("Failed to load scene %s".format(scene_name))
		return null
	var new_scene_node = new_scene.instantiate()
	return new_scene_node

func push_scene(scene: Node) -> void:
	root.add_child(scene)
	_scene_stack.push_back(scene)

func pop_scene() -> void:
	var top_scene = _scene_stack.pop_back()
	root.remove_child(top_scene)
	top_scene.queue_free()

func change_scene(scene: Node, transition: Node) -> void:
	if transition:
		root.add_child(transition)
		if transition.has_method("_on_in"):
			await transition.call("_on_in")
	while not _scene_stack.is_empty():
		pop_scene()
	push_scene(scene)
	if transition:
		root.move_child(transition, -1)
		if transition.has_method("_on_out"):
			await transition.call("_on_out")
		transition.queue_free()
