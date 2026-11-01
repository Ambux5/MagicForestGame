extends CharacterBody3D
## Player controller – CharacterBody3D.
## WASD movement, mouse-look camera, jumping, sprinting, and spell casting.

# ── Export parameters (editable in Godot Inspector) ──────────────────────────

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 9.0
@export var jump_velocity: float = 5.5
@export var gravity: float = 18.0
@export var camera_sensitivity: float = 0.003
@export var camera_vertical_min: float = -50.0
@export var camera_vertical_max: float = 70.0
@export var camera_distance: float = 4.5

# ── Child node references ────────────────────────────────────────────────────

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var mesh_root: Node3D = $MeshRoot
@onready var spell_cast_point: Marker3D = $MeshRoot/SpellCastPoint
@onready var damage_flash_timer: Timer = $DamageFlashTimer
@onready var mana_regen_timer: Timer = $ManaRegenTimer
@onready var interact_ray: RayCast3D = $SpringArm3D/Camera3D/InteractRay

# ── Internal state ────────────────────────────────────────────────────────────

var _camera_yaw: float = 0.0
var _camera_pitch: float = 0.0
var _is_dead: bool = false
var _current_animation: String = ""
var _is_casting: bool = false
var _cast_timer: float = 0.0
const CAST_DURATION := 0.4

# Animation player – set by WizardMeshBuilder once its AnimationPlayer is ready
# Multiplayer: set by world.gd before add_child when in MP mode
var peer_id:     int    = 1
var player_name: String = "Wizard"

var _wizard_anim_player: AnimationPlayer = null

# Targeting
var _targeted_enemy: Node = null
var _target_timer: float = 0.0
const TARGET_UPDATE_RATE := 0.1

# Spell scenes (loaded once)
var _spell_scenes: Array = []

const SPELL_PATHS := [
	"res://scenes/spells/nature_bolt.tscn",
	"res://scenes/spells/fireball.tscn",
	"res://scenes/spells/healing_spell.tscn",
	"res://scenes/spells/nature_shield.tscn",
]
const SPELL_MANA_COSTS: Array[float] = [8.0, 15.0, 20.0, 18.0]

var _selected_spell: int = 0

# Wizard material (for damage flash)
var _wizard_materials: Array[StandardMaterial3D] = []
const DAMAGE_FLASH_COLOR := Color(1.0, 0.3, 0.3)
const NORMAL_EMISSIVE := Color(0.1, 0.4, 0.1)


func _ready() -> void:
	if _is_local():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		spring_arm.spring_length = camera_distance
		spring_arm.collision_mask = 1
		_load_spells()
		_connect_signals()
		# Restore saved position only in singleplayer
		if not NetworkManager.is_active and SaveSystem.save_exists():
			global_position = SaveSystem.get_saved_position()
		GameManager.player_node = self
		GameManager.health_changed.emit(GameManager.current_health, GameManager.max_health)
		GameManager.mana_changed.emit(GameManager.current_mana, GameManager.max_mana)
	else:
		# Remote peer – deactivate camera and physics-based camera arm
		camera.current = false

	# Show floating name label in multiplayer
	if NetworkManager.is_active:
		_build_name_label()


func _is_local() -> bool:
	if not NetworkManager.is_active:
		return true
	return is_multiplayer_authority()


