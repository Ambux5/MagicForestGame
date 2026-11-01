extends Node3D
## Main game world – spawns terrain, lighting, environment props, enemies,
## collectibles, player, HUD, and pause menu.

const WORLD_HALF := 40.0   # half-extent of the play area
const TREE_COUNT := 35
const ROCK_COUNT := 20
const MUSHROOM_COUNT := 18
const GRASS_PATCH_COUNT := 50
const FLOWER_COUNT := 40

# Enemy spawn configuration
const ENEMY_TYPES: Array[String] = [
	"res://scenes/enemies/forest_slime.tscn",
	"res://scenes/enemies/mushroom_monster.tscn",
	"res://scenes/enemies/forest_goblin.tscn",
]
const MAX_ENEMIES := 12
const ENEMY_RESPAWN_TIME := 20.0

# Collectible spawn configuration
const COLLECTIBLE_SCENE := "res://scenes/items/collectible.tscn"
const COLLECTIBLE_COUNT := 20

var _enemy_pool: Array[Node] = []
var _respawn_timer: float = 0.0
var _loaded_scenes: Dictionary = {}
var _player: Node3D


func _ready() -> void:
	if NetworkManager.is_active:
		seed(42)   # deterministic world so all peers see the same layout
	else:
		randomize()
	_build_terrain()
	_build_lighting()
	_build_world_boundary()
	_build_environment()
	_spawn_collectibles()
	_spawn_enemies()
	_spawn_player()
	_add_ui()
	_load_saved_state()


# ── Terrain ────────────────────────────────────────────────────────────────────

func _build_terrain() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(WORLD_HALF * 2, WORLD_HALF * 2)
	plane.subdivide_width = 4
	plane.subdivide_depth = 4
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.42, 0.18)
	mat.roughness = 1.0
	ground.set_surface_override_material(0, mat)
	add_child(ground)

	# Static body for ground collision
	var sb := StaticBody3D.new()
	sb.name = "GroundBody"
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WORLD_HALF * 2, 0.4, WORLD_HALF * 2)
	col.shape = box
	col.position = Vector3(0, -0.2, 0)
	sb.add_child(col)
	add_child(sb)

	# Subtle terrain variation patches (dark/light grass)
	for i in 15:
		var patch := MeshInstance3D.new()
		var pmesh := PlaneMesh.new()
		var patch_size := randf_range(3.0, 8.0)
		pmesh.size = Vector2(patch_size, patch_size)
		patch.mesh = pmesh
		patch.position = Vector3(
			randf_range(-WORLD_HALF + 5, WORLD_HALF - 5),
			0.01,
			randf_range(-WORLD_HALF + 5, WORLD_HALF - 5)
		)
		var pmat := StandardMaterial3D.new()
		var darkness := randf_range(0.0, 0.08)
		pmat.albedo_color = Color(0.18 + darkness, 0.38 + darkness, 0.14, 1.0)
		pmat.roughness = 1.0
		patch.set_surface_override_material(0, pmat)
		add_child(patch)

	# Small pond
	_build_pond(Vector3(15, 0.02, -10), 5.0)
	_build_pond(Vector3(-20, 0.02, 18), 3.5)


func _build_pond(pos: Vector3, radius: float) -> void:
	var pond := MeshInstance3D.new()
	pond.name = "Pond"
	var pmesh := PlaneMesh.new()
	pmesh.size = Vector2(radius * 2, radius * 2)
	pond.mesh = pmesh
	pond.position = pos
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.15, 0.35, 0.65, 0.85)
	pmat.roughness = 0.05
	pmat.metallic = 0.4
	pmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pond.set_surface_override_material(0, pmat)
	add_child(pond)


# ── Lighting ───────────────────────────────────────────────────────────────────

