@abstract
class_name GunFireStrategy extends WeaponFireStrategy


func fire(weapon: Weapon, origin: Vector3, dir: Vector3, collision_mask: int) -> void:
	return

func _initial_hit_test(weapon: Weapon, origin: Vector3, dir: Vector3, collision_mask: int) -> Vector3:
	var ray_start = origin
	var ray_end = origin + dir * 10000
	var params = PhysicsRayQueryParameters3D.create(ray_start, ray_end, collision_mask)
	var hit = weapon.get_world_3d().direct_space_state.intersect_ray(params)
	if hit:
		return hit.position
	else:
		return ray_end
