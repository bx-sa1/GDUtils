class_name MeleeFireStrategy extends WeaponFireStrategy

@export var melee_range = 2

func fire(weapon: Weapon, origin: Vector3, dir: Vector3, collision_mask: int) -> void:
	var params = PhysicsRayQueryParameters3D.create(origin, origin + dir * melee_range, collision_mask)
	var hit = weapon.get_world_3d().direct_space_state.intersect_ray(params)
	if hit:
		weapon.collider_call_take_damage(weapon.data.damage, hit.collider, hit.position, hit.normal)
		weapon.add_decal_to_world(hit.position, hit.normal)
