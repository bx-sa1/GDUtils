class_name MuzzleFlashPostFireStrategy extends WeaponPostFireStrategy

@export var muzzle_flash_scene: PackedScene
@export var muzzle_flash_time: float = 0.2

func postfire(weapon: Weapon) -> void:
	var fire_point = weapon.get_fire_point()
	if fire_point == null:
		return
	var muzzle_flash = muzzle_flash_scene.instantiate()
	var timer = Timer.new()
	timer.wait_time = muzzle_flash_time
	timer.autostart = true
	timer.timeout.connect(func(): muzzle_flash.queue_free())
	muzzle_flash.add_child(timer)
	weapon.add_child(muzzle_flash)
