extends FireTrait

@export var anims: AnimationPlayer

func on_fire(weapon: Weapon) -> void:
	anims.play("fire")
	await anims.animation_finished
