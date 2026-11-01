extends "res://scripts/spells/base_spell.gd"
## Nature Bolt – fast green projectile that deals single-target damage.

func _ready() -> void:
	damage = 18.0
	speed = 22.0
	lifetime = 3.5
	spell_color = Color(0.2, 0.9, 0.3)
	impact_radius = 0.0
	add_to_group("spells")
	super()
	_build_visuals()


func _build_visuals() -> void:
	var orb := MeshInstance3D.new()
	orb.name = "OrbMesh"
	var sph := SphereMesh.new()
	sph.radius = 0.12
	sph.height = 0.22
	sph.radial_segments = 6
	sph.rings = 3
	orb.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.95, 0.4, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.8, 0.15)
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	orb.set_surface_override_material(0, mat)
	add_child(orb)

	var trail := GPUParticles3D.new()
	trail.name = "Trail"
	trail.amount = 12
	trail.lifetime = 0.4
	trail.fixed_fps = 30
	trail.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.08
	pm.direction = Vector3(0, 0, 1)
	pm.spread = 30.0
	pm.gravity = Vector3(0, 0.2, 0)
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 1.5
	pm.scale_min = 0.04
	pm.scale_max = 0.1
	pm.color = Color(0.2, 0.9, 0.3, 0.7)
	trail.process_material = pm
	add_child(trail)

	# Collision
	var col := CollisionShape3D.new()
	var sph2 := SphereShape3D.new()
	sph2.radius = 0.15
	col.shape = sph2
	add_child(col)
