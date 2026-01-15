#
# Action Contract
#
class_name GoapAction extends Resource

class Strategy:
	func is_complete(actor: Node):
		return true
	func is_valid(actor: Node):
		return true
	func activate(actor: Node):
		pass
	func deactivate(actor: Node):
		pass

@export var name: String
@export var cost: int
@export var preconditions: Dictionary
@export var effects: Dictionary
@export var strategy_script: Script:
	set(v):
		strategy_script = v
		strategy = v.new()

var strategy: Strategy = null

func is_complete(actor: Node) -> bool:
	if not strategy:
		return true

	return strategy.is_complete(actor)

func is_valid(actor: Node) -> bool:
	if not strategy:
		return true

	return strategy.is_valid(actor)


func activate(actor: Node):
	if not strategy:
		return

	return strategy.activate(actor)

func deactivate(actor: Node):
	if not strategy:
		return

	return strategy.deactivate(actor)

func validate_preconditions(world_state: Dictionary) -> bool:
	for p in preconditions:
		if preconditions[p] != world_state[p]:
			return false
	return true

func apply_effects(world_state: Dictionary) -> void:
	for e in effects:
		world_state[e] = effects[e]
