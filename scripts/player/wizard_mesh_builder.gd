extends Node3D
## Procedurally builds the wizard character mesh at runtime.
## Attaches to the MeshRoot node inside player.tscn.
## Creates a visually distinct low-poly wizard using Godot primitives.

@onready var player: CharacterBody3D = get_parent().get_parent()

# Color palette
const COLOR_ROBE := Color(0.18, 0.12, 0.45)       # deep purple robe
const COLOR_ROBE_TRIM := Color(0.45, 0.30, 0.08)   # gold trim
const COLOR_SKIN := Color(0.95, 0.82, 0.65)        # warm skin
const COLOR_HAT := Color(0.12, 0.08, 0.35)         # dark purple hat
const COLOR_STAFF := Color(0.40, 0.28, 0.12)       # wood brown
const COLOR_CRYSTAL := Color(0.3, 0.9, 0.4, 0.85) # green glowing crystal
const EMISSIVE_CRYSTAL := Color(0.1, 0.8, 0.2)


func _ready() -> void:
	_build_wizard()
	_build_staff()
	var wizard_ap := _build_animations()
	if player and player.has_method("register_material"):
		for child in get_children():
			if child is MeshInstance3D:
				var mat: Material = child.get_surface_override_material(0)
				if mat is StandardMaterial3D:
					player.register_material(mat as StandardMaterial3D)
	# Register the wizard AnimationPlayer with the player controller
	if player and player.has_method("set_wizard_animation_player"):
		player.set_wizard_animation_player(wizard_ap)


