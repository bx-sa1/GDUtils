class_name DamageableTrait extends Trait

@export var health: float = 100

signal damaged(damage: float)

func on_take_damage(damage: float) -> void:
	health -= damage
	damaged.emit(damage)
