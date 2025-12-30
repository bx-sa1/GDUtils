extends Manual

func _ready() -> void:
	super()
	await get_tree().create_timer(1).timeout
	mission_manager.inc_progress("Foo")
	await get_tree().create_timer(1).timeout
	mission_manager.inc_progress("Bar")
