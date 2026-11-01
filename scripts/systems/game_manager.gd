extends Node
## Global game state manager – autoloaded as GameManager.
## Tracks player stats, emits signals for UI, and coordinates scene transitions.

signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal experience_gained(amount: int, total: int)
signal level_up(new_level: int)
signal player_died
signal game_paused(paused: bool)
signal enemy_targeted(enemy_node)
signal enemy_untargeted

# ── Player stats ──────────────────────────────────────────────────────────────

var player_level: int = 1
var experience: int = 0
var experience_to_next: int = 100

var max_health: float = 100.0
var current_health: float = 100.0
var max_mana: float = 80.0
var current_mana: float = 80.0

var base_damage: float = 10.0
var spell_power: float = 1.0
var movement_speed: float = 5.0

var has_shield: bool = false
var shield_reduction: float = 0.3

# ── Cooldowns ─────────────────────────────────────────────────────────────────

var spell_cooldowns: Array[float] = [0.0, 0.0, 0.0, 0.0]
var spell_max_cooldowns: Array[float] = [1.2, 2.5, 8.0, 12.0]

# ── Game state ────────────────────────────────────────────────────────────────

var is_paused: bool = false
var is_in_game: bool = false
var player_node: CharacterBody3D = null

const GAME_SCENE := "res://scenes/environment/world.tscn"
const MAIN_MENU_SCENE := "res://scenes/menus/main_menu.tscn"

# ── Leveling ──────────────────────────────────────────────────────────────────

const XP_TABLE: Array[int] = [0, 100, 250, 450, 700, 1000, 1400, 1900, 2500, 3200]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	_tick_cooldowns(delta)


func _tick_cooldowns(delta: float) -> void:
	for i in spell_cooldowns.size():
		if spell_cooldowns[i] > 0.0:
			spell_cooldowns[i] = maxf(0.0, spell_cooldowns[i] - delta)

# ── Damage / Healing ──────────────────────────────────────────────────────────

func take_damage(amount: float) -> void:
	if has_shield:
		amount *= (1.0 - shield_reduction)
	current_health = maxf(0.0, current_health - amount)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		player_died.emit()


func heal(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func use_mana(amount: float) -> bool:
	if current_mana < amount:
		return false
	current_mana -= amount
	mana_changed.emit(current_mana, max_mana)
	return true


func restore_mana(amount: float) -> void:
	current_mana = minf(max_mana, current_mana + amount)
	mana_changed.emit(current_mana, max_mana)

# ── Spell cooldown helpers ────────────────────────────────────────────────────

func is_spell_ready(index: int) -> bool:
	return spell_cooldowns[index] <= 0.0


func trigger_cooldown(index: int) -> void:
	spell_cooldowns[index] = spell_max_cooldowns[index]


func get_cooldown_fraction(index: int) -> float:
	if spell_max_cooldowns[index] <= 0.0:
		return 0.0
	return spell_cooldowns[index] / spell_max_cooldowns[index]

# ── Experience / Leveling ─────────────────────────────────────────────────────

func gain_experience(amount: int) -> void:
	experience += amount
	experience_gained.emit(amount, experience)
	_check_level_up()


func _check_level_up() -> void:
	var next_threshold := _xp_for_next_level()
	while experience >= next_threshold:
		player_level += 1
		_apply_level_up_bonuses()
		level_up.emit(player_level)
		next_threshold = _xp_for_next_level()


func _xp_for_next_level() -> int:
	if player_level - 1 < XP_TABLE.size():
		return XP_TABLE[player_level - 1]
	return XP_TABLE[-1] + (player_level - XP_TABLE.size()) * 500


func _apply_level_up_bonuses() -> void:
	var bonus_hp := 15.0
	var bonus_mana := 10.0
	max_health += bonus_hp
	current_health = minf(current_health + bonus_hp * 0.5, max_health)
	max_mana += bonus_mana
	current_mana = minf(current_mana + bonus_mana * 0.5, max_mana)
	spell_power += 0.1
	base_damage += 2.0
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)


func get_xp_fraction() -> float:
	var prev := _xp_for_prev_level()
	var next := _xp_for_next_level()
	if next == prev:
		return 1.0
	return float(experience - prev) / float(next - prev)


func _xp_for_prev_level() -> int:
	if player_level - 2 >= 0 and player_level - 2 < XP_TABLE.size():
		return XP_TABLE[player_level - 2]
	return 0

# ── Scene management ──────────────────────────────────────────────────────────

func start_new_game() -> void:
	_reset_stats()
	is_in_game = true
	SaveSystem.delete_save()
	get_tree().change_scene_to_file(GAME_SCENE)


func continue_game() -> void:
	if SaveSystem.save_exists():
		is_in_game = true
		get_tree().change_scene_to_file(GAME_SCENE)


func go_to_main_menu() -> void:
	is_in_game = false
	is_paused = false
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _reset_stats() -> void:
	player_level = 1
	experience = 0
	max_health = 100.0
	current_health = 100.0
	max_mana = 80.0
	current_mana = 80.0
	base_damage = 10.0
	spell_power = 1.0
	has_shield = false
	spell_cooldowns = [0.0, 0.0, 0.0, 0.0]

# ── Pause ─────────────────────────────────────────────────────────────────────

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	game_paused.emit(is_paused)


func set_pause(value: bool) -> void:
	is_paused = value
	get_tree().paused = value
	game_paused.emit(value)
