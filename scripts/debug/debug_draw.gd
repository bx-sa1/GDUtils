class_name DebugDraw

static var mat: Material = _create_mat()

static func _create_mat() -> Material:
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	return mat

static func draw_ray(tree: SceneTree, from: Vector3, to: Vector3, radius: float = 1, end_radius: float = 1.5, color: Color = Color(0,1,0,1), ttl: float = 1.0) -> void:

	draw_line(tree, from, to, radius, color, ttl)
	draw_point(tree, to, end_radius, color, ttl)

static func draw_line(tree: SceneTree, from: Vector3, to: Vector3, radius: float = 1, color: Color = Color(0,1,0,1), ttl: float = 1.0):
	var line_v = [
		from + Vector3(-radius, -radius, 0),
		from + Vector3(-radius, radius, 0),
		from + Vector3(radius, -radius, 0),
		from + Vector3(radius, radius, 0),
		to + Vector3(-radius, -radius, 0),
		to + Vector3(-radius, radius, 0),
		to + Vector3(radius, -radius, 0),
		to + Vector3(radius, radius, 0)
	]

	var line_i = [
		2, 0, 1,
		1, 3, 2,

		3, 1, 5,
		1, 7, 3,

		6, 2, 3,
		3, 7, 6,

		7, 5, 4,
		4, 6, 7,

		6, 4, 0,
		0, 2, 6,

		0, 4, 5,
		5, 1, 0
	]

	draw_mesh(tree, line_v, line_i, color, ttl)

static func draw_point(tree: SceneTree, point: Vector3, radius: float = 1, color: Color = Color(0,1,0,1), ttl: float = 1.0):
	var point_v = [
		point + Vector3(-radius, -radius, -radius),
		point + Vector3(-radius, radius, -radius),
		point + Vector3(radius, -radius, -radius),
		point + Vector3(radius, radius, -radius),
		point + Vector3(-radius, -radius, radius),
		point + Vector3(-radius, radius, radius),
		point + Vector3(radius, -radius, radius),
		point + Vector3(radius, radius, radius)
	]

	var point_i = [
		1, 0, 2,
		2, 3, 1,

		5, 1, 3,
		3, 7, 1,

		3, 2, 6,
		6, 7, 3,

		4, 5, 7,
		7, 6, 4,

		0, 4, 6,
		6, 2, 0,

		5, 4, 0,
		0, 1, 5
	]

	draw_mesh(tree, point_v, point_i, color, ttl)

static func draw_mesh(tree: SceneTree, verts: Array, ids: Array, color: Color, ttl: float = 1.0):
	var mesh: ImmediateMesh = ImmediateMesh.new()

	mesh.surface_begin(ImmediateMesh.PRIMITIVE_TRIANGLES, mat)
	mesh.surface_set_color(color)

	for id in ids:
		mesh.surface_add_vertex(verts[id])

	mesh.surface_end()

	_add_to_tree(tree, mesh, ttl)


static func _add_to_tree(tree: SceneTree, mesh: Mesh, ttl: float) -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	tree.get_root().add_child(mesh_instance)
	tree.create_timer(ttl).timeout.connect(func(): mesh_instance.queue_free())
