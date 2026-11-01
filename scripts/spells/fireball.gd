extends "res://scripts/spells/base_spell.gd"
## Fireball – slower orange projectile that explodes on impact for AoE damage.

func _ready() -> void:
	damage = 28.0
	speed = 14.0
	lifetime = 4.0
	spell_color = Color(1.0, 0.5, 0.1)
	impact_radius = 3.0  # AoE radius in metres
	add_to_group("spells")
	super()
	_build_visuals()


func _build_visuals() -> void:
	var orb := MeshInstance3D.new()
	orb.name = "FireOrb"
	var sph := SphereMesh.new()
	sph.radius = 0.18
	sph.height = 0.36
	sph.radial_segments = 7
	sph.rings = 4
	orb.mesh = sph
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.05, 0.95)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.25, 0.0)
	mat.emission_energy_multiplier = 3.0
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	orb.set_surface_override_material(0, mat)
	add_child(orb)

	# Fire trail
	var trail := GPUParticles3D.new()
	trail.amount = 16
	trail.lifetime = 0.5
	trail.fixed_fps = 30
	trail.local_coords = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.12
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.gravity = Vector3(0, 1.0, 0)
	pm.initial_velocity_min = 0.5
	pm.initial_velocity_max = 2.0
	pm.scale_min = 0.05
	pm.scale_max = 0.15
	pm.color = Color(1.0, 0.5, 0.1, 0.8)
	trail.process_material = pm
	add_child(trail)

	# Point light for fire glow
	var light := OmniLight3D.new()
	light.omni_range = 2.5
	light.light_color = Color(1.0, 0.5, 0.1)
	light.light_energy = 2.0
	add_child(light)

	var col := CollisionShape3D.new()
	var sph2 := SphereShape3D.new()
	sph2.radius = 0.22
	col.shape = sph2
	add_child(col)


func _spawn_impact_effect() -> void:
	# Bigger explosion effect
	var explosion := GPUParticles3D.new()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	explosion.emitting = true
	explosion.one_shot = true
	explosion.explosiveness = 0.98
	explosion.amount = 40
	explosion.lifetime = 1.0
	explosion.fixed_fps = 30
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.3
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.gravity = Vector3(0, -6.0, 0)
	pm.initial_velocity_min = 3.0
	pm.initial_velocity_max = 8.0
	pm.scale_min = 0.1
	pm.scale_max = 0.3
	pm.color = Color(1.0, 0.5, 0.1, 0.9)
	explosion.process_material = pm
	get_tree().create_timer(2.0).timeout.connect(explosion.queue_free)
	AudioManager.play_sfx("fireball_impact")
