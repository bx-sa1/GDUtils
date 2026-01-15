#
# Planner. Goap's heart.
#
class_name GoapActionPlanner

class PlanNode:
	var action: GoapAction
	var state: Dictionary
	var children: Array[PlanNode]
	var cummulative_cost: int

	func _init(_action: GoapAction, _state: Dictionary, cummulative_cost: int):
		action = _action
		state = _state
		children = []
		self.cummulative_cost = cummulative_cost


class Plan:
	var goal: GoapGoal
	var actions: Array[GoapAction]
	var cost: int

	func _init(goal: GoapGoal, actions: Array[GoapAction], cost: int):
		self.goal = goal
		self.actions = actions
		self.cost = cost

	func is_complete() -> bool:
		return actions.size() == 0

func get_plan(agent: GoapAgent, goals: Array[GoapGoal], world_state: Dictionary) -> Plan:
	goals = goals.filter(func(x):
		for s in x.desired_state:
			if x.desired_state[s] == world_state.get(s):
				return false
		return true)
	goals.sort_custom(func(a,b): return a.priority > b.priority)

	for goal in goals:
		var root = PlanNode.new(null, goal.desired_state, 0)
		if find_path(root, agent.actions, world_state):
			if root.children.size() == 0 and root.action == null:
				continue

			var actions: Array[GoapAction] = []
			while root.children.size() > 0:
				root.children.sort_custom(func(a,b): return a.cummulative_cost < b.cummulative_cost)
				var cheapest = root.children.front()
				root = cheapest
				actions.push_back(cheapest.action)

			return Plan.new(goal, actions, root.cummulative_cost)

	return null

func find_path(node: PlanNode, actions: Array[GoapAction], world_state: Dictionary) -> bool:
	var desired_state = _satisfy_state(node.state, world_state)

	# desired state satisfied
	if desired_state.size() == 0:
		return true

	for action in actions:
		var effects = action.effects
		var preconditions = action.preconditions

		# can action resolve the state?
		if effects.keys().any(desired_state.keys().has):
			var new_desired_state = _satisfy_state(desired_state, effects)
			new_desired_state.merge(preconditions, true)

			var new_node = PlanNode.new(action, new_desired_state, node.cummulative_cost + action.cost)
			if find_path(new_node, actions, world_state):
				node.children.push_back(new_node)
				new_desired_state = _satisfy_state(new_desired_state, preconditions)

			# all states satisified at this depth, no possible further states
			if new_desired_state.size() == 0:
				return true

	return node.children.size() > 0

func _satisfy_state(old_state: Dictionary, required_state: Dictionary) -> Dictionary:
		var new_state = old_state.duplicate()
		for s in new_state:
			if new_state[s] == required_state.get(s):
				new_state.erase(s)
		return new_state
