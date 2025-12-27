extends ReloadTrait

@export var anims: AnimationPlayer

func on_reload(weapon: Weapon) -> void:
	anims.play("reload")
	await anims.animation_finished
