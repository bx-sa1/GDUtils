class_name Health extends Node

@export var health: float
var modifier: HealthModifier
var start_health: float

signal killed

func _ready() -> void:
	start_health = health

func _process(delta: float) -> void:
	if modifier:
		if not modifier.tick(health, delta):
			modifier = null

	if health <= 0:
		killed.emit()

func take_damage(dmg: float, mod: HealthModifier = null):
	health -= dmg
	modifier = mod
