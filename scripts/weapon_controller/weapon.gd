class_name Weapon extends Node3D

@export var data: WeaponData
@export var fire_point_node_group_name = "fire_point"

var weapon_controller: WeaponController

func _ready() -> void:
	data.init()
	var parent =  get_parent()
	if parent is WeaponController:
		weapon_controller = parent

func reload() -> void:
	if not weapon_controller:
		return

	if weapon_controller.has_meta("ReloadTrait"):
		var reload_t = weapon_controller.get_meta("ReloadTrait")
		await reload_t.on_reload(self)
	else:
		await get_tree().create_timer(1).timeout

func fire(origin: Vector3, dir: Vector3, collision_mask: int) -> void:
	if not weapon_controller:
		return
	if data.should_reload():
		reload()
		return
	if not data.can_fire():
		return

	if not data.fire_strategy:
		return

	var ammount = data.fire()
	for i in ammount:
		var spread_dir = data.get_spread_dir(dir)
		data.fire_strategy.fire(self, origin, spread_dir, collision_mask)
		for post in data.post_fire_strategies:
			post.postfire(self)

	if weapon_controller.has_meta("FireTrait"):
		var fire_t = weapon_controller.get_meta("FireTrait")
		await fire_t.on_fire(self)

func _process(delta: float) -> void:
	data.update_cooldown(delta)

func get_fire_point() -> Node3D:
	for child in get_children():
		if child.is_in_group(fire_point_node_group_name):
			return child
	print(self.name, " does not have a node in group \"", fire_point_node_group_name, "\"")
	return null

func add_decal_to_world(position: Vector3, normal: Vector3):
	if not data.hit_decal:
		return

	var decal: Node3D = data.hit_decal.instantiate()
	get_tree().get_root().add_child(decal)

	decal.global_position = position + normal * 0.01
	var decal_rotation = Quaternion(decal.global_basis.z, normal)
	decal.quaternion *= decal_rotation