func _build_name_label() -> void:
	var lbl := Label3D.new()
	lbl.text = player_name
	lbl.position = Vector3(0.0, 2.6, 0.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.font_size = 24
	lbl.modulate = Color(1.0, 1.0, 0.75)
	lbl.no_depth_test = true
	add_child(lbl)


func _load_spells() -> void:
	_spell_scenes.clear()
	for path in SPELL_PATHS:
		if ResourceLoader.exists(path):
			_spell_scenes.append(load(path))
		else:
			_spell_scenes.append(null)


func _connect_signals() -> void:
	GameManager.player_died.connect(_on_player_died)
	damage_flash_timer.timeout.connect(_on_damage_flash_end)
	mana_regen_timer.timeout.connect(_regen_mana)


# ── Input ─────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if _is_dead:
		return
	if not _is_local():
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens: float = SaveSystem.load_config().get_value("controls", "camera_sensitivity", camera_sensitivity)
		_camera_yaw -= event.relative.x * sens
		_camera_pitch -= event.relative.y * sens
		_camera_pitch = clampf(_camera_pitch, deg_to_rad(camera_vertical_min), deg_to_rad(camera_vertical_max))
		rotation.y = _camera_yaw
		spring_arm.rotation.x = _camera_pitch

	if event.is_action_pressed("spell_1"):
		_selected_spell = 0
	if event.is_action_pressed("spell_2"):
		_selected_spell = 1
	if event.is_action_pressed("spell_3"):
		_selected_spell = 2
	if event.is_action_pressed("spell_4"):
		_selected_spell = 3

	if event.is_action_pressed("cast_spell"):
		_try_cast_spell()

	if event.is_action_pressed("pause"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		GameManager.toggle_pause()


# ── Physics ───────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not _is_local():
		return   # remote players: position is set via _rpc_sync RPC

	if _is_dead or GameManager.is_paused:
		return

	_apply_gravity(delta)
	_handle_movement(delta)
	_handle_cast_timer(delta)
	_update_targeting(delta)
	move_and_slide()
	_update_animation()

	# Broadcast position to all peers in multiplayer
	if NetworkManager.is_active and NetworkManager.players.size() > 1:
		_rpc_sync.rpc(global_position, rotation.y, _current_animation)


@rpc("any_peer", "unreliable")
func _rpc_sync(pos: Vector3, yaw: float, anim: String) -> void:
	global_position = pos
	rotation.y      = yaw
	_play_animation(anim)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity
		_play_animation("jump")


func _handle_movement(delta: float) -> void:
	var speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction.length() > 0.01:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)


func _handle_cast_timer(delta: float) -> void:
	if _is_casting:
		_cast_timer -= delta
		if _cast_timer <= 0.0:
			_is_casting = false


# ── Spell casting ─────────────────────────────────────────────────────────────

func _try_cast_spell() -> void:
	if _is_casting:
		return
	if not GameManager.is_spell_ready(_selected_spell):
		return
	var cost: float = SPELL_MANA_COSTS[_selected_spell]
	if not GameManager.use_mana(cost):
		return

	GameManager.trigger_cooldown(_selected_spell)
	_is_casting = true
	_cast_timer = CAST_DURATION
	_play_animation("cast")

	# Slight delay before projectile spawns
	get_tree().create_timer(0.15).timeout.connect(_spawn_spell.bind(_selected_spell))


func _spawn_spell(spell_index: int) -> void:
	if _spell_scenes[spell_index] == null:
		return

	var spell_instance = _spell_scenes[spell_index].instantiate()
	get_tree().current_scene.add_child(spell_instance)

	var spawn_pos := spell_cast_point.global_position
	spell_instance.global_position = spawn_pos

	# Aim toward camera forward or a raycasted target
	var aim_dir := -camera.global_transform.basis.z
	if interact_ray.is_colliding():
		aim_dir = (interact_ray.get_collision_point() - spawn_pos).normalized()

	spell_instance.direction = aim_dir
	if spell_instance.has_method("initialize"):
		spell_instance.initialize(aim_dir, GameManager.spell_power)


# ── Animation ─────────────────────────────────────────────────────────────────

func _update_animation() -> void:
	if _is_casting:
		return
	var hspeed := Vector2(velocity.x, velocity.z).length()
	var new_anim: String
	if not is_on_floor():
		new_anim = "fall" if velocity.y < -1.0 else "jump"
	elif hspeed > 6.0:
		new_anim = "run"
	elif hspeed > 0.3:
		new_anim = "walk"
	else:
		new_anim = "idle"
	_play_animation(new_anim)


func _play_animation(anim: String) -> void:
	if _current_animation == anim:
		return
	# Use the wizard's own animation player if available
	var ap: AnimationPlayer = _wizard_anim_player if _wizard_anim_player != null else animation_player
	if ap == null or not ap.has_animation(anim):
		return
	_current_animation = anim
	ap.play(anim)


func _update_targeting(delta: float) -> void:
	_target_timer -= delta
	if _target_timer > 0.0:
		return
	_target_timer = TARGET_UPDATE_RATE

	var hit_enemy: Node = null
	if interact_ray.is_colliding():
		var col := interact_ray.get_collider()
		if is_instance_valid(col) and col.is_in_group("enemies"):
			hit_enemy = col

	if hit_enemy != _targeted_enemy:
		_targeted_enemy = hit_enemy
		if hit_enemy != null:
			GameManager.enemy_targeted.emit(hit_enemy)
		else:
			GameManager.enemy_untargeted.emit()


# ── Called by WizardMeshBuilder once its AnimationPlayer is created ────────────

func set_wizard_animation_player(ap: AnimationPlayer) -> void:
	_wizard_anim_player = ap
	# Re-play current animation on the new player
	if _current_animation != "":
		if ap.has_animation(_current_animation):
			ap.play(_current_animation)
		elif ap.has_animation("idle"):
			ap.play("idle")


# ── Damage ─────────────────────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	if _is_dead:
		return
	GameManager.take_damage(amount)
	AudioManager.play_sfx("player_hurt")
	_flash_damage()
	if _current_animation != "hurt":
		_play_animation("hurt")


func _flash_damage() -> void:
	for mat in _wizard_materials:
		mat.emission_enabled = true
		mat.emission = DAMAGE_FLASH_COLOR
	damage_flash_timer.start(0.25)


func _on_damage_flash_end() -> void:
	for mat in _wizard_materials:
		mat.emission = NORMAL_EMISSIVE


func _on_player_died() -> void:
	_is_dead = true
	_play_animation("death")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().create_timer(2.5).timeout.connect(_show_game_over)


func _show_game_over() -> void:
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over()


# ── Mana regen ─────────────────────────────────────────────────────────────────

func _regen_mana() -> void:
	if not _is_dead:
		GameManager.restore_mana(2.0)


# ── Public helpers ────────────────────────────────────────────────────────────

func get_selected_spell() -> int:
	return _selected_spell


func get_cast_point() -> Vector3:
	return spell_cast_point.global_position


func register_material(mat: StandardMaterial3D) -> void:
	_wizard_materials.append(mat)
