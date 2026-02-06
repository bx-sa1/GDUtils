@tool
class_name CharacterHeadController extends Node3D

@export var debug := false
@export var look_sensitivity: float = 1.0
@export_range(0, 90) var pitch_lower_limit: float = 89
@export_range(0, 90) var pitch_upper_limit: float = 89

var mouse_captured := false
var yaw := 0.0
var pitch := 0.0

var parent: CharacterController


func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if get_parent() is not CharacterController:
		warnings.push_back("Must be a child of a CharacterController")

	return warnings

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	parent = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	if not mouse_captured:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		mouse_captured = true

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			yaw += -event.relative.x * look_sensitivity * 0.1
			pitch += -event.relative.y * look_sensitivity * 0.1
			apply_rotation()

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var motion = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	if motion.length() > 0:
		yaw -= motion.x * look_sensitivity
		pitch -= motion.y * look_sensitivity
		apply_rotation()

func apply_rotation() -> void:
	pitch = clampf(pitch, -pitch_lower_limit, pitch_upper_limit)
	var rot = Vector3(deg_to_rad(pitch), deg_to_rad(yaw), 0)
	if parent.strafe:
		transform.basis = Basis(Vector3.RIGHT, rot.x)
		parent.transform.basis = Basis(Vector3.UP, rot.y)
	else:
		transform.basis = Basis.from_euler(rot)