func _build_wizard() -> void:
	# ── Torso / Robe ──────────────────────────────────────────────────────────
	var torso := _make_mesh(CylinderMesh.new(), "Torso", Vector3(0, 0.75, 0))
	var cyl: CylinderMesh = torso.mesh
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.32
	cyl.height = 0.9
	_apply_material(torso, COLOR_ROBE)

	# ── Hips / Robe skirt ─────────────────────────────────────────────────────
	var skirt := _make_mesh(CylinderMesh.new(), "Skirt", Vector3(0, 0.22, 0))
	var scyl: CylinderMesh = skirt.mesh
	scyl.top_radius = 0.32
	scyl.bottom_radius = 0.38
	scyl.height = 0.45
	_apply_material(skirt, COLOR_ROBE)

	# ── Head ─────────────────────────────────────────────────────────────────
	var head := _make_mesh(SphereMesh.new(), "Head", Vector3(0, 1.55, 0))
	var hsph: SphereMesh = head.mesh
	hsph.radius = 0.2
	hsph.height = 0.38
	_apply_material(head, COLOR_SKIN)

	# ── Wizard Hat ────────────────────────────────────────────────────────────
	var hat_brim := _make_mesh(CylinderMesh.new(), "HatBrim", Vector3(0, 1.72, 0))
	var hbcyl: CylinderMesh = hat_brim.mesh
	hbcyl.top_radius = 0.22
	hbcyl.bottom_radius = 0.30
	hbcyl.height = 0.06
	_apply_material(hat_brim, COLOR_HAT)

	var hat_cone := _make_mesh(CylinderMesh.new(), "HatCone", Vector3(0, 1.95, 0))
	var hccyl: CylinderMesh = hat_cone.mesh
	hccyl.top_radius = 0.04
	hccyl.bottom_radius = 0.22
	hccyl.height = 0.50
	_apply_material(hat_cone, COLOR_HAT)

	# ── Arms ──────────────────────────────────────────────────────────────────
	for side in [-1, 1]:
		var arm := _make_mesh(CylinderMesh.new(), "Arm_" + ("L" if side == -1 else "R"),
				Vector3(side * 0.35, 1.05, 0))
		arm.rotation.z = side * deg_to_rad(20)
		var acyl: CylinderMesh = arm.mesh
		acyl.top_radius = 0.07
		acyl.bottom_radius = 0.07
		acyl.height = 0.55
		_apply_material(arm, COLOR_ROBE)

	# ── Robe trim strip ───────────────────────────────────────────────────────
	var trim := _make_mesh(CylinderMesh.new(), "Trim", Vector3(0, 0.75, 0))
	var tcyl: CylinderMesh = trim.mesh
	tcyl.top_radius = 0.225
	tcyl.bottom_radius = 0.225
	tcyl.height = 0.05
	_apply_material(trim, COLOR_ROBE_TRIM)

	# ── Eyes ─────────────────────────────────────────────────────────────────
	for side in [-1, 1]:
		var eye := _make_mesh(SphereMesh.new(), "Eye_" + ("L" if side == -1 else "R"),
				Vector3(side * 0.078, 1.58, -0.178))
		var esph: SphereMesh = eye.mesh
		esph.radius = 0.028; esph.height = 0.056
		var emat := StandardMaterial3D.new()
		emat.albedo_color = Color(0.10, 0.07, 0.04)
		emat.roughness = 0.4
		eye.set_surface_override_material(0, emat)

	# ── Eyebrows ─────────────────────────────────────────────────────────────
	for side in [-1, 1]:
		var brow := _make_mesh(CylinderMesh.new(), "Brow_" + ("L" if side == -1 else "R"),
				Vector3(side * 0.078, 1.624, -0.186))
		var bcyl: CylinderMesh = brow.mesh
		bcyl.top_radius = 0.006; bcyl.bottom_radius = 0.006
		bcyl.height = 0.075; bcyl.radial_segments = 5
		brow.rotation.z = side * deg_to_rad(25)
		brow.rotation.x = deg_to_rad(-6)
		var bmat := StandardMaterial3D.new()
		bmat.albedo_color = Color(0.58, 0.43, 0.18)
		brow.set_surface_override_material(0, bmat)

	# ── Mustache ─────────────────────────────────────────────────────────────
	var mustache := _make_mesh(CylinderMesh.new(), "Mustache",
			Vector3(0, 1.508, -0.196))
	var mcyl: CylinderMesh = mustache.mesh
	mcyl.top_radius = 0.007; mcyl.bottom_radius = 0.007
	mcyl.height = 0.115; mcyl.radial_segments = 5
	mustache.rotation.x = deg_to_rad(88)
	var mmat := StandardMaterial3D.new()
	mmat.albedo_color = Color(0.90, 0.88, 0.78)
	mustache.set_surface_override_material(0, mmat)

	# ── Beard ────────────────────────────────────────────────────────────────
	var beard := _make_mesh(CylinderMesh.new(), "Beard", Vector3(0, 1.31, -0.152))
	var beardcyl: CylinderMesh = beard.mesh
	beardcyl.top_radius = 0.068; beardcyl.bottom_radius = 0.018
	beardcyl.height = 0.26; beardcyl.radial_segments = 6
	beard.rotation.x = deg_to_rad(-10)
	var beardmat := StandardMaterial3D.new()
	beardmat.albedo_color = Color(0.90, 0.88, 0.78)
	beard.set_surface_override_material(0, beardmat)

	for side in [-1, 1]:
		var lock := _make_mesh(CylinderMesh.new(), "BeardLock_" + ("L" if side == -1 else "R"),
				Vector3(side * 0.068, 1.27, -0.10))
		var lockcyl: CylinderMesh = lock.mesh
		lockcyl.top_radius = 0.030; lockcyl.bottom_radius = 0.005
		lockcyl.height = 0.16; lockcyl.radial_segments = 5
		lock.rotation.z = side * deg_to_rad(18)
		lock.rotation.x = deg_to_rad(-8)
		lock.set_surface_override_material(0, beardmat)

	# ── Hands ────────────────────────────────────────────────────────────────
	for side in [-1, 1]:
		var ang: float = side * deg_to_rad(20)
		var arm_down := Vector3(sin(ang), -cos(ang), 0)
		var hand_pos: Vector3 = Vector3(float(side) * 0.35, 1.05, 0) + arm_down * 0.275
		var hand := _make_mesh(SphereMesh.new(), "Hand_" + ("L" if side == -1 else "R"), hand_pos)
		var hdsph: SphereMesh = hand.mesh
		hdsph.radius = 0.065; hdsph.height = 0.11
		_apply_material(hand, COLOR_SKIN)

	# ── Hat star (glowing) ────────────────────────────────────────────────────
	var star := _make_mesh(SphereMesh.new(), "HatStar", Vector3(0, 2.235, 0))
	var ssph: SphereMesh = star.mesh
	ssph.radius = 0.050; ssph.height = 0.10
	var starmat := StandardMaterial3D.new()
	starmat.albedo_color = Color(1.0, 0.92, 0.30)
	starmat.emission_enabled = true
	starmat.emission = Color(0.80, 0.65, 0.05)
	starmat.emission_energy_multiplier = 2.2
	star.set_surface_override_material(0, starmat)


