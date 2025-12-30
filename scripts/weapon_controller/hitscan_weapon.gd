@tool
class_name HitscanWeapon extends Weapon

func _fire(aim_point: Vector3, collision_mask: int) -> void:
	var weapon_fire_point = _get_fire_point()
	if not weapon_fire_point:
		return

	var ray_start = weapon_fire_point.global_position
	var ray_dir = (aim_point - ray_start).normalized()
	var ray_end = aim_point+ray_dir*2
	var hit = _ray_cast(ray_start, ray_end, collision_mask)
	if hit:
		_call_collider_damageable_trait(hit.collider, hit.position, hit.normal)
		_spawn_hit_scene(hit.position, hit.normal)
