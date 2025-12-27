@tool
extends Control

@export var dot_radius: float = 3:
	set(v):
		dot_radius = v
		queue_redraw()
@export var dot_color: Color = Color(0,1,0,1):
	set(v):
		dot_color = v
		queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, dot_radius, dot_color)
