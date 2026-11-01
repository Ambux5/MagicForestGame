extends "res://scripts/enemies/base_enemy.gd"
## Forest Goblin – agile, cunning forest predator. Enhanced procedural mesh.

# ── Palette ────────────────────────────────────────────────────────────────────
const COLOR_SKIN      := Color(0.28, 0.50, 0.18)   # mossy green
const COLOR_SKIN_DARK := Color(0.21, 0.38, 0.13)   # warts / nose / brow
const COLOR_CLOTH     := Color(0.27, 0.19, 0.09)   # ragged cloth
const COLOR_LEATHER   := Color(0.40, 0.25, 0.08)   # belt / boots
const COLOR_METAL     := Color(0.52, 0.46, 0.32)   # ring, buckle
const COLOR_WOOD      := Color(0.45, 0.32, 0.14)   # club handle
const COLOR_FANG      := Color(0.92, 0.88, 0.72)   # ivory tusks
const COLOR_EYES      := Color(1.00, 0.82, 0.00)   # bright yellow
const EMISSIVE_EYES   := Color(0.80, 0.55, 0.00)   # orange glow

const _ARM_REST_Z := 28.0   # degrees – arm spread; referenced in animation keys

var _body_mat: StandardMaterial3D
var _eye_mat: StandardMaterial3D
var _all_skin_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	max_health      = 50.0
	move_speed      = 4.2
	detect_radius   = 12.0
	attack_range    = 1.8
	attack_damage   = 12.0
	attack_cooldown = 1.4
	xp_reward       = 30
	enemy_name      = "Forest Goblin"
	super()
	# If a .glb model is already a child (GoblinModel), use its AnimationPlayer.
	# Otherwise fall back to building the procedural mesh.
	var ap := _find_model_anim_player()
	if ap:
		_animation_player_ref = ap
	else:
		_build_mesh()
		_build_animations()


# Searches direct Node3D children (the glb root) for an AnimationPlayer
func _find_model_anim_player() -> AnimationPlayer:
	for child in get_children():
		if child is Node3D and not (child is CollisionShape3D):
			var found := _search_anim_player(child)
			if found:
				return found
	return null


func _search_anim_player(node: Node) -> AnimationPlayer:
	for child in node.get_children():
		if child is AnimationPlayer:
			return child as AnimationPlayer
		var found := _search_anim_player(child)
		if found:
			return found
	return null


func _build_mesh() -> void:
	_build_lower_body()
	_build_torso()
	_build_head()
	_build_weapon()


# ── Lower body ────────────────────────────────────────────────────────────────

func _build_lower_body() -> void:
	for side in [-1, 1]:
		var boot := _make_mi("Boot_" + _lr(side))
		var bsph := SphereMesh.new()
		bsph.radius = 0.10; bsph.radial_segments = 6; bsph.rings = 3
		boot.mesh = bsph
		boot.position = Vector3(side * 0.10, 0.06, 0.04)
		boot.scale    = Vector3(1.0, 0.55, 1.55)
		boot.set_surface_override_material(0, _mat(COLOR_LEATHER, 0.90))

	for side in [-1, 1]:
		var leg := _make_mi("Leg_" + _lr(side))
		var lc := CylinderMesh.new()
		lc.top_radius = 0.085; lc.bottom_radius = 0.075
		lc.height = 0.50;      lc.radial_segments = 7
		leg.mesh = lc
		leg.position = Vector3(side * 0.10, 0.28, 0)
		var lmat := _mat(COLOR_SKIN, 0.85)
		leg.set_surface_override_material(0, lmat)
		_all_skin_mats.append(lmat)

	var hips := _make_mi("Hips")
	var hc := CylinderMesh.new()
	hc.top_radius = 0.16; hc.bottom_radius = 0.17
	hc.height = 0.18;     hc.radial_segments = 8
	hips.mesh = hc
	hips.position = Vector3(0, 0.52, 0)
	_body_mat = _mat(COLOR_CLOTH, 0.95)
	hips.set_surface_override_material(0, _body_mat)

	var belt := _make_mi("Belt")
	var bc := CylinderMesh.new()
	bc.top_radius = 0.165; bc.bottom_radius = 0.165
	bc.height = 0.065;     bc.radial_segments = 8
	belt.mesh = bc
	belt.position = Vector3(0, 0.535, 0)
	belt.set_surface_override_material(0, _mat(COLOR_LEATHER, 0.85))

	var buckle := _make_mi("Buckle")
	var bxm := BoxMesh.new()
	bxm.size = Vector3(0.06, 0.05, 0.04)
	buckle.mesh = bxm
	buckle.position = Vector3(0, 0.535, -0.165)
	var mmat := _mat(COLOR_METAL, 0.45)
	mmat.metallic = 0.5
	buckle.set_surface_override_material(0, mmat)

	var pouch := _make_mi("Pouch")
	var psph := SphereMesh.new()
	psph.radius = 0.055; psph.radial_segments = 5; psph.rings = 3
	pouch.mesh = psph
	pouch.position = Vector3(0.13, 0.535, -0.14)
	pouch.scale    = Vector3(1.0, 0.85, 0.75)
	pouch.set_surface_override_material(0, _mat(COLOR_LEATHER.darkened(0.20), 0.90))


