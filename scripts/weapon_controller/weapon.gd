@tool
@abstract
class_name Weapon extends Node3D

@export var data: WeaponData
@export var max_fire_distance: float = 1000
@export var hit_scene: PackedScene
@export var pickup_scene: PackedScene
@export var fire_point_node_group_name: StringName = "fire_point"

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()

	if not _check_fire_point():
		warnings.push_back("Weapon does not have a child node in group %s." % fire_point_node_group_name)

	return warnings

func _ready() -> void:
	if not Engine.is_editor_hint():
		data.init()

func make_pickup() -> WeaponPickup:
	var pickup = pickup_scene.instantiate()
	assert(pickup is WeaponPickup)

	var new_self = self.duplicate()
	pickup.weapon = new_self
	pickup.add_child(new_self)
	new_self.position = Vector3.ZERO
	return pickup

func _check_fire_point() -> bool:
	var fire_point = _get_fire_point()
	if not fire_point:
		return false
	return true

func start_reload() -> void:
	data.start_reload()

func finish_reload() -> void:
	data.finish_reload()

func fire(origin: Vector3, dir: Vector3, collision_mask: int) -> void:
	var ammount = data.fire()
	for i in ammount:
		var spread_dir = data.get_spread_dir(dir)
		var aim_point = _get_aim_point(origin, spread_dir, collision_mask)
		_fire(aim_point, collision_mask)

@abstract
func _fire(aim_point: Vector3, collision_mask: int) -> void

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
	else:
		data.update_cooldown(delta)

func _get_fire_point() -> Node3D:
	for child in get_children():
		if child.is_in_group(fire_point_node_group_name):
			return child
	return null

func _get_aim_point(origin: Vector3, dir: Vector3, collision_mask: int) -> Vector3:
	var hit = _ray_cast(origin, origin+dir*max_fire_distance, collision_mask)
	if hit:
		return hit.position
	else:
		return origin+dir*max_fire_distance

func _ray_cast(from: Vector3, to: Vector3, collision_mask: int) -> Dictionary:
	var params = PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	return get_world_3d().direct_space_state.intersect_ray(params)


func _spawn_hit_scene(position: Vector3, normal: Vector3):
	if not data.hit_decal:
		return

	var decal: Node3D = data.hit_decal.instantiate()
	get_tree().get_root().add_child(decal)

	decal.global_position = position + normal * 0.01
	var decal_rotation = Quaternion(decal.global_basis.z, normal)
	decal.quaternion *= decal_rotation

func _call_collider_damageable_trait(collider: Node, position: Vector3, normal: Vector3):
	if collider.has_meta("DamageableTrait"):
		var damageable_trait: DamageableTrait = collider.get_meta("DamageableTrait")
		damageable_trait.on_damage(data.damage, position, normal)
