extends Area3D
## Collectible item – auto-collects on player contact.
## Four types: HEAL_HERB, MANA_CRYSTAL, MAGIC_MUSHROOM, XP_CRYSTAL.

enum Type { HEAL_HERB, MANA_CRYSTAL, MAGIC_MUSHROOM, XP_CRYSTAL }

@export var item_type: Type = Type.HEAL_HERB
@export var value: float = 20.0  # heal/mana amount or XP amount

const COLORS := {
	Type.HEAL_HERB: Color(0.2, 0.9, 0.3),
	Type.MANA_CRYSTAL: Color(0.2, 0.4, 0.95),
	Type.MAGIC_MUSHROOM: Color(0.85, 0.3, 0.85),
	Type.XP_CRYSTAL: Color(1.0, 0.85, 0.1),
}
const NAMES := {
	Type.HEAL_HERB: "Healing Herb",
	Type.MANA_CRYSTAL: "Mana Crystal",
	Type.MAGIC_MUSHROOM: "Magic Mushroom",
	Type.XP_CRYSTAL: "Experience Crystal",
}

var _bob_time: float = 0.0
var _base_y: float = 0.0
var _mesh: MeshInstance3D
var _collected: bool = false


func _ready() -> void:
	collision_layer = 16
	collision_mask = 2
	monitoring = true
	monitorable = true

	_base_y = position.y
	_build_visuals()

	body_entered.connect(_on_body_entered)

	var col := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 0.5
	col.shape = sph
	add_child(col)


func _build_visuals() -> void:
	_mesh = MeshInstance3D.new()
	var shape: Mesh
	match item_type:
		Type.HEAL_HERB:
			shape = _make_herb_mesh()
		Type.MANA_CRYSTAL:
			shape = _make_crystal_mesh()
		Type.MAGIC_MUSHROOM:
			shape = _make_mushroom_mesh()
		Type.XP_CRYSTAL:
			shape = _make_crystal_mesh()
	_mesh.mesh = shape

	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLORS[item_type]
	mat.emission_enabled = true
	mat.emission = COLORS[item_type] * 0.6
	mat.emission_energy_multiplier = 1.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh.set_surface_override_material(0, mat)
	add_child(_mesh)

	# Glow light
	var light := OmniLight3D.new()
	light.light_color = COLORS[item_type]
	light.light_energy = 0.8
	light.omni_range = 1.5
	add_child(light)

	# Particle sparkle
	var particles := GPUParticles3D.new()
	particles.amount = 6
	particles.lifetime = 1.0
	particles.fixed_fps = 20
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.2
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 90.0
	pm.gravity = Vector3(0, 0.5, 0)
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.4
	pm.scale_min = 0.025
	pm.scale_max = 0.06
	pm.color = COLORS[item_type]
	particles.process_material = pm
	add_child(particles)


func _make_herb_mesh() -> SphereMesh:
	var sph := SphereMesh.new()
	sph.radius = 0.18
	sph.height = 0.35
	sph.radial_segments = 6
	sph.rings = 4
	return sph


func _make_crystal_mesh() -> PrismMesh:
	var prism := PrismMesh.new()
	prism.size = Vector3(0.2, 0.4, 0.2)
	return prism


func _make_mushroom_mesh() -> CylinderMesh:
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0
	cyl.bottom_radius = 0.22
	cyl.height = 0.35
	cyl.radial_segments = 8
	return cyl


func _process(delta: float) -> void:
	if _collected:
		return
	_bob_time += delta
	position.y = _base_y + sin(_bob_time * 2.0) * 0.08
	_mesh.rotation.y += delta * 1.5


func _on_body_entered(body: Node) -> void:
	if _collected:
		return
	if not body.is_in_group("player"):
		return
	_collected = true
	_apply_effect()
	_spawn_collect_effect()
	queue_free()


func _apply_effect() -> void:
	match item_type:
		Type.HEAL_HERB:
			GameManager.heal(value)
			AudioManager.play_sfx("collect_herb")
		Type.MANA_CRYSTAL:
			GameManager.restore_mana(value)
			AudioManager.play_sfx("collect_crystal")
		Type.MAGIC_MUSHROOM:
			GameManager.heal(value * 0.5)
			GameManager.restore_mana(value * 0.5)
			AudioManager.play_sfx("collect_herb")
		Type.XP_CRYSTAL:
			GameManager.gain_experience(int(value))
			AudioManager.play_sfx("collect_crystal")


func _spawn_collect_effect() -> void:
	var particles := GPUParticles3D.new()
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	particles.one_shot = true
	particles.explosiveness = 0.95
	particles.amount = 15
	particles.lifetime = 0.8
	particles.fixed_fps = 30
	var pm := ParticleProcessMaterial.new()
	pm.emission_sphere_radius = 0.1
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.gravity = Vector3(0, -2, 0)
	pm.initial_velocity_min = 1.0
	pm.initial_velocity_max = 3.0
	pm.scale_min = 0.04
	pm.scale_max = 0.1
	pm.color = COLORS[item_type]
	particles.process_material = pm
	get_tree().create_timer(1.5).timeout.connect(particles.queue_free)
