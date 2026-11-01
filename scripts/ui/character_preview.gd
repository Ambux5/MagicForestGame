@tool
extends Node3D
## Character Preview – builds all three enemy meshes in a lit stage.
## Open scenes/preview/character_preview.tscn to inspect characters without
## running the game. Characters auto-rotate when the scene is played.

const TURNTABLE_SPEED := 0.55   # rad/s (runtime only)

var _turntables: Array[Node3D] = []


func _ready() -> void:
	if get_node_or_null("PreviewRoot") != null:
		return
	_build_scene()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for t in _turntables:
		t.rotate_y(TURNTABLE_SPEED * delta)


# ── Scene setup ───────────────────────────────────────────────────────────────

func _build_scene() -> void:
	var root := Node3D.new()
	root.name = "PreviewRoot"
	add_child(root)
	_setup_environment(root)
	_setup_lighting(root)
	_setup_camera(root)
	_setup_floor(root)
	_setup_characters(root)


func _setup_environment(parent: Node3D) -> void:
	var we  := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode        = Environment.BG_COLOR
	env.background_color       = Color(0.06, 0.05, 0.12)
	env.ambient_light_source   = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color    = Color(0.22, 0.22, 0.42)
	env.ambient_light_energy   = 0.55
	env.tonemap_mode            = Environment.TONE_MAPPER_ACES
	we.environment = env
	parent.add_child(we)


func _setup_lighting(parent: Node3D) -> void:
	var sun := DirectionalLight3D.new()
	sun.light_color         = Color(1.0, 0.93, 0.80)
	sun.light_energy        = 1.5
	sun.shadow_enabled      = true
	sun.rotation_degrees    = Vector3(-45, 30, 0)
	parent.add_child(sun)

	var fill := OmniLight3D.new()
	fill.position      = Vector3(0, 2.2, 3.5)
	fill.light_color   = Color(0.45, 0.55, 1.0)
	fill.light_energy  = 0.7
	fill.omni_range    = 14.0
	parent.add_child(fill)


func _setup_camera(parent: Node3D) -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.6, 6.2)
	cam.fov      = 64.0
	cam.current  = true
	cam.look_at(Vector3(0, 0.85, 0), Vector3.UP)
	parent.add_child(cam)


func _setup_floor(parent: Node3D) -> void:
	var mi    := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 9)
	mi.mesh    = plane
	var fmat   := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.14, 0.12, 0.09)
	fmat.roughness    = 0.92
	mi.set_surface_override_material(0, fmat)
	parent.add_child(mi)


func _setup_characters(parent: Node3D) -> void:
	var chars := [
		{"label": "Forest Goblin",    "x": -2.5, "fn": _build_goblin},
		{"label": "Forest Slime",     "x":  0.0, "fn": _build_slime},
		{"label": "Mushroom Monster", "x":  2.5, "fn": _build_mushroom},
	]
	for c in chars:
		var platform := _make_platform()
		platform.position = Vector3(c["x"], 0, 0)
		parent.add_child(platform)

		var turntable := Node3D.new()
		turntable.name = "Turntable"
		platform.add_child(turntable)
		_turntables.append(turntable)
		(c["fn"] as Callable).call(turntable)

		var lbl := Label3D.new()
		lbl.text        = c["label"]
		lbl.pixel_size  = 0.006
		lbl.font_size   = 26
		lbl.position    = Vector3(0, 2.05, 0)
		lbl.billboard   = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.modulate    = Color(1.0, 0.88, 0.30)
		lbl.outline_size = 6
		platform.add_child(lbl)

		var spot := SpotLight3D.new()
		spot.position          = Vector3(0, 3.8, 0)
		spot.rotation_degrees  = Vector3(-90, 0, 0)
		spot.light_color       = Color(1.0, 0.96, 0.88)
		spot.light_energy      = 2.2
		spot.spot_range        = 5.5
		spot.spot_angle        = 24.0
		spot.shadow_enabled    = true
		platform.add_child(spot)


func _make_platform() -> Node3D:
	var n   := Node3D.new()
	var mi  := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius    = 0.55
	cyl.bottom_radius = 0.63
	cyl.height        = 0.14
	cyl.radial_segments = 12
	mi.mesh     = cyl
	mi.position = Vector3(0, -0.07, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.30, 0.25, 0.18)
	mat.roughness    = 0.88
	mi.set_surface_override_material(0, mat)
	n.add_child(mi)
	return n


