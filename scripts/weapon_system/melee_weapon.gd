@tool
class_name MeleeWeapon extends Weapon

@export var hitbox: Area3D
@export var force: float = 1.0
@export var force_decay_rate: float = 1.0

func _ready() -> void:
	hitbox.monitoring = false

func _process(delta: float) -> void:
	if not hitbox.monitoring:
		return

	for body in hitbox.get_overlapping_bodies():
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

		var dmg = body.find_children("", "Damageable")
		if dmg:
			dmg.damage(decay, Vector3.INF, Vector3.ZERO)

func _fire(aim_point: Vector3, collision_mask: int) -> void:
	hitbox.monitoring = true
	await get_tree().create_timer(1.0).timeout
	hitbox.monitoring = false