func _build_lighting() -> void:
	# Sky / ambient
	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.28, 0.45, 0.65)
	sky_mat.sky_horizon_color = Color(0.55, 0.75, 0.45)
	sky_mat.ground_bottom_color = Color(0.18, 0.28, 0.14)
	sky_mat.ground_horizon_color = Color(0.30, 0.42, 0.22)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_density = 0.006
	env.fog_light_color = Color(0.6, 0.8, 0.6)
	env.fog_depth_begin = 20.0
	env.fog_depth_end = 80.0
	world_env.environment = env
	add_child(world_env)

	# Main directional light (sun)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.add_to_group("main_light")
	sun.light_color = Color(1.0, 0.95, 0.80)
	sun.light_energy = 1.2
	sun.shadow_enabled = false   # Off by default for Raspberry Pi perf
	sun.rotation_degrees = Vector3(-45, 30, 0)
	add_child(sun)

	# Soft fill light from opposite side
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color(0.4, 0.6, 0.8)
	fill.light_energy = 0.25
	fill.shadow_enabled = false
	fill.rotation_degrees = Vector3(-30, -150, 0)
	add_child(fill)


# ── World boundary ─────────────────────────────────────────────────────────────

func _build_world_boundary() -> void:
	var half := WORLD_HALF
	var walls := [
		[Vector3(0, 3, half), Vector3(half * 2, 6, 1)],
		[Vector3(0, 3, -half), Vector3(half * 2, 6, 1)],
		[Vector3(half, 3, 0), Vector3(1, 6, half * 2)],
		[Vector3(-half, 3, 0), Vector3(1, 6, half * 2)],
	]
	for wall_data in walls:
		var sb := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = wall_data[1]
		col.shape = box
		sb.position = wall_data[0]
		sb.add_child(col)
		add_child(sb)


# ── Environment objects ────────────────────────────────────────────────────────

func _build_environment() -> void:
	_place_trees()
	_place_rocks()
	_place_mushrooms()
	_place_flowers()
	_place_ancient_ruins()
	_place_magical_stones()


func _place_trees() -> void:
	var tree_builder_script := load("res://scripts/environment/tree_builder.gd")
	for i in TREE_COUNT:
		var pos := _random_world_pos(5.0, WORLD_HALF - 3.0)
		var tree := Node3D.new()
		tree.name = "Tree_" + str(i)
		tree.set_script(tree_builder_script)
		tree.set("variation", i % 4)
		tree.position = pos
		tree.rotation.y = randf() * TAU
		tree.scale = Vector3.ONE * randf_range(0.8, 1.5)
		add_child(tree)

		# Static collision capsule for each tree
		var sb := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var cap := CapsuleShape3D.new()
		cap.radius = 0.25
		cap.height = 2.5
		col.shape = cap
		col.position = Vector3(0, 1.25, 0)
		sb.position = pos
		sb.add_child(col)
		add_child(sb)


func _place_rocks() -> void:
	for i in ROCK_COUNT:
		var pos := _random_world_pos(3.0, WORLD_HALF - 2.0)
		var rock := MeshInstance3D.new()
		rock.name = "Rock_" + str(i)
		var sph := SphereMesh.new()
		var scale_x := randf_range(0.25, 0.8)
		var scale_y := randf_range(0.2, 0.55)
		var scale_z := randf_range(0.25, 0.7)
		sph.radius = 0.5
		sph.height = 1.0
		sph.radial_segments = 7
		sph.rings = 5
		rock.mesh = sph
		rock.position = Vector3(pos.x, scale_y * 0.5, pos.z)
		rock.scale = Vector3(scale_x, scale_y, scale_z) * randf_range(0.9, 2.0)
		rock.rotation = Vector3(randf() * 0.4, randf() * TAU, randf() * 0.3)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(
			randf_range(0.45, 0.62),
			randf_range(0.44, 0.60),
			randf_range(0.40, 0.55)
		)
		mat.roughness = 0.95
		rock.set_surface_override_material(0, mat)
		add_child(rock)

		# Rock collision
		var sb := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(scale_x * 1.0, scale_y, scale_z * 1.0)
		col.shape = box
		sb.position = rock.position
		sb.add_child(col)
		add_child(sb)


