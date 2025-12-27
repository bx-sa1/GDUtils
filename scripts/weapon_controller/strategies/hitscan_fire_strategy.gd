class_name HitscanFireStrategy extends GunFireStrategy

func fire(weapon: Weapon, origin: Vector3, dir: Vector3, collision_mask: int) -> void:
	var init_hit = _initial_hit_test(weapon, origin, dir, collision_mask)
	var weapon_fire_point = weapon.get_fire_point()
	if not weapon_fire_point:
		return

	var ray_start = weapon_fire_point.global_position
	var ray_dir = (init_hit - ray_start).normalized()
	var ray_end = init_hit+ray_dir*2
	var params = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	var hit = weapon.get_world_3d().direct_space_state.intersect_ray(params)
	if hit:
		weapon.collider_call_take_damage(weapon.data.damage, hit.collider, hit.position, hit.normal)
		weapon.add_decal_to_world(hit.position, hit.normal)
