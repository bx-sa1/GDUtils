class_name MissionManager extends Resource

var missions: Array[Mission]

var completed_missions: Array[Mission]
var failed_missions: Array[Mission]

signal mission_completed(mission: Mission)
signal mission_failed(mission: Mission)

func _ready() -> void:
	for m in missions:
		m._init()

func add_mission(mission: Mission) -> void:
	missions.push_back(mission)
	mission._init()

func remove_mission(mission: Mission) -> void:
	missions.erase(mission)

func inc_progress(event_name: String) -> void:
	for i in range(len(missions)-1, -1, -1):
		var mission = missions[i]
		mission.inc_progress(event_name)
		if mission.is_completed():
			print_debug("Mission Completed. Moving to completed list.")
			missions.remove_at(i)
			completed_missions.push_back(mission)
			mission_completed.emit(mission)

func dec_progress(event_name: String) -> void:
	for i in range(len(missions)-1, -1, -1):
		var mission = missions[i]
		mission.dec_progress(event_name)
		if mission.is_failed():
			print_debug("Mission Failed. Moving to failed list.")
			missions.remove_at(i)
			failed_missions.push_back(mission)
			mission_failed.emit(mission)

func is_completed() -> bool:
	return len(completed_missions) == len(missions)

func get_mission(name: String) -> Mission:
	for mission in missions:
		if mission.name == name:
			return mission
	return null
