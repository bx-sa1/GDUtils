extends Label

@export var weapon_controller: WeaponController


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	text = weapon_controller.debug_print()