func _place_mushrooms() -> void:
	for i in MUSHROOM_COUNT:
		var pos := _random_world_pos(2.0, WORLD_HALF - 2.0)
		var group := Node3D.new()
		group.name = "MushroomGroup_" + str(i)
		group.position = pos

		var count := randi_range(1, 3)
		for j in count:
			_make_mushroom_prop(group,
				Vector3(randf_range(-0.4, 0.4), 0, randf_range(-0.4, 0.4)),
				randf_range(0.3, 0.8))
		add_child(group)


func _make_mushroom_prop(parent: Node3D, offset: Vector3, scale: float) -> void:
	var mi := Node3D.new()
	mi.position = offset
	mi.scale = Vector3.ONE * scale

	var stem := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.08
	scyl.bottom_radius = 0.10
	scyl.height = 0.35
	scyl.radial_segments = 7
	stem.mesh = scyl
	stem.position = Vector3(0, 0.175, 0)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.85, 0.80, 0.70)
	stem.set_surface_override_material(0, smat)
	mi.add_child(stem)

	var cap := MeshInstance3D.new()
	var ccyl := CylinderMesh.new()
	ccyl.top_radius = 0.02
	ccyl.bottom_radius = 0.28
	ccyl.height = 0.22
	ccyl.radial_segments = 8
	cap.mesh = ccyl
	cap.position = Vector3(0, 0.45, 0)
	var glow_colors := [
		Color(0.85, 0.25, 0.25),
		Color(0.9, 0.55, 0.1),
		Color(0.35, 0.8, 0.35),
		Color(0.55, 0.25, 0.85),
	]
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = glow_colors[randi() % glow_colors.size()]
	cmat.emission_enabled = true
	cmat.emission = cmat.albedo_color * 0.5
	cmat.emission_energy_multiplier = 0.6
	cap.set_surface_override_material(0, cmat)
	mi.add_child(cap)
	parent.add_child(mi)


func _place_flowers() -> void:
	var flower_colors := [
		Color(0.95, 0.9, 0.2),
		Color(0.9, 0.3, 0.7),
		Color(0.3, 0.6, 0.95),
		Color(0.95, 0.5, 0.1),
		Color(0.9, 0.95, 0.9),
	]
	for i in FLOWER_COUNT:
		var pos := _random_world_pos(1.0, WORLD_HALF - 2.0)
		var flower := MeshInstance3D.new()
		var sph := SphereMesh.new()
		sph.radius = 0.08
		sph.height = 0.15
		sph.radial_segments = 5
		sph.rings = 3
		flower.mesh = sph
		flower.position = Vector3(pos.x, 0.12, pos.z)
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = flower_colors[i % flower_colors.size()]
		flower.set_surface_override_material(0, fmat)
		add_child(flower)


func _place_ancient_ruins() -> void:
	# A small ruined stone circle near the center
	var ruin_center := Vector3(8, 0, 8)
	var pillar_count := 6
	var radius := 5.0
	for i in pillar_count:
		var angle := (float(i) / pillar_count) * TAU
		var pos := ruin_center + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var height := randf_range(1.2, 2.5)
		var toppled := randf() < 0.35

		var pillar := StaticBody3D.new()
		pillar.name = "RuinPillar_" + str(i)
		pillar.position = pos

		var mi := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.22
		cyl.bottom_radius = 0.25
		cyl.height = height
		cyl.radial_segments = 8
		mi.mesh = cyl
		if toppled:
			mi.position = Vector3(0, 0.2, 0)
			mi.rotation.z = deg_to_rad(80)
		else:
			mi.position = Vector3(0, height * 0.5, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.68, 0.64, 0.58)
		mat.roughness = 0.9
		mi.set_surface_override_material(0, mat)
		pillar.add_child(mi)

		var col := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(0.5, height, 0.5)
		col.shape = box
		col.position = Vector3(0, height * 0.5, 0)
		pillar.add_child(col)
		add_child(pillar)

	# Altar stone at center
	var altar := StaticBody3D.new()
	altar.position = ruin_center + Vector3(0, 0.25, 0)
	var ami := MeshInstance3D.new()
	var abox := BoxMesh.new()
	abox.size = Vector3(1.5, 0.5, 1.0)
	ami.mesh = abox
	var amat := StandardMaterial3D.new()
	amat.albedo_color = Color(0.62, 0.58, 0.52)
	amat.emission_enabled = true
	amat.emission = Color(0.2, 0.5, 0.2)
	amat.emission_energy_multiplier = 0.3
	ami.set_surface_override_material(0, amat)
	altar.add_child(ami)
	var acol := CollisionShape3D.new()
	var abox2 := BoxShape3D.new()
	abox2.size = Vector3(1.5, 0.5, 1.0)
	acol.shape = abox2
	altar.add_child(acol)
	add_child(altar)


