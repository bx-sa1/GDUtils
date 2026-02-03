class_name Interactable extends Node3D

@export var id: StringName = ""
@export var activator_id: StringName = ""
@export var display_name: String = ""
@export var enabled: bool = true
@export var holdable: bool = false
@export var pickup: bool = false

signal focused
signal unfocused
signal interacted

func _ready() -> void:
	add_to_group("interactables")
	_connect_activator.call_deferred()

func _connect_activator() -> void:
	if activator_id == "":
		return
	for node in get_tree().get_nodes_in_group("interactables"):
		if node is Interactable and node.id == activator_id:
			node.interacted.connect(interact)

func focus() -> void:
	focused.emit()

func unfocus() -> void:
	unfocused.emit()

func interact() -> void:
	interacted.emit()
