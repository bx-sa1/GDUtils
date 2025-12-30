extends InteractableTrait


func on_interact(caller: CharacterController) -> void:
	super(caller)
	if pickup and caller.has_meta("PickupTrait"):
		var p = caller.get_meta("PickupTrait")
		p.pickup(trait_owner)
