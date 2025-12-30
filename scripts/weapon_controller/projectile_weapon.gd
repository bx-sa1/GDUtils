@tool
class_name ProjectileWeapon extends Weapon

@export var projectile: PackedScene
@export var projectile_speed: float
@export_flags_3d_physics var projectile_collision_layer: int = 2

func _fire(aim_point: Vector3, collision_mask: int) -> void:
	if not projectile:
		return


	var p = projectile.instantiate()
	assert(p is Projectile)
	p._weapon = self
	p.collision_layer = projectile_collision_layer
	p.collision_mask = 9223372036854775807 & ~p.collision_layer

	var fire_point = _get_fire_point()
	if not fire_point:
		return

	var from = fire_point.global_position
	var p_dir = (aim_point - from).normalized()

	get_tree().get_root().add_child(p)
	p.global_position = from
	p.linear_velocity = p_dir * projectile_speed
	p.look_at(from + p_dir)