# ── Torso & arms ──────────────────────────────────────────────────────────────

func _build_torso() -> void:
	var torso := _make_mi("Torso")
	var tc := CylinderMesh.new()
	tc.top_radius = 0.19; tc.bottom_radius = 0.16
	tc.height = 0.52;     tc.radial_segments = 8
	torso.mesh = tc
	torso.position  = Vector3(0, 0.74, 0)
	torso.rotation.x = deg_to_rad(5)   # slight hunch
	torso.set_surface_override_material(0, _mat(COLOR_CLOTH, 0.95))

	for side in [-1, 1]:
		var sh := _make_mi("Shoulder_" + _lr(side))
		var ssph := SphereMesh.new()
		ssph.radius = 0.11; ssph.radial_segments = 6; ssph.rings = 3
		sh.mesh = ssph
		sh.position = Vector3(side * 0.23, 0.91, 0)
		sh.scale    = Vector3(1.15, 0.65, 0.80)
		sh.set_surface_override_material(0, _mat(COLOR_CLOTH.darkened(0.15), 0.95))

	for side in [-1, 1]:
		var arm := _make_mi("Arm_" + _lr(side))
		var ac := CylinderMesh.new()
		ac.top_radius = 0.068; ac.bottom_radius = 0.056
		ac.height = 0.44;      ac.radial_segments = 6
		arm.mesh = ac
		arm.position   = Vector3(side * 0.28, 0.78, 0)
		arm.rotation.z = side * deg_to_rad(_ARM_REST_Z)
		var amat := _mat(COLOR_SKIN, 0.85)
		arm.set_surface_override_material(0, amat)
		_all_skin_mats.append(amat)

		# Fist is a child of the arm → follows arm rotation automatically
		var fist := MeshInstance3D.new()
		fist.name = "Fist"
		var fsph := SphereMesh.new()
		fsph.radius = 0.065; fsph.radial_segments = 5; fsph.rings = 3
		fist.mesh = fsph
		fist.position = Vector3(0, -0.22, 0)   # bottom tip of cylinder
		var fmat := _mat(COLOR_SKIN.darkened(0.08), 0.85)
		fist.set_surface_override_material(0, fmat)
		_all_skin_mats.append(fmat)
		arm.add_child(fist)


# ── Head ──────────────────────────────────────────────────────────────────────