func _place_magical_stones() -> void:
	var stone_colors: Array[Color] = [
		Color(0.2, 0.9, 0.3),
		Color(0.3, 0.5, 0.95),
		Color(0.9, 0.3, 0.9),
	]
	for i in 8:
		var pos := _random_world_pos(8.0, WORLD_HALF - 5.0)
		var stone := MeshInstance3D.new()
		stone.name = "MagicStone_" + str(i)
		var sph := SphereMesh.new()
		sph.radius = randf_range(0.15, 0.35)
		sph.height = sph.radius * 2.0
		sph.radial_segments = 6
		sph.rings = 4
		stone.mesh = sph
		stone.position = Vector3(pos.x, sph.radius, pos.z)
		var col: Color = stone_colors[i % stone_colors.size()]
		var smat := StandardMaterial3D.new()
		smat.albedo_color = col
		smat.emission_enabled = true
		smat.emission = col * 0.7
		smat.emission_energy_multiplier = 1.2
		stone.set_surface_override_material(0, smat)
		add_child(stone)

		var light := OmniLight3D.new()
		light.light_color = col
		light.light_energy = 0.6
		light.omni_range = 3.0
		light.position = Vector3(pos.x, sph.radius + 0.5, pos.z)
		add_child(light)


# ── Collectibles ───────────────────────────────────────────────────────────────

func _spawn_collectibles() -> void:
	var collectible_scene := _get_scene(COLLECTIBLE_SCENE)
	if collectible_scene == null:
		return

	var types := [0, 1, 2, 3]
	for i in COLLECTIBLE_COUNT:
		var inst = collectible_scene.instantiate()
		inst.item_type = types[i % types.size()]
		match inst.item_type:
			0: inst.value = 25.0   # herb
			1: inst.value = 20.0   # mana
			2: inst.value = 30.0   # mushroom
			3: inst.value = 40.0   # XP
		var pos := _random_world_pos(4.0, WORLD_HALF - 4.0)
		inst.position = Vector3(pos.x, 0.4, pos.z)
		add_child(inst)


# ── Enemies ───────────────────────────────────────────────────────────────────

func _spawn_enemies() -> void:
	var per_type := MAX_ENEMIES / ENEMY_TYPES.size()
	for type_path in ENEMY_TYPES:
		var scene := _get_scene(type_path)
		if scene == null:
			continue
		for i in per_type:
			var inst = scene.instantiate()
			var pos := _random_world_pos(12.0, WORLD_HALF - 5.0)
			inst.position = Vector3(pos.x, 0.5, pos.z)
			inst.died.connect(_on_enemy_died)
			add_child(inst)
			_enemy_pool.append(inst)


func _on_enemy_died(_pos: Vector3, _xp: int) -> void:
	_enemy_pool = _enemy_pool.filter(func(e): return is_instance_valid(e))
	_respawn_timer = ENEMY_RESPAWN_TIME


func _process(delta: float) -> void:
	if _respawn_timer > 0.0:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_check_respawn()


