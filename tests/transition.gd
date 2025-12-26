extends Control

@export var anims: AnimationPlayer

func _on_in() -> void:
	anims.play("in")
	await anims.animation_finished

func _on_out() -> void:
	anims.play("out")
	await anims.animation_finished
