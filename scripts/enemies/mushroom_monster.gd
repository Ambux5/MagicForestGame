extends "res://scripts/enemies/base_enemy.gd"
## Mushroom Monster – walking magical mushroom creature.

const COLOR_CAP := Color(0.78, 0.22, 0.22)
const COLOR_CAP_SPOTS := Color(0.95, 0.92, 0.85)
const COLOR_STEM := Color(0.90, 0.85, 0.72)
const COLOR_EYES := Color(0.15, 0.08, 0.05)
const EMISSIVE_GLOW := Color(0.6, 0.1, 0.1)

var _cap_mat: StandardMaterial3D


func _ready() -> void:
	max_health = 55.0
	move_speed = 2.0
	detect_radius = 9.0
	attack_range = 2.0
	attack_damage = 12.0
	attack_cooldown = 2.2
	xp_reward = 30
	enemy_name = "Mushroom Monster"
	super()
	_build_mesh()
	_build_animations()


func _build_mesh() -> void:
	# ── Stem / Body ──────────────────────────────────────────────────────────
	var stem := MeshInstance3D.new()
	stem.name = "Stem"
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.24
	scyl.bottom_radius = 0.30
	scyl.height = 0.8
	scyl.radial_segments = 8
	stem.mesh = scyl
	stem.position = Vector3(0, 0.4, 0)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = COLOR_STEM
	smat.roughness = 0.9
	stem.set_surface_override_material(0, smat)
	add_child(stem)

	# ── Cap ───────────────────────────────────────────────────────────────────
	var cap := MeshInstance3D.new()
	cap.name = "Cap"
	var csph := SphereMesh.new()
	csph.radius = 0.52
	csph.height = 0.62
	csph.radial_segments = 10
	csph.rings = 5
	cap.mesh = csph
	cap.position = Vector3(0, 1.0, 0)
	cap.scale = Vector3(1.0, 0.75, 1.0)
	_cap_mat = StandardMaterial3D.new()
	_cap_mat.albedo_color = COLOR_CAP
	_cap_mat.emission_enabled = true
	_cap_mat.emission = EMISSIVE_GLOW
	_cap_mat.emission_energy_multiplier = 0.4
	cap.set_surface_override_material(0, _cap_mat)
	add_child(cap)

	# Cap spots
	for i in 4:
		var spot := MeshInstance3D.new()
		spot.name = "Spot_" + str(i)
		var ssph := SphereMesh.new()
		ssph.radius = 0.08
		ssph.height = 0.16
		ssph.radial_segments = 5
		ssph.rings = 3
		spot.mesh = ssph
		var angle := i * TAU / 4.0 + 0.4
		spot.position = Vector3(cos(angle) * 0.35, 1.1 + sin(i * 0.7) * 0.05, sin(angle) * 0.35)
		var spmat := StandardMaterial3D.new()
		spmat.albedo_color = COLOR_CAP_SPOTS
		spot.set_surface_override_material(0, spmat)
		add_child(spot)

	# ── Eyes ─────────────────────────────────────────────────────────────────
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.name = "Eye"
		var esph := SphereMesh.new()
		esph.radius = 0.06
		esph.radial_segments = 5
		esph.rings = 3
		eye.mesh = esph
		eye.position = Vector3(side * 0.17, 0.75, -0.22)
		var emat := StandardMaterial3D.new()
		emat.albedo_color = COLOR_EYES
		eye.set_surface_override_material(0, emat)
		add_child(eye)

	# ── Legs ──────────────────────────────────────────────────────────────────
	for side in [-1, 1]:
		var leg := MeshInstance3D.new()
		leg.name = "Leg"
		var lcyl := CylinderMesh.new()
		lcyl.top_radius = 0.075
		lcyl.bottom_radius = 0.075
		lcyl.height = 0.35
		lcyl.radial_segments = 6
		leg.mesh = lcyl
		leg.position = Vector3(side * 0.15, 0.17, 0)
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = COLOR_STEM
		leg.set_surface_override_material(0, lmat)
		add_child(leg)

	# Spore particles
	var particles := GPUParticles3D.new()
	particles.amount = 8
	particles.lifetime = 1.5
	particles.fixed_fps = 20
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.5
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.gravity = Vector3(0, 0.3, 0)
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.3
	pm.scale_min = 0.02
	pm.scale_max = 0.05
	pm.color = Color(1.0, 0.6, 0.2, 0.5)
	particles.process_material = pm
	particles.position = Vector3(0, 1.0, 0)
	add_child(particles)


func _build_animations() -> void:
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	add_child(ap)

	var lib := AnimationLibrary.new()
	for anim_name in ["idle", "walk", "run", "attack", "hurt", "death"]:
		var a := Animation.new()
		a.length = 0.8
		if anim_name in ["idle", "walk", "run"]:
			a.loop_mode = Animation.LOOP_LINEAR
		# Gentle sway on cap
		var t := a.add_track(Animation.TYPE_ROTATION_3D)
		a.track_set_path(t, "Cap:rotation")
		var speed := 1.0 if anim_name == "idle" else (2.0 if anim_name == "walk" else 3.0)
		var amplitude := 0.05 if anim_name == "idle" else (0.1 if anim_name == "walk" else 0.15)
		a.length = 1.0 / speed
		a.rotation_track_insert_key(t, 0.0, Quaternion.IDENTITY)
		a.rotation_track_insert_key(t, a.length * 0.5, Quaternion.from_euler(Vector3(amplitude, 0, 0)))
		a.rotation_track_insert_key(t, a.length, Quaternion.IDENTITY)
		lib.add_animation(anim_name, a)
	ap.add_animation_library("", lib)
	ap.play("idle")


func _on_hit_flash() -> void:
	_cap_mat.albedo_color = Color(1, 0.9, 0.9)
	get_tree().create_timer(0.2).timeout.connect(func(): _cap_mat.albedo_color = COLOR_CAP)
