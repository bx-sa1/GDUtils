@tool
@abstract
class_name Weapon extends Node3D

@export var weapon_name: String
@export var slot = -1
@export var debug: bool = false
@export var hit_scene: PackedScene
@export var pickup_scene: PackedScene
@export var fire_point_node_group_name: StringName = "fire_point"
@export_category("Stats")
@export var max_fire_distance: float = 1000
@export var max_ammo_count: int = 1
# How many ammunitions to fire at once
@export var fire_ammount: int = 1
# How many times you can shoot per second
@export var fire_rate: float = 1.0
@export var spread: float = 0.0
@export var recoil_pattern: Curve2D
@export var auto: bool = false
@export var damage: float
@export var modifier: HealthModifier

var heat: float = 0.0
var ammo_count: int = max_ammo_count
var cooldown: bool = false
var t_cooldown: float
var reloading: bool = false

signal cooldown_finished

func _get_configuration_warnings() -> PackedStringArray:
	var warnings = PackedStringArray()

	if not _check_fire_point():
		warnings.push_back("Weapon does not have a child node in group %s." % fire_point_node_group_name)

	return warnings

func make_pickup() -> WeaponPickup:
	var pickup = pickup_scene.instantiate()
	assert(pickup is WeaponPickup)

	var parent = get_parent()
	if parent != null:
		parent.remove_child(self)
	pickup.weapon = self
	pickup.add_child(self)
	self.position = Vector3.ZERO
	return pickup

func _check_fire_point() -> bool:
	var fire_point = _get_fire_point()
	if not fire_point:
		return false
	return true

func start_reload() -> void:
	if reloading:
		return

	reloading = true

func finish_reload() -> void:
	if not reloading:
		return

	heat = 0.0
	ammo_count = max_ammo_count
	reloading = false

func start_fire(origin: Vector3, dir: Vector3, collision_mask: int) -> void:
	var ammount
	if is_infinite_ammo():
		ammount = fire_ammount
	else:
		ammo_count -= fire_ammount
		cooldown = true
		ammount = fire_ammount - ammo_count if ammo_count < 0 else fire_ammount
		if ammo_count <= 0:
			ammo_count = 0

	for i in ammount:
		var spread_dir = get_spread_dir(dir)
		var aim_point = _get_aim_point(origin, spread_dir, collision_mask)
		if debug:
			DebugDraw.draw_ray(get_tree(), origin, aim_point, 0.07, 0.2, Color(1, 1, 0, 1), 10)
		_fire(aim_point, collision_mask)

@abstract
func _fire(aim_point: Vector3, collision_mask: int) -> void

func finish_fire() -> void:
	pass

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		update_configuration_warnings()
		return

	heat = max(0.0, heat - delta / max_ammo_count)
	if cooldown:
		t_cooldown -= delta
		if t_cooldown <= 0:
			cooldown = false
			t_cooldown = 1.0/fire_rate
			cooldown_finished.emit()


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
	if debug:
		DebugDraw.draw_ray(get_tree(), from, to, 0.07, 0.2, Color(1, 0, 0, 1), 10)
	return get_world_3d().direct_space_state.intersect_ray(params)


func _spawn_hit_scene(collider: Node3D, position: Vector3, normal: Vector3):
	if not hit_scene:
		return

	var decal: Node3D = hit_scene.instantiate()
	collider.add_child(decal)

	decal.global_position = position + normal * 0.01
	var decal_rotation = Quaternion(decal.global_basis.z, normal)
	decal.quaternion *= decal_rotation

func is_coolingdown() -> bool:
	return cooldown

func should_reload() -> bool:
	return ammo_count == 0 and not is_infinite_ammo()

func is_infinite_ammo() -> bool:
	return max_ammo_count == 0

func get_ammo_fraction() -> float:
	return ammo_count/max_ammo_count

func get_rand_spread_angle() -> float:
	return randf_range(-deg_to_rad(spread), deg_to_rad(spread))

func get_spread_dir(ray_dir: Vector3) -> Vector3:
	return Quaternion.from_euler(Vector3(
		get_rand_spread_angle(),
		get_rand_spread_angle(),
		get_rand_spread_angle())) * ray_dir

func can_fire() -> bool:
	return reloading == false and cooldown == false
