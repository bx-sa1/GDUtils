class_name InventoryManager

var allowed_types: Array[Variant]

var items: Array
var last_insert_pos = 0

func _init(size: int, _allowed_types: Array[Variant]) -> void:
	allowed_types = _allowed_types
	items.resize(size)
	items.fill(null)

func add_item(item: Variant) -> void:
	for type in allowed_types:
		if not is_instance_of(item, type):
			return

	while true:
		if items[last_insert_pos] == null:
			items[last_insert_pos] = item
			break
		last_insert_pos += 1

func remove_item(pos: int) -> void:
	items[pos] = null

func get_item(pos: int) -> Variant:
	return items.get(pos)
