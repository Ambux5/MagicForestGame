extends Node3D
## Nature Shield – temporary protective field around the player.
## Reduces incoming damage by 30% for a duration.

@export var duration: float = 8.0
@export var damage_reduction: float = 0.30

var direction: Vector3 = Vector3.ZERO
var _spell_power_mult: float = 1.0
var _age: float = 0.0
var _shield_mesh: MeshInstance3D
var _shield_mat: StandardMaterial3D


func initialize(dir: Vector3, spell_power: float) -> void:
	direction = dir
	_spell_power_mult = spell_power


func _ready() -> void:
	GameManager.has_shield = true
	GameManager.shield_reduction = damage_reduction
	AudioManager.play_sfx("shield_activate")
	_build_shield_visual()


func _process(delta: float) -> void:
	_age += delta
	var frac := 1.0 - (_age / duration)
	if _shield_mat:
		_shield_mat.albedo_color.a = 0.28 * frac
		_shield_mat.emission_energy_multiplier = 1.5 * frac

	if _age >= duration:
		_deactivate()


func _build_shield_visual() -> void:
	_shield_mesh = MeshInstance3D.new()
	_shield_mesh.name = "ShieldMesh"
	var sph := SphereMesh.new()
	sph.radius = 0.9
	sph.height = 1.8
	sph.radial_segments = 12
	sph.rings = 6
	_shield_mesh.mesh = sph
	_shield_mat = StandardMaterial3D.new()
	_shield_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.28)
	_shield_mat.emission_enabled = true
	_shield_mat.emission = Color(0.1, 0.7, 0.2)
	_shield_mat.emission_energy_multiplier = 1.5
	_shield_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shield_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shield_mesh.set_surface_override_material(0, _shield_mat)
	add_child(_shield_mesh)

	# Orbit particles
	var particles := GPUParticles3D.new()
	particles.amount = 12
	particles.lifetime = 2.0
	particles.fixed_fps = 20
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.9
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 10.0
	pm.gravity = Vector3(0, 0, 0)
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.0
	pm.orbit_velocity_min = 1.0
	pm.orbit_velocity_max = 1.5
	pm.scale_min = 0.04
	pm.scale_max = 0.09
	pm.color = Color(0.3, 1.0, 0.4, 0.8)
	particles.process_material = pm
	add_child(particles)


func _deactivate() -> void:
	GameManager.has_shield = false
	queue_free()
