class_name Projectile extends RigidBody3D

@export var explosion: PackedScene

var _weapon: Weapon


func _ready() -> void:
	if not _weapon:
		printerr("_weapon not properly assigned")
		queue_free()

	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 1


func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if state.get_contact_count() > 0:
		var pos: Vector3 = state.get_contact_local_position(0)
		var norm: Vector3 = state.get_contact_local_normal(0)
		var col: Node = state.get_contact_collider_object(0)
		if explosion:
			var e = explosion.instantiate()
			assert(e is ProjectileExplosion, "explosion is not a ProjectileExplosion")
			add_sibling(e)
			e.global_position = pos
			e._weapon = _weapon
			e.collision_mask = 0xFFFFFFFF
		else:
			_weapon._call_collider_damageable_trait(col, pos, norm)
			_weapon._spawn_hit_scene(pos, norm)
		queue_free()
