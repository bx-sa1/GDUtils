@tool
class_name MeleeWeapon extends Weapon

@export var shape_cast: ShapeCast3D
@export var force: float = 1.0
@export var force_decay_rate: float = 1.0

func _ready() -> void:
	shape_cast.enabled = false

func _process(delta: float) -> void:
	for i in shape_cast.get_collision_count():
		var col = shape_cast.get_collider(i)
		var force_dir = (col.global_position - global_position).normalized()
		var dist = (col.global_position - global_position).length()
		var decay = exp(-(force_decay_rate * dist))
		var force_mag = force * decay
		if debug:
			DebugDraw.draw_ray(get_tree(), global_position, global_position+force_dir*force_mag, 0.07, 0.08, Color(0,0,1,1), 10)

		if col is RigidBody3D or col is PhysicalBone3D:
			col.apply_impulse(force_dir * force_mag)
		elif col is CharacterController:
			col.velocity = force_dir * force_mag
		else:
			_call_collider_damageable_trait(col, Vector3.INF, Vector3.ZERO, decay)

func _fire(aim_point: Vector3, collision_mask: int) -> void:
	shape_cast.enabled = true
