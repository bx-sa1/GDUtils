class_name Utils

static func ray_trace(tree: SceneTree, start: Vector3, end: Vector3, collision_mask: int, exclude: Array[RID], debug := false, debug_color := Color(1,0,0,1), debug_ttl := 5.0) -> Dictionary:
	var params = PhysicsRayQueryParameters3D.create(start, end, collision_mask, exclude)
	if debug:
		DebugDraw.draw_ray(tree, start, end, 0.01, 0.02, debug_color, debug_ttl)
	var hit = tree.get_root().get_world_3d().direct_space_state.intersect_ray(params)
	if hit:
		return {
			"collider": hit.collider,
			"collider_id": hit.collider_id,
			"fraction": ((end - start)/hit.position).length(),
			"position": hit.position,
			"normal": hit.normal,
			"shape": hit.shape,
			"rid": hit.rid
			}
	else:
		return {
			"collider": null,
			"collider_id": -1,
			"fraction": 1.0,
			"position": end,
			"normal": Vector3.ZERO,
			"shape": null,
			"rid": -1
			}
