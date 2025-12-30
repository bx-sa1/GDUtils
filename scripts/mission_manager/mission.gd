class_name Mission extends Resource

@export var name: String
@export_multiline var description: String
@export var objectives: Array[Objective]

var _event_map: Dictionary[String, Array]

func _init() -> void:
	for o in objectives:
		_map_objective(o)

func _map_objective(obj: Objective) -> void:
	if not _event_map.has(obj.event_trigger):
		_event_map[obj.event_trigger] = []
	_event_map[obj.event_trigger].push_back(obj)

func _unmap_objective(obj: Objective) -> void:
	_event_map[obj.event_trigger].erase(obj)

func inc_progress(event_trigger: String) -> void:
	if not _event_map.has(event_trigger):
		return

	for i in len(_event_map[event_trigger]):
		var obj: Objective = _event_map[event_trigger][i]
		obj.inc_progress()
		if obj.is_completed():
			print_debug("Objective Completed. Unmapping.")
			_unmap_objective(obj)
			i -= 1

func dec_progress(event_trigger: String) -> void:
	if not _event_map.has(event_trigger):
		return

	for i in len(_event_map[event_trigger]):
		var obj: Objective = _event_map[event_trigger][i]
		obj.dec_progress()
		if obj.is_failed():
			print_debug("Objective Failed. Unmapping.")
			_unmap_objective(obj)
			i -= 1

func is_completed() -> bool:
	return objectives.map(func(x): return x.is_completed()).all(func(x): return x == true)

func is_failed() -> bool:
	return objectives.map(func(x): return x.is_failed()).any(func(x): return x == true)
