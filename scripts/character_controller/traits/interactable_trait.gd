class_name InteractableTrait extends Trait

@export var debug: bool = false
@export var pickup: bool = true

func on_focus() -> void:
	if debug: print_debug("on_focus")

func on_unfocus() -> void:
	if debug: print_debug("on_unfocus")

func on_interact(caller: CharacterController) -> void:
	if debug: print_debug("on_interact\nCaller: %s" % caller.name)
