class_name Health extends Node

@export var health: float
var modifier: HealthModifier

signal killed

func _process(delta: float) -> void:
	if modifier:
		if not modifier.tick(health, delta):
			modifier = null

	if health <= 0:
		killed.emit()

func take_damage(dmg: float, mod: HealthModifier = null):
	health -= dmg
	modifier = mod