func _build_staff() -> void:
	# ── Staff handle ──────────────────────────────────────────────────────────
	var handle := _make_mesh(CylinderMesh.new(), "StaffHandle", Vector3(0.50, 0.80, 0))
	var scyl: CylinderMesh = handle.mesh
	scyl.top_radius = 0.035
	scyl.bottom_radius = 0.04
	scyl.height = 1.6
	_apply_material(handle, COLOR_STAFF)

	# ── Staff top knob ────────────────────────────────────────────────────────
	var knob := _make_mesh(SphereMesh.new(), "StaffKnob", Vector3(0.50, 1.64, 0))
	var ksph: SphereMesh = knob.mesh
	ksph.radius = 0.065
	ksph.height = 0.13
	_apply_material(knob, COLOR_STAFF)

	# ── Magic crystal orb ─────────────────────────────────────────────────────
	var orb := _make_mesh(SphereMesh.new(), "StaffOrb", Vector3(0.50, 1.72, 0))
	var osph: SphereMesh = orb.mesh
	osph.radius = 0.09
	osph.height = 0.18
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_CRYSTAL
	mat.emission_enabled = true
	mat.emission = EMISSIVE_CRYSTAL
	mat.emission_energy_multiplier = 1.8
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	orb.set_surface_override_material(0, mat)

	# Small sparkle particles on the orb
	var particles := GPUParticles3D.new()
	particles.name = "OrbParticles"
	particles.transform = Transform3D(Basis.IDENTITY, Vector3(0.50, 1.72, 0))
	particles.amount = 8
	particles.lifetime = 1.2
	particles.fixed_fps = 20
	var pmaterial := ParticleProcessMaterial.new()
	pmaterial.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pmaterial.emission_sphere_radius = 0.1
	pmaterial.direction = Vector3(0, 1, 0)
	pmaterial.spread = 90.0
	pmaterial.gravity = Vector3(0, 0.5, 0)
	pmaterial.initial_velocity_min = 0.05
	pmaterial.initial_velocity_max = 0.15
	pmaterial.scale_min = 0.015
	pmaterial.scale_max = 0.04
	pmaterial.color = EMISSIVE_CRYSTAL
	particles.process_material = pmaterial
	add_child(particles)


func _build_animations() -> AnimationPlayer:
	var ap := AnimationPlayer.new()
	ap.name = "WizardAnimations"
	add_child(ap)

	var lib := AnimationLibrary.new()

	# ── Idle ─────────────────────────────────────────────────────────────────
	var idle := Animation.new()
	idle.length = 2.0
	idle.loop_mode = Animation.LOOP_LINEAR
	var torso_track := idle.add_track(Animation.TYPE_POSITION_3D)
	idle.track_set_path(torso_track, ".:position")
	idle.position_track_insert_key(torso_track, 0.0, Vector3.ZERO)
	idle.position_track_insert_key(torso_track, 1.0, Vector3(0, 0.015, 0))
	idle.position_track_insert_key(torso_track, 2.0, Vector3.ZERO)
	lib.add_animation("idle", idle)

	# ── Walk ─────────────────────────────────────────────────────────────────
	var walk := Animation.new()
	walk.length = 0.8
	walk.loop_mode = Animation.LOOP_LINEAR
	var wt := walk.add_track(Animation.TYPE_POSITION_3D)
	walk.track_set_path(wt, ".:position")
	walk.position_track_insert_key(wt, 0.0, Vector3.ZERO)
	walk.position_track_insert_key(wt, 0.2, Vector3(0, 0.04, 0))
	walk.position_track_insert_key(wt, 0.4, Vector3.ZERO)
	walk.position_track_insert_key(wt, 0.6, Vector3(0, 0.04, 0))
	walk.position_track_insert_key(wt, 0.8, Vector3.ZERO)
	lib.add_animation("walk", walk)

	# ── Run ──────────────────────────────────────────────────────────────────
	var run := Animation.new()
	run.length = 0.5
	run.loop_mode = Animation.LOOP_LINEAR
	var rt := run.add_track(Animation.TYPE_POSITION_3D)
	run.track_set_path(rt, ".:position")
	run.position_track_insert_key(rt, 0.0, Vector3.ZERO)
	run.position_track_insert_key(rt, 0.125, Vector3(0, 0.07, 0))
	run.position_track_insert_key(rt, 0.25, Vector3.ZERO)
	run.position_track_insert_key(rt, 0.375, Vector3(0, 0.07, 0))
	run.position_track_insert_key(rt, 0.5, Vector3.ZERO)
	lib.add_animation("run", run)

	# ── Jump / Fall / Cast / Hurt / Death (single-frame stubs) ───────────────
	for anim_name in ["jump", "fall", "cast", "hurt", "death"]:
		var a := Animation.new()
		a.length = 0.4 if anim_name != "death" else 1.2
		a.loop_mode = Animation.LOOP_NONE
		lib.add_animation(anim_name, a)

	ap.add_animation_library("", lib)
	ap.play("idle")
	return ap


# ── Helpers ────────────────────────────────────────────────────────────────────

func _make_mesh(mesh_res: Mesh, node_name: String, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh_res
	mi.position = pos
	add_child(mi)
	return mi


func _apply_material(mi: MeshInstance3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.85
	mat.metallic = 0.0
	mi.set_surface_override_material(0, mat)
