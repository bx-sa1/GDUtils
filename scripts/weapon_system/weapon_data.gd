class_name WeaponData extends Resource

@export var name: String
@export var slot = -1

@export_category("Stats")
@export var max_ammo_count: int = 1
# How many ammunitions to fire at once
@export var fire_ammount: int = 1
# How many times you can shoot per second
@export var fire_rate: float = 1.0
@export var spread: float = 0.0
@export var auto: bool = false
@export var damage: float

var ammo_count: int = max_ammo_count
var cooldown: bool = false
var t_cooldown: float
var reloading: bool = false

signal cooldown_finished

func init() -> void:
	ammo_count = max_ammo_count
	reloading = false
	cooldown = false

func is_coolingdown() -> bool:
	return cooldown

func should_reload() -> bool:
	return ammo_count == 0 and not is_infinite_ammo()

func is_infinite_ammo() -> bool:
	return max_ammo_count == 0

func start_reload() -> void:
	if reloading:
		return

	reloading = true

func finish_reload() -> void:
	if not reloading:
		return

	ammo_count = max_ammo_count
	reloading = false

func fire() -> int: # return how much is acctually fire
	var ammount
	if is_infinite_ammo():
		ammount = fire_ammount
	else:
		ammo_count -= fire_ammount
		cooldown = true
		ammount = fire_ammount - ammo_count if ammo_count < 0 else fire_ammount
		if ammo_count <= 0:
			ammo_count = 0

	return ammount

func update_cooldown(delta: float) -> void:
	if cooldown:
		t_cooldown -= delta
		if t_cooldown <= 0:
			cooldown = false
			cooldown_finished.emit()
	else:
		t_cooldown = 1.0/fire_rate

func get_rand_spread_angle() -> float:
	return randf_range(-deg_to_rad(spread), deg_to_rad(spread))

func get_spread_dir(ray_dir: Vector3) -> Vector3:
	return Quaternion.from_euler(Vector3(
		get_rand_spread_angle(),
		get_rand_spread_angle(),
		get_rand_spread_angle())) * ray_dir

func can_fire() -> bool:
	return reloading == false and cooldown == false
