## Base class for nodes that expose functions to their parents through the meta data system.
## Essentially a replacement for using has_method, but gives type inference to IDEs.
@abstract
class_name Trait extends Node

var trait_owner

func _ready() -> void:
	trait_owner = get_parent()
	assert(trait_owner != null)

	var meta_name: String = get_script().get_global_name()
	if meta_name == "":
		meta_name = get_script().get_base_script().get_global_name()

	trait_owner.set_meta(meta_name, self)
