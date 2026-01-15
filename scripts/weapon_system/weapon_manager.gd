class_name WeaponManager extends Node3D

@export_flags_3d_physics var fire_collision_mask: int  = 1 ## Coliision mask for raycasts
@export var weapon_parent_node: Node ## Node to parent current weapon to
@export var fire_at_center_of_screen: bool = true
@export var fire_action: String = "fire"
@export var reload_action: String = "jump"
@export var drop_action: String = "drop"

var current_weapon: Weapon
var fire_just_pressed: bool = false
var reload_just_pressed: bool = false
var drop_just_pressed: bool = false

signal reload_started
signal reload_finished
signal fire_started
signal fire_finished
signal weapon_changed(new_weapon: Weapon)
signal recoil(yaw: float, pitch: float)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed(fire_action):
		if current_weapon and current_weapon.data.auto:
			fire()
		elif not fire_just_pressed:
			fire_just_pressed = true
			fire()
	elif not reload_just_pressed and event.is_action_pressed(reload_action):
		reload_just_pressed = true
		reload()
	elif not drop_just_pressed and event.is_action_pressed(drop_action):
		drop_just_pressed = true
		drop_weapon(true)


func _process(delta: float) -> void:
	if fire_just_pressed:
		fire_just_pressed = false
	if reload_just_pressed:
		reload_just_pressed = false
	if drop_just_pressed:
		drop_just_pressed = false

func set_weapon_parent(parent: Node) -> void:
	current_weapon.get_parent().remove_child(current_weapon)
	weapon_parent_node = parent
	weapon_parent_node.add_child(current_weapon)

## Set current weapon, and return the last weapon.
## If drop is true, drop the old weapon as a pickup into the world
## if false, just remove the old weapon from the weapon manager
func set_weapon(weapon: Weapon, drop_as_pickup = false) -> Weapon:
	if weapon.get_parent() != null:
		weapon.get_parent().remove_child(weapon)
	weapon_parent_node.add_child(weapon)

	var last_weapon = current_weapon
	drop_weapon(drop_as_pickup)
	current_weapon = weapon
	weapon_changed.emit(current_weapon)

	return last_weapon

func drop_weapon(as_pickup = false) -> void:
	if current_weapon == null:
		return

	weapon_parent_node.remove_child(current_weapon)
	if as_pickup:
		var pickup: WeaponPickup = current_weapon.make_pickup()
		weapon_parent_node.get_tree().get_root().add_child(pickup)
		pickup.global_transform = weapon_parent_node.global_transform
		pickup.apply_impulse(-pickup.global_basis.z * 10)
	current_weapon = null
	weapon_changed.emit(current_weapon)

func reload() -> void:
	if not current_weapon:
		return

	current_weapon.start_reload()
	if reload_started.has_connections():
		reload_started.emit()
		await reload_finished
	current_weapon.finish_reload()

func fire() -> void:
	if not current_weapon:
		return

	var origin: Vector3
	var dir: Vector3
	if fire_at_center_of_screen:
		var camera = get_viewport().get_camera_3d()
		var viewport_size = get_viewport().get_size()
		origin = camera.project_ray_origin(viewport_size/2)
		dir = camera.project_ray_normal(viewport_size/2)
	else:
		origin = global_position
		dir = -global_basis.z

	if current_weapon.data.should_reload():
		reload()
		return
	if not current_weapon.data.can_fire():
		return

	current_weapon.start_fire(origin, dir, fire_collision_mask)
	if fire_started.has_connections():
		fire_started.emit()
		await fire_finished
	current_weapon.finish_fire()

	do_recoil()

func do_recoil() -> void:
	if not current_weapon:
		return

	var pattern = current_weapon.data.recoil_pattern
	if not pattern:
		return

	var progress = (current_weapon.data.max_ammo_count - current_weapon.data.ammo_count)/pattern.point_count
	var rot = pattern.samplef(progress)
	recoil.emit(-rot.x, -rot.y)
