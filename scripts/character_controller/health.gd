class_name Health extends Node

@export var health: float
var modifier: HealthModifier

func _process(delta: float) -> void:
	if modifier:
		if not modifier.tick(health, delta):
			modifier = null

func take_damage(dmg: float, mod: HealthModifier = null):
	health -= dmg
	modifier = mod
