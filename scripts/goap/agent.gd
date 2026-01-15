#
# This script integrates the actor (NPC) with goap.
# In your implementation you could have this logic
# inside your NPC script.
#
# As good practice, I suggest leaving it isolated like
# this, so it makes re-use easy and it doesn't get tied
# to unrelated implementation details (movement, collisions, etc)
extends Node

class_name GoapAgent

@export var actor: Node
@export var goals: Array[GoapGoal]
@export var actions: Array[GoapAction]
@export var sensors: Dictionary[String, GoapSensor]
@export var world_state: Dictionary

var _current_action: GoapAction
var _current_plan: GoapActionPlanner.Plan
var _action_planner: GoapActionPlanner

signal plan_changed(new_plan: GoapActionPlanner.Plan)
signal plan_advanced(new_action: GoapAction)

func _ready() -> void:
	_action_planner = GoapActionPlanner.new()

func _process(delta: float) -> void:
	for s in sensors:
		for d in sensors[s].desired_state:
			# flip the state if out range, return same state if in range
			# check a truth table
			world_state[d] = sensors[s].is_target_in_range() == sensors[s].desired_state[d]
	_update_goal()
	_set_best_goal()

func _update_goal() -> void:
	if not _current_plan or _current_plan.is_complete():
		return

	if not _current_action or _current_action.is_complete(actor):
		_advance_plan()

func _set_best_goal() -> void:
	var update_goal = false
	if _current_action and not _current_action.is_valid(actor):
		print_debug("Action %s invalid, finding new goal" % _current_action.name)
		update_goal = true
	elif not _current_plan or _current_plan.is_complete():
		print_debug("Goal reached, finding new goal")
		update_goal = true

	if update_goal:
		var relevant_goals = goals
		if _current_plan:
			relevant_goals.filter(func(x): return x.priority > _current_plan.goal.priority)
		var plan = _action_planner.get_plan(self, relevant_goals, world_state)
		if plan:
			print_debug("Goals: %s, Actions: %s" % [plan.goal.name, plan.actions.map(func(x): return x.name)])
			_current_plan = plan
			_current_action = null

func _advance_plan() -> void:
	while true:
		if _current_action:
			_current_action.apply_effects(world_state)
			_current_action.deactivate(actor)

		if _current_plan.is_complete():
			return

		var new_action = _current_plan.actions.pop_back()
		if not new_action.validate_preconditions(world_state):
			print_debug("Preconditions for %s failed to validate" % new_action.name)
			_current_plan = null
			_current_action = null
			return

		new_action.activate(actor)
		print_debug("Action activated: %s" % new_action.name)
		if not new_action.is_complete(actor):
			_current_action = new_action
			return

		new_action.deactivate(actor)
