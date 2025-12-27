class_name ProjectileExplosion extends Area3D

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
		if body is RigidBody3D or body is PhysicalBone3D:
			body.apply_impulse(force_dir * force_mag)
		else:
			if body.has_method("_on_weapon_hit_explosion_impulse"):
				body.get("_on_weapon_hit_explosion_impulse").call(_weapon, force_dir * force_mag)
			else:
				printerr("Body ", body.name, " does not have method _on_weapon_hit_explosion_impulse.")
			_weapon.collider_call_take_damage(_weapon.data.damage * decay, body)
