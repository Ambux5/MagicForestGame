extends CharacterBody3D
## Base class for all enemies.
## Provides an AI state machine (IDLE → PATROL → CHASE → ATTACK → HURT → DEAD).
## Subclasses override exported stats and _attack() behaviour.

signal died(position: Vector3, xp_reward: int)
signal health_changed(current: float, maximum: float)

# ── Stats (override in subclass via @export) ───────────────────────────────────
@export var max_health: float = 40.0
@export var move_speed: float = 2.5
@export var detect_radius: float = 10.0
@export var attack_range: float = 1.8
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 2.0
@export var xp_reward: int = 25
@export var enemy_name: String = "Enemy"

# ── Runtime state ──────────────────────────────────────────────────────────────
var current_health: float
var _state: int = 0
var _attack_timer: float = 0.0
var _ai_timer: float = 0.0
const AI_TICK: float = 0.15        # AI logic runs every 0.15 s (perf)
var _patrol_target: Vector3 = Vector3.ZERO
var _player: Node3D = null
var _is_dead: bool = false
var _hurt_timer: float = 0.0

const GRAVITY := 18.0

enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

# ── Child nodes – lazily resolved after subclass _ready() creates them ─────────
var _animation_player_ref: AnimationPlayer = null

func _get_anim() -> AnimationPlayer:
	if _animation_player_ref == null:
		_animation_player_ref = get_node_or_null("AnimationPlayer")
	return _animation_player_ref


func _ready() -> void:
	current_health = max_health
	_state = State.IDLE
	add_to_group("enemies")
	_patrol_target = global_position
	_find_patrol_point()


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	_apply_gravity(delta)
	_attack_timer = maxf(0.0, _attack_timer - delta)
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	if _hurt_timer > 0.0:
		_move_toward_player(delta, 0.0)
		move_and_slide()
		return

	_ai_timer -= delta
	if _ai_timer <= 0.0:
		_ai_timer = AI_TICK
		_ai_tick()

	_execute_state(delta)
	move_and_slide()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -0.5


# ── AI ─────────────────────────────────────────────────────────────────────────

func _ai_tick() -> void:
	if _state == State.HURT or _state == State.DEAD:
		return

	_player = _find_player()
	if _player == null:
		if _state != State.PATROL and _state != State.IDLE:
			_set_state(State.IDLE)
		return

	var dist := global_position.distance_to(_player.global_position)
	match _state:
		State.IDLE, State.PATROL:
			if dist <= detect_radius:
				_set_state(State.CHASE)
		State.CHASE:
			if dist <= attack_range:
				_set_state(State.ATTACK)
			elif dist > detect_radius * 1.5:
				_set_state(State.PATROL)
		State.ATTACK:
			if dist > attack_range * 1.2:
				_set_state(State.CHASE)


func _execute_state(delta: float) -> void:
	match _state:
		State.IDLE:
			_idle_behavior(delta)
		State.PATROL:
			_patrol_behavior(delta)
		State.CHASE:
			_chase_behavior(delta)
		State.ATTACK:
			_attack_behavior(delta)


func _idle_behavior(_delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0, 5.0 * _delta)
	velocity.z = move_toward(velocity.z, 0, 5.0 * _delta)
	_play_animation("idle")
	# Occasionally start patrolling
	if randf() < 0.005:
		_find_patrol_point()
		_set_state(State.PATROL)


func _patrol_behavior(delta: float) -> void:
	var dist := global_position.distance_to(_patrol_target)
	if dist < 1.5:
		_find_patrol_point()
		_set_state(State.IDLE)
		return
	_move_toward_point(_patrol_target, delta, move_speed * 0.6)
	_play_animation("walk")


func _chase_behavior(delta: float) -> void:
	if _player:
		_move_toward_player(delta, move_speed)
		_play_animation("run")


func _attack_behavior(_delta: float) -> void:
	_move_toward_player(_delta, 0.0)
	if _attack_timer <= 0.0:
		_attack_timer = attack_cooldown
		_play_animation("attack")
		get_tree().create_timer(0.35).timeout.connect(_do_attack_damage)


func _find_patrol_point() -> void:
	var offset := Vector3(randf_range(-8, 8), 0, randf_range(-8, 8))
	_patrol_target = global_position + offset


func _find_player() -> Node3D:
	return GameManager.player_node


# ── Movement helpers ──────────────────────────────────────────────────────────

func _move_toward_player(delta: float, speed: float) -> void:
	if not _player:
		return
	_move_toward_point(_player.global_position, delta, speed)


func _move_toward_point(target: Vector3, _delta: float, speed: float) -> void:
	var dir := (target - global_position)
	dir.y = 0.0
	if dir.length() > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		look_at(Vector3(target.x, global_position.y, target.z), Vector3.UP)
	else:
		velocity.x = 0.0
		velocity.z = 0.0


# ── Combat ────────────────────────────────────────────────────────────────────

func _do_attack_damage() -> void:
	if _is_dead or _player == null:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= attack_range * 1.3:
		if _player.has_method("take_damage"):
			_player.take_damage(attack_damage)


func take_damage(amount: float) -> void:
	if _is_dead:
		return
	current_health -= amount
	health_changed.emit(current_health, max_health)
	AudioManager.play_sfx("enemy_hurt")
	_on_hit_flash()
	if current_health <= 0.0:
		_die()
	else:
		_set_state(State.HURT)
		_hurt_timer = 0.35
		_play_animation("hurt")
		get_tree().create_timer(0.35).timeout.connect(func(): _set_state(State.CHASE))


func _on_hit_flash() -> void:
	pass  # Subclasses override to flash material


func _die() -> void:
	_is_dead = true
	_set_state(State.DEAD)
	_play_animation("death")
	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	GameManager.gain_experience(xp_reward)
	died.emit(global_position, xp_reward)
	AudioManager.play_sfx("enemy_die")
	get_tree().create_timer(2.0).timeout.connect(queue_free)


# ── Animation ─────────────────────────────────────────────────────────────────

func _play_animation(anim: String) -> void:
	var ap := _get_anim()
	if ap == null:
		return
	if not ap.has_animation(anim):
		return
	if ap.current_animation == anim:
		return
	ap.play(anim)


func _set_state(new_state: int) -> void:
	_state = new_state


# ── Public ───────────────────────────────────────────────────────────────────

func get_health_fraction() -> float:
	return current_health / max_health
