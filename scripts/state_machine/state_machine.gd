class_name StateMachine extends Node

@export var debug: bool = false
@export var initial_state: State

class Transition:
	var new_state: NodePath
	var user_data: Dictionary

var current_state: State

signal transitioned(old_state: State, new_state: State)

func _ready() -> void:
	set_state.call_deferred(initial_state)

func transition(user_data: Dictionary = {}) -> void:
	if not current_state:
		return

	var state_transition: Transition = current_state.transition()
	if not state_transition or state_transition.new_state == ^"":
		return


	var state_node = get_node(state_transition.new_state)
	if not state_node:
		return
	if not state_node is State:
		return

	set_state(state_node, state_transition.user_data.merged(user_data))

func set_state(state_node: State, user_data: Dictionary = {}):
	transitioned.emit(current_state, state_node)
	if current_state: current_state.exit()
	current_state = state_node
	if current_state: current_state.enter(user_data)

func _process(delta: float) -> void:
	if not current_state:
		return

	if debug:
		print_debug(current_state.name)

	current_state.process(delta)

func _physics_process(delta: float) -> void:
	if not current_state:
		return

	current_state.physics_process(delta)
