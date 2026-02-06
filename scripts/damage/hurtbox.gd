class_name HurtBox extends Area3D

@export var health: Health
@export var damage_percentage: float = 1.0
@export var ignore: Array[Node]
signal damaged(hitbox: HitBox)

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D):
	if area is HitBox and ignore.find(area) == -1:
		var hitbox = area as HitBox
		if health:
			health.take_damage(hitbox.damage * damage_percentage, hitbox.modifier)
			hitbox.damaged.emit(self)
			damaged.emit(hitbox)
