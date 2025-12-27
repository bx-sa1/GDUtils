class_name ProjectileFireStrategy extends GunFireStrategy

@export var projectile: PackedScene
@export var projectile_speed: float

func fire(weapon: Weapon, origin: Vector3, dir: Vector3, collision_mask: int) -> void:
	if not projectile:
		return


	var p = projectile.instantiate()
	assert(p is Projectile)

	var new_collision_mask = p.collision_mask
	var init_hit = _initial_hit_test(weapon, origin, dir, new_collision_mask)

	var fire_point = weapon.get_fire_point()
	if not fire_point:
		return

	var from = fire_point.global_position
	var p_dir = (init_hit - from).normalized()

	p._weapon = weapon
	weapon.get_tree().get_root().add_child(p)
	p.global_position = from
	p.linear_velocity = p_dir * projectile_speed
	p.look_at(from + p_dir)
