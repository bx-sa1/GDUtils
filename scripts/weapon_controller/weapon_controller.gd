@tool
class_name WeaponController extends Node3D

var _debug_viewmodel_weapon: Weapon = null

@export var debug_weapon: PackedScene
@export_tool_button("Debug Viewmodel") var debug_viewmodel = func():
	if _debug_viewmodel_weapon != null:
		return

	_debug_viewmodel_weapon = debug_weapon.instantiate()
	assert(_debug_viewmodel_weapon is Weapon)
	if _debug_viewmodel_weapon != null:
		parent_node.add_child(_debug_viewmodel_weapon)
		_debug_viewmodel_weapon.owner = get_tree().edited_scene_root

@export_tool_button("Remove Debug Viewmodel") var remove_debug_viewmodel = func():
	if _debug_viewmodel_weapon == null:
		return
	else:
		parent_node.remove_child(_debug_viewmodel_weapon)
		_debug_viewmodel_weapon.owner = null
		_debug_viewmodel_weapon = null

@export_category("Settings")
@export_flags_3d_physics var ray_collision_mask: int = 0b1
@export var parent_node: Node3D

var weapon_stack: Array[Weapon]
var current_weapon_id: int = -1
var character: CharacterController

signal weapon_changed(old_weapon: Weapon, new_weapon: Weapon)
signal reload_finished

func _ready() -> void:
	if Engine.is_editor_hint():
		return

	var parent = get_parent()
	assert(parent is CharacterController)
	character = parent


func is_fire_pressed(fire_action: String) -> bool:
	var weapon = get_current_weapon()
	if not weapon:
		return false

	if weapon.data.auto:
		return Input.is_action_pressed(fire_action)
	else:
		return Input.is_action_just_pressed(fire_action)

func give_weapon(weapon: Weapon) -> void:
	var weap = weapon.duplicate()
	if not weapon_stack.has(weapon):
		var slot = weap.data.slot
		if slot == -1:
			weapon_stack.push_back(weap)
			change_weapon(len(weapon_stack) - 1)
		else:
			if slot >= len(weapon_stack):
				weapon_stack.resize(slot + 1)
			weapon_stack[slot] = weap
			change_weapon(slot)

func drop_weapon(id: int) -> void:
	var weapon: Weapon = weapon_stack.get(id)
	if not weapon:
		return

	weapon_stack.remove_at(id)
	var weapon_pickup: WeaponPickup = weapon.make_pickup()
	weapon_pickup.linear_velocity = 10 * -global_basis.z
	get_tree().root.add_child(weapon_pickup)
	weapon.queue_free()

func change_weapon(new_id: int) -> void:
	if len(weapon_stack) == 0:
		return

	if new_id < 0:
		new_id = len(weapon_stack) - 1
	elif new_id >= len(weapon_stack):
		new_id = 0

	var current_weapon: Weapon = weapon_stack[current_weapon_id] if current_weapon_id != -1 else null
	var new_weapon: Weapon = weapon_stack[new_id]
	if new_weapon == null:
		change_weapon(new_id + 1)
	current_weapon_id = new_id

	if current_weapon != null:
		parent_node.remove_child(current_weapon)

	parent_node.add_child(new_weapon)
	new_weapon.owner = owner

	weapon_changed.emit(current_weapon, new_weapon)

func reload() -> void:
	var weapon: Weapon = get_current_weapon()
	if not weapon:
		return

	weapon.start_reload()
	if character.has_meta("WeaponReloadTrait"):
		var weapon_reload_trait: WeaponReloadTrait = character.get_meta("WeaponReloadTrait")
		await weapon_reload_trait.on_reload(weapon)
	weapon.finish_reload()

func fire(origin: Vector3, dir: Vector3) -> void:
	var weapon: Weapon = get_current_weapon()
	if not weapon:
		return

	if weapon.data.should_reload():
		reload()
		return
	if not weapon.data.can_fire():
		return

	if character.has_meta("WeaponFireTrait"):
		var weapon_fire_trait: WeaponFireTrait = character.get_meta("WeaponReloadTrait")
		await weapon_fire_trait.on_fire(weapon)

	weapon.fire(origin, dir, ray_collision_mask)



func get_current_weapon() -> Weapon:
	return weapon_stack[current_weapon_id] if current_weapon_id > -1 else null

func debug_print() -> String:
	var weapon = get_current_weapon()
	if not weapon:
		return ""

	return """
	Weapon: %s
	Ammo: %d/%d
	""" % [weapon.data.name, weapon.data.ammo_count, weapon.data.max_ammo_count]
