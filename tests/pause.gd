extends Node

var paused = false
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		if paused:
			unpause()
		else:
			pause()

func pause() -> void:
	if paused:
		return

	SceneManager.push_scene("res://pause.tscn")
	paused = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func unpause() -> void:
	if not paused:
		return

	SceneManager.pop_scene()
	paused = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
