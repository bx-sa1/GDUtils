class_name InteractionComponent extends Node

@export var debug: bool = false
@export var holdable: bool = false

func on_focus() -> void:
	if debug: print_debug("on_focus")

func on_unfocus() -> void:
	if debug: print_debug("on_unfocus")

func on_interact(caller: Node) -> void:
	if debug: print_debug("on_interact\nCaller: %s" % caller.name)
