@abstract
class_name State extends Node

func enter(user_data: Dictionary):
	pass

func exit():
	pass

@abstract func transition() -> StateMachine.Transition
@abstract func process(delta: float)
@abstract func physics_process(delta: float)