func _check_respawn() -> void:
	var alive := _enemy_pool.filter(func(e): return is_instance_valid(e)).size()
	if alive < MAX_ENEMIES:
		var to_spawn := MAX_ENEMIES - alive
		var types: Array[String] = ENEMY_TYPES
		for i in to_spawn:
			var type_path: String = types[randi() % types.size()]
			var scene := _get_scene(type_path)
			if scene == null:
				continue
			var inst = scene.instantiate()
			var pos := _random_world_pos(15.0, WORLD_HALF - 5.0)
			inst.position = Vector3(pos.x, 0.5, pos.z)
			inst.died.connect(_on_enemy_died)
			add_child(inst)
			_enemy_pool.append(inst)


# ── Player ────────────────────────────────────────────────────────────────────

const _SPAWN_OFFSETS: Array[Vector3] = [
	Vector3(  0.0, 1.0,  5.0),
	Vector3(  5.0, 1.0,  0.0),
	Vector3( -5.0, 1.0,  0.0),
	Vector3(  0.0, 1.0, -5.0),
]


func _spawn_player() -> void:
	if NetworkManager.is_active:
		_spawn_multiplayer_players()
	else:
		var player_scene := _get_scene("res://scenes/player/player.tscn")
		if player_scene == null:
			return
		_player = player_scene.instantiate()
		_player.position = Vector3(0, 1.0, 0)
		add_child(_player)


func _spawn_multiplayer_players() -> void:
	NetworkManager.peer_joined.connect(_on_mp_peer_joined)
	NetworkManager.peer_left.connect(_on_mp_peer_left)
	var idx := 0
	for pid: int in NetworkManager.players:
		var pos := _SPAWN_OFFSETS[idx % _SPAWN_OFFSETS.size()]
		_spawn_player_for_peer(pid, NetworkManager.players[pid], pos)
		idx += 1


func _spawn_player_for_peer(pid: int, p_name: String, pos: Vector3) -> void:
	var player_scene := _get_scene("res://scenes/player/player.tscn")
	if player_scene == null:
		return
	var player = player_scene.instantiate()
	player.name        = "Player_%d" % pid
	player.peer_id     = pid
	player.player_name = p_name
	player.set_multiplayer_authority(pid)
	player.position = pos
	add_child(player)
	if pid == NetworkManager.get_local_peer_id():
		_player = player
		GameManager.player_node = player


func _on_mp_peer_joined(peer_id: int, p_name: String) -> void:
	if get_node_or_null("Player_%d" % peer_id) != null:
		return
	var pos := _SPAWN_OFFSETS[NetworkManager.players.size() % _SPAWN_OFFSETS.size()]
	_spawn_player_for_peer(peer_id, p_name, pos)


func _on_mp_peer_left(peer_id: int) -> void:
	var node := get_node_or_null("Player_%d" % peer_id)
	if node:
		node.queue_free()


# ── UI ────────────────────────────────────────────────────────────────────────

func _add_ui() -> void:
	var hud_scene := _get_scene("res://scenes/ui/hud.tscn")
	if hud_scene:
		var hud := hud_scene.instantiate()
		add_child(hud)

	var pause_scene := _get_scene("res://scenes/ui/pause_menu.tscn")
	if pause_scene:
		var pause := pause_scene.instantiate()
		add_child(pause)


# ── Save/load ─────────────────────────────────────────────────────────────────

func _load_saved_state() -> void:
	if NetworkManager.is_active:
		return   # no save/load in multiplayer
	if SaveSystem.save_exists():
		SaveSystem.load_game()
		if is_instance_valid(_player):
			var saved_pos := SaveSystem.get_saved_position()
			if saved_pos != Vector3.ZERO:
				_player.global_position = saved_pos


# ── Helpers ────────────────────────────────────────────────────────────────────

func _random_world_pos(min_dist: float, max_dist: float) -> Vector3:
	var dist := randf_range(min_dist, max_dist)
	var angle := randf() * TAU
	return Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)


func _get_scene(path: String) -> PackedScene:
	if _loaded_scenes.has(path):
		return _loaded_scenes[path]
	if ResourceLoader.exists(path):
		var s: PackedScene = load(path)
		_loaded_scenes[path] = s
		return s
	push_warning("WorldGenerator: Scene not found – " + path)
	return null
