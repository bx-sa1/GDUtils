class_name PickupTrait extends Trait

@export var hold_distance: float = 3
@export var hold_lerp: float = 0.3
var current_holding: RigidBody3D
var current_holding_freeze_mode: RigidBody3D.FreezeMode

func _ready() -> void:
	super()
	assert(trait_owner is CharacterBody3D)

func pickup(node: RigidBody3D) -> void:
	if current_holding or node == null:
		current_holding.freeze = false
		current_holding.freeze_mode = current_holding_freeze_mode
		current_holding = null
	else:
		current_holding = node
		current_holding.freeze = true
		current_holding_freeze_mode = current_holding.freeze_mode
		current_holding.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

func _process(delta: float) -> void:
	if current_holding:
		var head = trait_owner.head
		var current_position = current_holding.global_position
		var new_position = head.global_transform.translated_local(Vector3.FORWARD*hold_distance).origin
		current_holding.move_and_collide((new_position - current_position) * hold_lerp)
		current_holding.global_basis = Basis(current_holding.global_basis.get_rotation_quaternion().slerp(head.global_basis.get_rotation_quaternion(), hold_lerp))