func _build_head() -> void:
	var head := _make_mi("Head")
	var hs := SphereMesh.new()
	hs.radius = 0.22; hs.height = 0.30; hs.radial_segments = 8; hs.rings = 5
	head.mesh = hs
	head.position = Vector3(0, 1.14, 0)
	head.scale    = Vector3(1.0, 1.08, 0.92)
	var hmat := _mat(COLOR_SKIN, 0.82)
	head.set_surface_override_material(0, hmat)
	_all_skin_mats.append(hmat)

	for side in [-1, 1]:
		var ear := _make_mi("Ear_" + _lr(side))
		var ec := CylinderMesh.new()
		ec.top_radius = 0.018; ec.bottom_radius = 0.055
		ec.height = 0.22;      ec.radial_segments = 5
		ear.mesh = ec
		ear.position   = Vector3(side * 0.22, 1.20, 0.0)
		ear.rotation.z = side * deg_to_rad(75)
		ear.set_surface_override_material(0, _mat(COLOR_SKIN, 0.82))

	var brow := _make_mi("Brow")
	var bxm := BoxMesh.new()
	bxm.size = Vector3(0.24, 0.045, 0.06)
	brow.mesh = bxm
	brow.position   = Vector3(0, 1.19, -0.18)
	brow.rotation.x = deg_to_rad(-8)
	brow.set_surface_override_material(0, _mat(COLOR_SKIN_DARK, 0.88))

	for side in [-1, 1]:
		var eye := _make_mi("Eye_" + _lr(side))
		var esph := SphereMesh.new()
		esph.radius = 0.050; esph.radial_segments = 3; esph.rings = 3
		eye.mesh = esph
		eye.position = Vector3(side * 0.09, 1.16, -0.152)
		_eye_mat = StandardMaterial3D.new()
		_eye_mat.albedo_color = COLOR_EYES
		_eye_mat.emission_enabled = true
		_eye_mat.emission = EMISSIVE_EYES
		_eye_mat.emission_energy_multiplier = 1.2
		eye.set_surface_override_material(0, _eye_mat)

	var nose := _make_mi("Nose")
	var nsph := SphereMesh.new()
	nsph.radius = 0.048; nsph.radial_segments = 5; nsph.rings = 3
	nose.mesh = nsph
	nose.position = Vector3(0, 1.09, -0.215)
	nose.scale    = Vector3(1.3, 0.9, 1.15)
	nose.set_surface_override_material(0, _mat(COLOR_SKIN_DARK, 0.88))

	for side in [-1, 1]:
		var fang := _make_mi("Fang_" + _lr(side))
		var fc := CylinderMesh.new()
		fc.top_radius = 0.005; fc.bottom_radius = 0.016
		fc.height = 0.075;     fc.radial_segments = 4
		fang.mesh = fc
		fang.position   = Vector3(side * 0.042, 1.00, -0.20)
		fang.rotation.x = deg_to_rad(8)
		fang.rotation.z = side * deg_to_rad(6)
		fang.set_surface_override_material(0, _mat(COLOR_FANG, 0.50))

	var wart_positions := [
		Vector3(0.09, 1.22, -0.15), Vector3(-0.12, 1.20, -0.14), Vector3(0.02, 1.25, -0.12)
	]
	for wp in wart_positions:
		var w := _make_mi("Wart")
		var wsph := SphereMesh.new()
		wsph.radius = 0.018; wsph.radial_segments = 4; wsph.rings = 2
		w.mesh = wsph
		w.position = wp
		w.set_surface_override_material(0, _mat(COLOR_SKIN_DARK, 0.92))


# ── Weapon ────────────────────────────────────────────────────────────────────

func _build_weapon() -> void:
	var club := Node3D.new()
	club.name = "Club"
	club.position   = Vector3(0.38, 0.58, 0)
	club.rotation.z = deg_to_rad(18)
	add_child(club)

	var handle := MeshInstance3D.new()
	handle.name = "Handle"
	var hcyl := CylinderMesh.new()
	hcyl.top_radius = 0.030; hcyl.bottom_radius = 0.025
	hcyl.height = 0.72;      hcyl.radial_segments = 6
	handle.mesh = hcyl
	handle.set_surface_override_material(0, _mat(COLOR_WOOD, 0.92))
	club.add_child(handle)

	var chd := MeshInstance3D.new()
	chd.name = "ClubHead"
	var ccyl := CylinderMesh.new()
	ccyl.top_radius = 0.055; ccyl.bottom_radius = 0.115
	ccyl.height = 0.20;      ccyl.radial_segments = 7
	chd.mesh = ccyl
	chd.position.y = 0.46
	chd.set_surface_override_material(0, _mat(COLOR_WOOD.darkened(0.15), 0.92))
	club.add_child(chd)

	var ring := MeshInstance3D.new()
	ring.name = "ClubRing"
	var rcyl := CylinderMesh.new()
	rcyl.top_radius = 0.052; rcyl.bottom_radius = 0.052
	rcyl.height = 0.032;     rcyl.radial_segments = 7
	ring.mesh = rcyl
	ring.position.y = 0.36
	var rmat := _mat(COLOR_METAL, 0.45)
	rmat.metallic = 0.55
	ring.set_surface_override_material(0, rmat)
	club.add_child(ring)

	var spike := MeshInstance3D.new()
	spike.name = "Spike"
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.005; scyl.bottom_radius = 0.040
	scyl.height = 0.11;      scyl.radial_segments = 5
	spike.mesh = scyl
	spike.position.y = 0.615
	spike.set_surface_override_material(0, rmat)
	club.add_child(spike)


