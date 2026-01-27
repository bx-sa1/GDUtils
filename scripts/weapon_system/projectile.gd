@tool
class_name Projectile extends ShapeCast3D

@export var explosion: PackedScene

var _weapon: Weapon
var velocity: Vector3


func _init() -> void:
	collide_with_areas = true
	collide_with_bodies = true
	target_position = Vector3.ZERO

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	if not _weapon:
		printerr("_weapon not properly assigned")
		queue_free()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var gravity_dir = PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR)
	var gravity_mag = PhysicsServer3D.area_get_param(get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY)
	velocity += gravity_dir * gravity_mag * delta

	var motion = velocity * delta
	target_position = to_local(global_position + motion)
	force_shapecast_update()
	global_position += motion * get_closest_collision_unsafe_fraction()

	if is_colliding():
		if explosion:
			var e = explosion.instantiate()
			assert(e is ProjectileExplosion, "explosion is not a ProjectileExplosion")
			add_sibling(e)
			e.global_position = global_position
			e._weapon = _weapon
			e.collision_mask = 0xFFFFFFFF
		else:
			print("hit %s" % get_collision_count())
			for c in get_collision_count():
				var collider = get_collider(c)
				_weapon._spawn_hit_scene(collider, get_collision_point(c), get_collision_normal(c))
				if collider is HurtBox:
					var hurtbox: HurtBox = collider
					hurtbox.health.take_damage(_weapon.damage * hurtbox.damage_percentage, _weapon.modifier)
					break
		queue_free()
