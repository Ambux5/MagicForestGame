extends Node3D
## Procedural tree prop – several variations built at runtime.

@export var variation: int = 0  # 0-3 for different tree shapes

const TRUNK_COLOR := Color(0.35, 0.22, 0.10)
const FOLIAGE_COLORS := [
	Color(0.15, 0.52, 0.18),
	Color(0.18, 0.45, 0.12),
	Color(0.22, 0.58, 0.15),
	Color(0.12, 0.40, 0.20),
]


func _ready() -> void:
	var v := variation % 4
	match v:
		0: _build_round_tree()
		1: _build_tall_tree()
		2: _build_wide_tree()
		3: _build_ancient_tree()


func _build_round_tree() -> void:
	_add_trunk(0.12, 0.10, 1.2)
	_add_foliage_sphere(0.0, 1.55, 0.0, 0.75, 0)


func _build_tall_tree() -> void:
	_add_trunk(0.09, 0.08, 1.8)
	_add_foliage_cone(0.0, 1.8, 0.0, 0.55, 2.2, 1)


func _build_wide_tree() -> void:
	_add_trunk(0.15, 0.13, 1.0)
	_add_foliage_sphere(0.0, 1.4, 0.0, 1.1, 2)
	_add_foliage_sphere(0.4, 1.7, 0.2, 0.65, 3)
	_add_foliage_sphere(-0.35, 1.6, 0.3, 0.6, 0)


func _build_ancient_tree() -> void:
	_add_trunk(0.18, 0.15, 1.5)
	_add_trunk_offset(0.15, 0.08, 0.8, Vector3(0.25, 1.0, 0.1), deg_to_rad(20))
	_add_foliage_sphere(0.0, 2.0, 0.0, 0.9, 1)
	_add_foliage_sphere(0.5, 1.8, 0.2, 0.55, 3)


func _add_trunk(top_r: float, bot_r: float, height: float) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r + 0.04
	cyl.height = height
	cyl.radial_segments = 8
	mi.mesh = cyl
	mi.position = Vector3(0, height * 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = TRUNK_COLOR
	mat.roughness = 1.0
	mi.set_surface_override_material(0, mat)
	add_child(mi)


func _add_trunk_offset(top_r: float, bot_r: float, height: float, pos: Vector3, rot_z: float) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = height
	cyl.radial_segments = 6
	mi.mesh = cyl
	mi.position = pos
	mi.rotation.z = rot_z
	var mat := StandardMaterial3D.new()
	mat.albedo_color = TRUNK_COLOR
	mat.roughness = 1.0
	mi.set_surface_override_material(0, mat)
	add_child(mi)


func _add_foliage_sphere(x: float, y: float, z: float, radius: float, col_idx: int) -> void:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 1.6
	sph.radial_segments = 8
	sph.rings = 5
	mi.mesh = sph
	mi.position = Vector3(x, y, z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FOLIAGE_COLORS[col_idx % FOLIAGE_COLORS.size()]
	mat.roughness = 0.95
	mi.set_surface_override_material(0, mat)
	add_child(mi)


func _add_foliage_cone(x: float, y: float, z: float, base_r: float, height: float, col_idx: int) -> void:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.05
	cyl.bottom_radius = base_r
	cyl.height = height
	cyl.radial_segments = 8
	mi.mesh = cyl
	mi.position = Vector3(x, y + height * 0.5, z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = FOLIAGE_COLORS[col_idx % FOLIAGE_COLORS.size()]
	mat.roughness = 0.95
	mi.set_surface_override_material(0, mat)
	add_child(mi)
