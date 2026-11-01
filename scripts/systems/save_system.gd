extends Node
## Save / load system – autoloaded as SaveSystem.
## Handles both game saves and settings using Godot's ConfigFile.

const SAVE_PATH := "user://save_game.cfg"
const SETTINGS_PATH := "user://settings.cfg"


# ── Settings ──────────────────────────────────────────────────────────────────

func save_settings(cfg: ConfigFile) -> void:
	cfg.save(SETTINGS_PATH)


func load_config() -> ConfigFile:
	var cfg := ConfigFile.new()
	if FileAccess.file_exists(SETTINGS_PATH):
		cfg.load(SETTINGS_PATH)
	return cfg


func save_current_settings(master_vol: float, music_vol: float, sfx_vol: float,
		cam_sensitivity: float, fullscreen: bool, shadow_quality: int,
		graphics_quality: int) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "master", master_vol)
	cfg.set_value("audio", "music", music_vol)
	cfg.set_value("audio", "sfx", sfx_vol)
	cfg.set_value("controls", "camera_sensitivity", cam_sensitivity)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("display", "shadow_quality", shadow_quality)
	cfg.set_value("display", "graphics_quality", graphics_quality)
	cfg.save(SETTINGS_PATH)


# ── Game save ─────────────────────────────────────────────────────────────────

func save_game() -> void:
	var gm := GameManager
	var player := gm.player_node

	var cfg := ConfigFile.new()
	cfg.set_value("player", "level", gm.player_level)
	cfg.set_value("player", "experience", gm.experience)
	cfg.set_value("player", "health", gm.current_health)
	cfg.set_value("player", "max_health", gm.max_health)
	cfg.set_value("player", "mana", gm.current_mana)
	cfg.set_value("player", "max_mana", gm.max_mana)
	cfg.set_value("player", "base_damage", gm.base_damage)
	cfg.set_value("player", "spell_power", gm.spell_power)

	if is_instance_valid(player):
		var pos := player.global_position
		cfg.set_value("world", "pos_x", pos.x)
		cfg.set_value("world", "pos_y", pos.y)
		cfg.set_value("world", "pos_z", pos.z)

	cfg.save(SAVE_PATH)


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return false

	var gm := GameManager
	gm.player_level = cfg.get_value("player", "level", 1)
	gm.experience = cfg.get_value("player", "experience", 0)
	gm.current_health = cfg.get_value("player", "health", 100.0)
	gm.max_health = cfg.get_value("player", "max_health", 100.0)
	gm.current_mana = cfg.get_value("player", "mana", 80.0)
	gm.max_mana = cfg.get_value("player", "max_mana", 80.0)
	gm.base_damage = cfg.get_value("player", "base_damage", 10.0)
	gm.spell_power = cfg.get_value("player", "spell_power", 1.0)

	return true


func get_saved_position() -> Vector3:
	if not FileAccess.file_exists(SAVE_PATH):
		return Vector3.ZERO
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return Vector3.ZERO
	return Vector3(
		cfg.get_value("world", "pos_x", 0.0),
		cfg.get_value("world", "pos_y", 2.0),
		cfg.get_value("world", "pos_z", 0.0)
	)


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
