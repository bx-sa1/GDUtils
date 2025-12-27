extends CharacterController

@export var weapon_controller: WeaponController

var enable_weapon = true
var enable_interaction = true

func _ready() -> void:
	if enable_weapon:
		weapon_controller.change_weapon(0)


func _input(event: InputEvent) -> void:
	look(event)

func _process(delta: float) -> void:
	if enable_interaction:
		var camera = get_viewport().get_camera_3d()
		var viewport_size = get_viewport().get_size()
		var origin = camera.project_ray_origin(viewport_size/2)
		var dir = camera.project_ray_normal(viewport_size/2)
		check_focus(origin, dir, Input.is_action_just_pressed("interact"))

	if enable_weapon:
		if weapon_controller.is_fire_pressed("fire"):
			weapon_controller.fire()

func _physics_process(delta: float) -> void:
	var idir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	move(delta, idir)
