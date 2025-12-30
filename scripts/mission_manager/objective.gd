class_name Objective extends Resource

@export var name: String
@export_multiline var description: String
@export var event_trigger: String #Event name to listen to
@export var max_progress: int = 1

var progress = 0

func inc_progress() -> void:
	progress += 1
	if progress >= max_progress:
		progress = max_progress

func dec_progress() -> void:
	progress -= 1
	if progress <= -1:
		progress = -1

func is_completed() -> bool:
	return progress >= max_progress

func is_failed() -> bool:
	return progress < 0
