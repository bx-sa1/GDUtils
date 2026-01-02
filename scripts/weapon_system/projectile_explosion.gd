class_name ProjectileExplosion extends Area3D

@export var debug: bool = false
@export var force: float = 1.0
@export var force_decay_rate: float = 1.0

var _weapon: Weapon

func _ready() -> void:
	await get_tree().physics_frame
	await get_tree().physics_frame
	_push_bodies()

func _push_bodies() -> void:
	for body in get_overlapping_bodies():
		var force_dir = (body.global_position - global_position).normalized()
		var dist = (body.global_position - global_position).length()
		var decay = exp(-(force_decay_rate * dist))
		var force_mag = force * decay
		if debug:
			DebugDraw.draw_ray(get_tree(), global_position, global_position+force_dir*force_mag, 0.07, 0.08, Color(0,0,1,1), 10)

		if body is RigidBody3D or body is PhysicalBone3D:
			body.apply_impulse(force_dir * force_mag)
		elif body is CharacterController:
			body.velocity = force_dir * force_mag
		else:
			_weapon._call_collider_damageable_trait(body, Vector3.INF, Vector3.ZERO, decay)
