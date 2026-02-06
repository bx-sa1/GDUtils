class_name LastCheckpoint extends Node

var checkpoint: Checkpoint = null
var used_checkpoints: Dictionary[Checkpoint, Object] = {}

signal kill_plane_passed(reset_pos: Vector3)

func _physics_process(delta: float) -> void:
	if not checkpoint:
		return

	if checkpoint.enable_kill_plane and not checkpoint.kill_plane.is_point_over(owner.global_position):
		kill_plane_passed.emit(checkpoint.global_position)
