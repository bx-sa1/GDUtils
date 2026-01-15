class_name GoapSensor extends Node3D

@export var check_interval: float = 1.0
@export var group_filter: String
@export var desired_state: Dictionary

var target: Node3D
var last_target_pos: Vector3
var timer: Timer

signal target_changed

func _ready():
	timer = Timer.new()
	timer.autostart = true
	timer.wait_time = check_interval
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	_update_position(target)

func _update_position(new_target: Node3D = null):
	if group_filter and new_target and not new_target.is_in_group(group_filter):
		return
	target = new_target
	if is_target_in_range() and (get_target_pos() != last_target_pos or last_target_pos != Vector3.ZERO):
		last_target_pos = get_target_pos()
		target_changed.emit()

func is_target_in_range() -> bool:
	return get_target_pos() != Vector3.ZERO

func get_target_pos() -> Vector3:
	return target.global_position if target else Vector3.ZERO
