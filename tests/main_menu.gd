extends Control


const TRANSITION = preload("res://transition.tscn")

func _on_button_pressed() -> void:
	SceneManager.change_scene("res://game.tscn", TRANSITION.instantiate())
