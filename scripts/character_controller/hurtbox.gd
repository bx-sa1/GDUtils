class_name HurtBox extends Area3D

@export var health: Health
var damage_percentage: float = 1.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area3D):
	if area is HitBox:
		var hitbox = area as HitBox
		if health:
			health.take_damage(hitbox.damage * damage_percentage, hitbox.modifier)