# ── Character mesh builders ───────────────────────────────────────────────────

func _build_goblin(p: Node3D) -> void:
	var SKIN      := Color(0.28, 0.50, 0.18)
	var SKIN_DARK := Color(0.21, 0.38, 0.13)
	var CLOTH     := Color(0.27, 0.19, 0.09)
	var LEATHER   := Color(0.40, 0.25, 0.08)
	var METAL     := Color(0.52, 0.46, 0.32)
	var WOOD      := Color(0.45, 0.32, 0.14)
	var FANG      := Color(0.92, 0.88, 0.72)
	var EYES      := Color(1.00, 0.82, 0.00)
	var EYE_EMIT  := Color(0.80, 0.55, 0.00)

	# Boots
	for side in [-1, 1]:
		var b := _mi(p, SphereMesh.new())
		(b.mesh as SphereMesh).radius = 0.10
		b.position = Vector3(side * 0.10, 0.06, 0.04)
		b.scale    = Vector3(1.0, 0.55, 1.55)
		b.set_surface_override_material(0, _pm(LEATHER, 0.90))
	# Legs
	for side in [-1, 1]:
		var l := _mi(p, CylinderMesh.new())
		var lc := l.mesh as CylinderMesh
		lc.top_radius = 0.085; lc.bottom_radius = 0.075; lc.height = 0.50; lc.radial_segments = 7
		l.position = Vector3(side * 0.10, 0.28, 0)
		l.set_surface_override_material(0, _pm(SKIN, 0.85))
	# Hips
	var hips := _mi(p, CylinderMesh.new())
	var hc := hips.mesh as CylinderMesh
	hc.top_radius = 0.16; hc.bottom_radius = 0.17; hc.height = 0.18; hc.radial_segments = 8
	hips.position = Vector3(0, 0.52, 0)
	hips.set_surface_override_material(0, _pm(CLOTH, 0.95))
	# Belt
	var belt := _mi(p, CylinderMesh.new())
	var bc := belt.mesh as CylinderMesh
	bc.top_radius = 0.165; bc.bottom_radius = 0.165; bc.height = 0.065; bc.radial_segments = 8
	belt.position = Vector3(0, 0.535, 0)
	belt.set_surface_override_material(0, _pm(LEATHER, 0.85))
	# Buckle
	var bk := _mi(p, BoxMesh.new())
	(bk.mesh as BoxMesh).size = Vector3(0.06, 0.05, 0.04)
	bk.position = Vector3(0, 0.535, -0.165)
	var mmat := _pm(METAL, 0.45); mmat.metallic = 0.5
	bk.set_surface_override_material(0, mmat)
	# Pouch
	var pouch := _mi(p, SphereMesh.new())
	(pouch.mesh as SphereMesh).radius = 0.055
	pouch.position = Vector3(0.13, 0.535, -0.14)
	pouch.scale    = Vector3(1.0, 0.85, 0.75)
	pouch.set_surface_override_material(0, _pm(LEATHER.darkened(0.2), 0.90))
	# Torso
	var torso := _mi(p, CylinderMesh.new())
	var tc := torso.mesh as CylinderMesh
	tc.top_radius = 0.19; tc.bottom_radius = 0.16; tc.height = 0.52; tc.radial_segments = 8
	torso.position   = Vector3(0, 0.74, 0)
	torso.rotation.x = deg_to_rad(5)
	torso.set_surface_override_material(0, _pm(CLOTH, 0.95))
	# Shoulders
	for side in [-1, 1]:
		var sh := _mi(p, SphereMesh.new())
		(sh.mesh as SphereMesh).radius = 0.11
		sh.position = Vector3(side * 0.23, 0.91, 0)
		sh.scale    = Vector3(1.15, 0.65, 0.80)
		sh.set_surface_override_material(0, _pm(CLOTH.darkened(0.15), 0.95))
	# Arms + fists
	for side in [-1, 1]:
		var arm := _mi(p, CylinderMesh.new())
		var ac := arm.mesh as CylinderMesh
		ac.top_radius = 0.068; ac.bottom_radius = 0.056; ac.height = 0.44; ac.radial_segments = 6
		arm.position   = Vector3(side * 0.28, 0.78, 0)
		arm.rotation.z = side * deg_to_rad(28)
		arm.set_surface_override_material(0, _pm(SKIN, 0.85))
		var fist := MeshInstance3D.new()
		var fsph := SphereMesh.new(); fsph.radius = 0.065; fsph.radial_segments = 5; fsph.rings = 3
		fist.mesh = fsph; fist.position = Vector3(0, -0.22, 0)
		fist.set_surface_override_material(0, _pm(SKIN.darkened(0.08), 0.85))
		arm.add_child(fist)
	# Head
	var head := _mi(p, SphereMesh.new())
	var hs := head.mesh as SphereMesh
	hs.radius = 0.22; hs.height = 0.30; hs.radial_segments = 8; hs.rings = 5
	head.position = Vector3(0, 1.14, 0)
	head.scale    = Vector3(1.0, 1.08, 0.92)
	head.set_surface_override_material(0, _pm(SKIN, 0.82))
	# Ears
	for side in [-1, 1]:
		var ear := _mi(p, CylinderMesh.new())
		var ec := ear.mesh as CylinderMesh
		ec.top_radius = 0.018; ec.bottom_radius = 0.055; ec.height = 0.22; ec.radial_segments = 5
		ear.position   = Vector3(side * 0.22, 1.20, 0.0)
		ear.rotation.z = side * deg_to_rad(75)
		ear.set_surface_override_material(0, _pm(SKIN, 0.82))
	# Brow
	var brow := _mi(p, BoxMesh.new())
	(brow.mesh as BoxMesh).size = Vector3(0.24, 0.045, 0.06)
	brow.position   = Vector3(0, 1.19, -0.18)
	brow.rotation.x = deg_to_rad(-8)
	brow.set_surface_override_material(0, _pm(SKIN_DARK, 0.88))
	# Eyes
	for side in [-1, 1]:
		var eye := _mi(p, SphereMesh.new())
		(eye.mesh as SphereMesh).radius = 0.050
		eye.position = Vector3(side * 0.09, 1.16, -0.152)
		var emat := StandardMaterial3D.new()
		emat.albedo_color = EYES; emat.emission_enabled = true
		emat.emission = EYE_EMIT; emat.emission_energy_multiplier = 1.5
		eye.set_surface_override_material(0, emat)
	# Nose
	var nose := _mi(p, SphereMesh.new())
	(nose.mesh as SphereMesh).radius = 0.048
	nose.position = Vector3(0, 1.09, -0.215)
	nose.scale    = Vector3(1.3, 0.9, 1.15)
	nose.set_surface_override_material(0, _pm(SKIN_DARK, 0.88))
	# Fangs
	for side in [-1, 1]:
		var fang := _mi(p, CylinderMesh.new())
		var fc := fang.mesh as CylinderMesh
		fc.top_radius = 0.005; fc.bottom_radius = 0.016; fc.height = 0.075; fc.radial_segments = 4
		fang.position   = Vector3(side * 0.042, 1.00, -0.20)
		fang.rotation.x = deg_to_rad(8); fang.rotation.z = side * deg_to_rad(6)
		fang.set_surface_override_material(0, _pm(FANG, 0.50))
	# Warts
	for wp in [Vector3(0.09, 1.22, -0.15), Vector3(-0.12, 1.20, -0.14), Vector3(0.02, 1.25, -0.12)]:
		var w := _mi(p, SphereMesh.new())
		(w.mesh as SphereMesh).radius = 0.018
		w.position = wp
		w.set_surface_override_material(0, _pm(SKIN_DARK, 0.92))
	# Club
	var club := Node3D.new()
	club.position   = Vector3(0.38, 0.58, 0)
	club.rotation.z = deg_to_rad(18)
	p.add_child(club)
	var hnd := _mi(club, CylinderMesh.new())
	var hcyl := hnd.mesh as CylinderMesh
	hcyl.top_radius = 0.030; hcyl.bottom_radius = 0.025; hcyl.height = 0.72; hcyl.radial_segments = 6
	hnd.set_surface_override_material(0, _pm(WOOD, 0.92))
	var chd := _mi(club, CylinderMesh.new())
	var ccyl := chd.mesh as CylinderMesh
	ccyl.top_radius = 0.055; ccyl.bottom_radius = 0.115; ccyl.height = 0.20; ccyl.radial_segments = 7
	chd.position.y = 0.46
	chd.set_surface_override_material(0, _pm(WOOD.darkened(0.15), 0.92))
	var rng := _mi(club, CylinderMesh.new())
	var rcyl := rng.mesh as CylinderMesh
	rcyl.top_radius = 0.052; rcyl.bottom_radius = 0.052; rcyl.height = 0.032; rcyl.radial_segments = 7
	rng.position.y = 0.36
	var rmat := _pm(METAL, 0.45); rmat.metallic = 0.55
	rng.set_surface_override_material(0, rmat)
	var spk := _mi(club, CylinderMesh.new())
	var scyl := spk.mesh as CylinderMesh
	scyl.top_radius = 0.005; scyl.bottom_radius = 0.040; scyl.height = 0.11; scyl.radial_segments = 5
	spk.position.y = 0.615
	spk.set_surface_override_material(0, rmat)


