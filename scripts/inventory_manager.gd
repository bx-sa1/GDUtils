class_name InventoryManager extends Node

@export var size: int

var items: Array
var last_insert_pos = 0
var equip_ptr: int = -1

signal item_added(item: Variant, pos: int)
signal item_removed(item: Variant, pos: int)
signal item_equipped(item: Variant)

func _ready() -> void:
	items.resize(size)
	items.fill(null)

func add_item(item: Variant, pos: int = -1) -> void:
	if pos != -1:
		items[pos] = item
		item_added.emit(item, pos)
	else:
		while true:
			if items[last_insert_pos] == null:
				items[last_insert_pos] = item
				break
			last_insert_pos += 1
		item_added.emit(item, last_insert_pos)

func remove_item(pos: int) -> void:
	var item = items[pos]
	items[pos] = null
	item_removed.emit(item, pos)

func equip_relative(rel: int) -> void:
	for i in range(size):
		equip_ptr += rel
		if equip_ptr < 0:
			equip_ptr = size
		elif equip_ptr >= size:
			equip_ptr = 0
		var item = items.get(equip_ptr)
		if item != null:
			item_equipped.emit(item)
			return

func equip_absolute(_abs: int) -> void:
	var item = items.get(_abs)
	if item:
		item_equipped.emit(item)
	else:
		print_debug("No Item at position %s" % _abs)
