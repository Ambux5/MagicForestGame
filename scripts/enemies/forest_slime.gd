extends "res://scripts/enemies/base_enemy.gd"
## Forest Slime – small bouncing green creature.

const COLOR_BODY := Color(0.15, 0.72, 0.25, 0.92)
const COLOR_EYES := Color(0.9, 0.95, 0.9)
const COLOR_EMISSIVE := Color(0.05, 0.5, 0.1)

var _body_mesh: MeshInstance3D
var _body_mat: StandardMaterial3D
var _bounce_t: float = 0.0


func _ready() -> void:
	max_health = 30.0
	move_speed = 3.2
	detect_radius = 8.0
	attack_range = 1.5
	attack_damage = 6.0
	attack_cooldown = 1.8
	xp_reward = 15
	enemy_name = "Forest Slime"
	super()
	_build_mesh()
	_build_animations()


func _build_mesh() -> void:
	# Main slime body – squished sphere
	_body_mesh = MeshInstance3D.new()
	_body_mesh.name = "Body"
	var sph := SphereMesh.new()
	sph.radius = 0.38
	sph.height = 0.55
	sph.radial_segments = 8
	sph.rings = 4
	_body_mesh.mesh = sph
	_body_mesh.position = Vector3(0, 0.3, 0)
	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = COLOR_BODY
	_body_mat.emission_enabled = true
	_body_mat.emission = COLOR_EMISSIVE
	_body_mat.emission_energy_multiplier = 0.5
	_body_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_body_mat.roughness = 0.3
	_body_mesh.set_surface_override_material(0, _body_mat)
	add_child(_body_mesh)

	# Eyes
	for side in [-1, 1]:
		var eye := MeshInstance3D.new()
		eye.name = "Eye_" + ("L" if side == -1 else "R")
		var esph := SphereMesh.new()
		esph.radius = 0.065
		esph.height = 0.13
		esph.radial_segments = 6
		esph.rings = 3
		eye.mesh = esph
		eye.position = Vector3(side * 0.15, 0.45, -0.3)
		var emat := StandardMaterial3D.new()
		emat.albedo_color = COLOR_EYES
		eye.set_surface_override_material(0, emat)
		add_child(eye)

	# Bounce particles
	var particles := GPUParticles3D.new()
	particles.amount = 6
	particles.lifetime = 0.6
	particles.fixed_fps = 20
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.2
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 60.0
	pm.gravity = Vector3(0, -3.0, 0)
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.6
	pm.scale_min = 0.04
	pm.scale_max = 0.08
	pm.color = Color(0.3, 0.9, 0.4, 0.7)
	particles.process_material = pm
	particles.position = Vector3(0, 0.1, 0)
	add_child(particles)


func _build_animations() -> void:
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	add_child(ap)

	var lib := AnimationLibrary.new()
	var idle := _make_bounce_anim(0.05, 1.2)
	lib.add_animation("idle", idle)
	var walk := _make_bounce_anim(0.12, 0.6)
	lib.add_animation("walk", walk)
	var run := _make_bounce_anim(0.18, 0.35)
	lib.add_animation("run", run)
	for a in ["attack", "hurt", "death"]:
		var an := Animation.new()
		an.length = 0.5
		lib.add_animation(a, an)
	ap.add_animation_library("", lib)
	ap.play("idle")


func _make_bounce_anim(height: float, period: float) -> Animation:
	var a := Animation.new()
	a.length = period
	a.loop_mode = Animation.LOOP_LINEAR
	var t := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(t, "Body:position")
	a.position_track_insert_key(t, 0.0, Vector3(0, 0.3, 0))
	a.position_track_insert_key(t, period * 0.5, Vector3(0, 0.3 + height, 0))
	a.position_track_insert_key(t, period, Vector3(0, 0.3, 0))
	return a


func _on_hit_flash() -> void:
	_body_mat.emission = Color(1, 0.3, 0.3)
	get_tree().create_timer(0.2).timeout.connect(func(): _body_mat.emission = COLOR_EMISSIVE)
