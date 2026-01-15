class_name Interactable extends Node

@export var holdable := false

signal focused
signal unfocused
signal interacted(caller: Node)

func focus() -> void:
	focused.emit()

func unfocus() -> void:
	unfocused.emit()

func interact(caller: Node) -> void:
	interacted.emit(caller)
