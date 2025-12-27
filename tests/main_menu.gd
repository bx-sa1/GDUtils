extends Control


const TRANSITION = preload("res://transition.tscn")

func _on_character_controller_test_pressed() -> void:
	SceneManager.change_scene("res://character_controller_test/main.tscn", TRANSITION.instantiate())


func _on_weapon_controller_test_pressed() -> void:
	SceneManager.change_scene("res://weapon_controller_test/main.tscn", TRANSITION.instantiate())
