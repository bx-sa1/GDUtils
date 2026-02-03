class_name Inventory extends Node

class Item:
	var scene: PackedScene
	var meta: Dictionary

	func _init(scene, meta) -> void:
		self.scene = scene
		self.meta = meta

@export var max_size: int

var items: Array[Item]

signal item_added(item: Item, pos: int)
signal item_removed(item: Item, pos: int)

func add_item(item: Node) -> void:
	if items.size() >= max_size:
		return

	var meta = item.get_metadata()
	var scene = load(item.scene_file_path)
	if not scene:
		return

	var inv_item = Item.new(scene, meta)
	items.push_back(inv_item)
	item_added.emit(inv_item, items.size()-1)

func remove_item(pos: int) -> void:
	var item = items.pop_at(pos)
	if item:
		item_removed.emit(item, pos)

func get_item(pos: int) -> Item:
	return items.get(pos)
