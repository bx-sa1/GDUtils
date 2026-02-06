class_name Checkpoint extends Area3D

@export var enable_kill_plane: bool = true
@export var kill_plane: Plane = Plane(0, 1, 0, 0)

func _ready() -> void:
	call_deferred("connect", "body_entered", _on_body_entered)

func _on_body_entered(body: Node3D):
	if not body is CharacterController:
		return

	var last_checkpoint = body.find_children("", "LastCheckpoint").pop_back()
	if not last_checkpoint:
		return

	if last_checkpoint.used_checkpoints.has(self):
		return

	last_checkpoint.checkpoint = self
	last_checkpoint.used_checkpoints[self] = null
