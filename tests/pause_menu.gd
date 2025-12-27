extends Control




func _on_continue_pressed() -> void:
	Pause.unpause()

func _on_back_to_menu_pressed() -> void:
	Pause.unpause()
	SceneManager.change_scene("res://main_menu.tscn", null)
