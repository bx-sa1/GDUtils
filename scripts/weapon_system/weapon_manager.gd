class_name WeaponManager

var fire_collision_mask: int  ## Coliision mask for raycasts
var weapon_parent_node: Node ## Node to parent current weapon to

var current_weapon: Weapon

signal reload_started
signal reload_finished
signal fire_started
signal fire_finished
signal weapon_changed(new_weapon: Weapon)

func _init(parent: Node, collision_mask: int = 0b1) -> void:
	assert(parent != null)
	weapon_parent_node = parent
	fire_collision_mask = collision_mask

func is_fire_pressed(fire_action: String) -> bool:
	if not current_weapon:
		return false

	if current_weapon.data.auto:
		return Input.is_action_pressed(fire_action)
	else:
		return Input.is_action_just_pressed(fire_action)

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

func fire(origin: Vector3, dir: Vector3) -> void:
	if not current_weapon:
		return

	if current_weapon.data.should_reload():
		reload()
		return
	if not current_weapon.data.can_fire():
		return

	current_weapon.fire(origin, dir, fire_collision_mask)