# ── Animations ────────────────────────────────────────────────────────────────

func _build_animations() -> void:
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	add_child(ap)
	var lib := AnimationLibrary.new()
	lib.add_animation("idle",   _anim_idle())
	lib.add_animation("walk",   _anim_walk())
	lib.add_animation("run",    _anim_run())
	lib.add_animation("attack", _anim_attack())
	lib.add_animation("hurt",   _anim_stub(0.3))
	lib.add_animation("death",  _anim_death())
	ap.add_animation_library("", lib)
	ap.play("idle")


func _anim_idle() -> Animation:
	var a := Animation.new()
	a.length = 2.4
	a.loop_mode = Animation.LOOP_LINEAR
	# Subtle torso breath
	var tt := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(tt, "Torso:position")
	a.position_track_insert_key(tt, 0.0, Vector3(0, 0.740, 0))
	a.position_track_insert_key(tt, 1.2, Vector3(0, 0.756, 0))
	a.position_track_insert_key(tt, 2.4, Vector3(0, 0.740, 0))
	# Arms and club held at rest (ensures clean reset from other anims)
	var zL := deg_to_rad(-_ARM_REST_Z)
	var zR := deg_to_rad( _ARM_REST_Z)
	var la := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(la, "Arm_L:rotation")
	a.track_insert_key(la, 0.0, Vector3(0.0, 0.0, zL))
	var ra := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(ra, "Arm_R:rotation")
	a.track_insert_key(ra, 0.0, Vector3(0.0, 0.0, zR))
	var cr := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(cr, "Club:rotation")
	a.track_insert_key(cr, 0.0, Vector3(0.0, 0.0, deg_to_rad(18)))
	return a


func _anim_walk() -> Animation:
	var a := Animation.new()
	a.length = 0.70
	a.loop_mode = Animation.LOOP_LINEAR
	# Torso bob
	var tt := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(tt, "Torso:position")
	a.position_track_insert_key(tt, 0.000, Vector3(0, 0.740, 0))
	a.position_track_insert_key(tt, 0.175, Vector3(0, 0.775, 0))
	a.position_track_insert_key(tt, 0.350, Vector3(0, 0.740, 0))
	a.position_track_insert_key(tt, 0.525, Vector3(0, 0.775, 0))
	a.position_track_insert_key(tt, 0.700, Vector3(0, 0.740, 0))
	# Arm swing (opposite phases, TYPE_VALUE on rotation Euler Vector3)
	var zL := deg_to_rad(-_ARM_REST_Z)
	var zR := deg_to_rad( _ARM_REST_Z)
	var sw  := 0.32   # ~18 deg
	var la := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(la, "Arm_L:rotation")
	a.track_set_interpolation_type(la, Animation.INTERPOLATION_CUBIC)
	a.track_insert_key(la, 0.000, Vector3( 0.0, 0.0, zL))
	a.track_insert_key(la, 0.175, Vector3( sw,  0.0, zL))
	a.track_insert_key(la, 0.350, Vector3( 0.0, 0.0, zL))
	a.track_insert_key(la, 0.525, Vector3(-sw,  0.0, zL))
	a.track_insert_key(la, 0.700, Vector3( 0.0, 0.0, zL))
	var ra := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(ra, "Arm_R:rotation")
	a.track_set_interpolation_type(ra, Animation.INTERPOLATION_CUBIC)
	a.track_insert_key(ra, 0.000, Vector3( 0.0, 0.0, zR))
	a.track_insert_key(ra, 0.175, Vector3(-sw,  0.0, zR))
	a.track_insert_key(ra, 0.350, Vector3( 0.0, 0.0, zR))
	a.track_insert_key(ra, 0.525, Vector3( sw,  0.0, zR))
	a.track_insert_key(ra, 0.700, Vector3( 0.0, 0.0, zR))
	return a


