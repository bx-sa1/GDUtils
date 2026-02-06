class_name HitBox extends Area3D

@export var modifier: HealthModifier
@export var damage: float

signal damaged(hurtbox: HurtBox)
