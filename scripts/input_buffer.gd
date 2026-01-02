class_name InputBuffer

var time: float
var max_time: float

func _init(_max_time: float) -> void:
	max_time = _max_time
	time = 0.0

func reset() -> void:
	time = 0

func update(delta: float, activation: bool) -> bool:
	if activation:
		time = max_time
	else:
		time -= delta

	return time > 0