func _anim_run() -> Animation:
	var a := Animation.new()
	a.length = 0.40
	a.loop_mode = Animation.LOOP_LINEAR
	# Bigger torso bob + slight forward lean
	var tt := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(tt, "Torso:position")
	a.position_track_insert_key(tt, 0.00, Vector3(0, 0.725, 0.025))
	a.position_track_insert_key(tt, 0.10, Vector3(0, 0.785, 0.025))
	a.position_track_insert_key(tt, 0.20, Vector3(0, 0.725, 0.025))
	a.position_track_insert_key(tt, 0.30, Vector3(0, 0.785, 0.025))
	a.position_track_insert_key(tt, 0.40, Vector3(0, 0.725, 0.025))
	var zL := deg_to_rad(-_ARM_REST_Z)
	var zR := deg_to_rad( _ARM_REST_Z)
	var sw  := 0.52   # ~30 deg
	var la := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(la, "Arm_L:rotation")
	a.track_set_interpolation_type(la, Animation.INTERPOLATION_CUBIC)
	a.track_insert_key(la, 0.00, Vector3( 0.0, 0.0, zL))
	a.track_insert_key(la, 0.10, Vector3( sw,  0.0, zL))
	a.track_insert_key(la, 0.20, Vector3( 0.0, 0.0, zL))
	a.track_insert_key(la, 0.30, Vector3(-sw,  0.0, zL))
	a.track_insert_key(la, 0.40, Vector3( 0.0, 0.0, zL))
	var ra := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(ra, "Arm_R:rotation")
	a.track_set_interpolation_type(ra, Animation.INTERPOLATION_CUBIC)
	a.track_insert_key(ra, 0.00, Vector3( 0.0, 0.0, zR))
	a.track_insert_key(ra, 0.10, Vector3(-sw,  0.0, zR))
	a.track_insert_key(ra, 0.20, Vector3( 0.0, 0.0, zR))
	a.track_insert_key(ra, 0.30, Vector3( sw,  0.0, zR))
	a.track_insert_key(ra, 0.40, Vector3( 0.0, 0.0, zR))
	return a


func _anim_attack() -> Animation:
	var a := Animation.new()
	a.length = 0.70
	a.loop_mode = Animation.LOOP_NONE
	# Torso lunges forward
	var tt := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(tt, "Torso:position")
	a.position_track_insert_key(tt, 0.00, Vector3(0, 0.740,  0.000))
	a.position_track_insert_key(tt, 0.15, Vector3(0, 0.760, -0.055))   # wind-up lean back
	a.position_track_insert_key(tt, 0.45, Vector3(0, 0.720,  0.095))   # lunge
	a.position_track_insert_key(tt, 0.70, Vector3(0, 0.740,  0.000))
	# Club overhead swing
	var ct := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(ct, "Club:rotation")
	a.track_set_interpolation_type(ct, Animation.INTERPOLATION_CUBIC)
	a.track_insert_key(ct, 0.00, Vector3(0.0, 0.0, deg_to_rad(18)))
	a.track_insert_key(ct, 0.15, Vector3(0.0, 0.0, deg_to_rad(-65)))   # wind-up
	a.track_insert_key(ct, 0.45, Vector3(0.0, 0.0, deg_to_rad(105)))   # impact
	a.track_insert_key(ct, 0.70, Vector3(0.0, 0.0, deg_to_rad(18)))    # return
	return a


func _anim_stub(length: float) -> Animation:
	var a := Animation.new()
	a.length = length
	a.loop_mode = Animation.LOOP_NONE
	return a


func _anim_death() -> Animation:
	var a := Animation.new()
	a.length = 1.5
	a.loop_mode = Animation.LOOP_NONE
	var tt := a.add_track(Animation.TYPE_POSITION_3D)
	a.track_set_path(tt, "Torso:position")
	a.position_track_insert_key(tt, 0.0, Vector3(0.0, 0.740, 0.0))
	a.position_track_insert_key(tt, 0.4, Vector3(0.1, 0.730, 0.0))
	a.position_track_insert_key(tt, 1.5, Vector3(0.6, 0.300, 0.0))
	return a


# ── Hit flash – flashes skin and cloth materials ──────────────────────────────

func _on_hit_flash() -> void:
	var saved_skin: Array[Color] = []
	for m in _all_skin_mats:
		saved_skin.append(m.albedo_color)
	var saved_body := _body_mat.albedo_color
	for m in _all_skin_mats:
		m.albedo_color = Color(1.0, 0.45, 0.45)
	_body_mat.albedo_color = Color(1.0, 0.45, 0.45)
	get_tree().create_timer(0.15).timeout.connect(func():
		for i in _all_skin_mats.size():
			_all_skin_mats[i].albedo_color = saved_skin[i]
		_body_mat.albedo_color = saved_body
	)


# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_mi(node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	add_child(mi)
	return mi


func _mat(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness    = roughness
	return m


static func _lr(side: int) -> String:
	return "L" if side == -1 else "R"