func _build_slime(p: Node3D) -> void:
	var BODY   := Color(0.15, 0.72, 0.25, 0.92)
	var EYES   := Color(0.9, 0.95, 0.9)
	var EMIT   := Color(0.05, 0.5, 0.1)

	var body := _mi(p, SphereMesh.new())
	var bs := body.mesh as SphereMesh
	bs.radius = 0.38; bs.height = 0.55; bs.radial_segments = 8; bs.rings = 4
	body.position = Vector3(0, 0.30, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = BODY
	bmat.emission_enabled = true; bmat.emission = EMIT
	bmat.emission_energy_multiplier = 0.5
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.roughness = 0.3
	body.set_surface_override_material(0, bmat)

	for side in [-1, 1]:
		var eye := _mi(p, SphereMesh.new())
		var es := eye.mesh as SphereMesh
		es.radius = 0.065; es.radial_segments = 6; es.rings = 3
		eye.position = Vector3(side * 0.15, 0.45, -0.30)
		eye.set_surface_override_material(0, _pm(EYES, 0.4))


func _build_mushroom(p: Node3D) -> void:
	var CAP    := Color(0.78, 0.22, 0.22)
	var SPOTS  := Color(0.95, 0.92, 0.85)
	var STEM   := Color(0.90, 0.85, 0.72)
	var EYES   := Color(0.15, 0.08, 0.05)
	var EMIT   := Color(0.6, 0.1, 0.1)

	# Legs
	for side in [-1, 1]:
		var leg := _mi(p, CylinderMesh.new())
		var lc := leg.mesh as CylinderMesh
		lc.top_radius = 0.075; lc.bottom_radius = 0.075; lc.height = 0.35; lc.radial_segments = 6
		leg.position = Vector3(side * 0.15, 0.175, 0)
		leg.set_surface_override_material(0, _pm(STEM, 0.90))
	# Stem
	var stem := _mi(p, CylinderMesh.new())
	var sc := stem.mesh as CylinderMesh
	sc.top_radius = 0.24; sc.bottom_radius = 0.30; sc.height = 0.80; sc.radial_segments = 8
	stem.position = Vector3(0, 0.40, 0)
	stem.set_surface_override_material(0, _pm(STEM, 0.90))
	# Cap
	var cap := _mi(p, SphereMesh.new())
	var cs := cap.mesh as SphereMesh
	cs.radius = 0.52; cs.height = 0.62; cs.radial_segments = 10; cs.rings = 5
	cap.position = Vector3(0, 1.00, 0)
	cap.scale    = Vector3(1.0, 0.75, 1.0)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = CAP
	cmat.emission_enabled = true; cmat.emission = EMIT
	cmat.emission_energy_multiplier = 0.4
	cap.set_surface_override_material(0, cmat)
	# Cap spots
	for i in 4:
		var angle := i * TAU / 4.0 + 0.4
		var spot := _mi(p, SphereMesh.new())
		var ss := spot.mesh as SphereMesh
		ss.radius = 0.08; ss.radial_segments = 5; ss.rings = 3
		spot.position = Vector3(cos(angle) * 0.35, 1.1 + sin(i * 0.7) * 0.05, sin(angle) * 0.35)
		spot.set_surface_override_material(0, _pm(SPOTS, 0.75))
	# Eyes
	for side in [-1, 1]:
		var eye := _mi(p, SphereMesh.new())
		(eye.mesh as SphereMesh).radius = 0.06
		eye.position = Vector3(side * 0.17, 0.75, -0.22)
		eye.set_surface_override_material(0, _pm(EYES, 0.8))


# ── Helpers ───────────────────────────────────────────────────────────────────

func _mi(parent: Node3D, mesh: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	parent.add_child(mi)
	return mi


static func _pm(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness    = roughness
	return m
