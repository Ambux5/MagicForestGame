extends Node
## Audio management singleton – autoloaded as AudioManager.
## Manages BGM, SFX players, and volume settings.
## Actual audio files can be placed in assets/audio/ and registered below.

var master_volume: float = 1.0
var music_volume: float = 0.7
var sfx_volume: float = 1.0

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 6

var _audio_streams: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)

	_setup_buses()
	_load_settings()
	_register_streams()


func _setup_buses() -> void:
	# Ensure Music and SFX buses exist (fallback if project doesn't define them)
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "Music")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, "SFX")
	apply_volumes()


func _register_streams() -> void:
	# Register audio file paths here when assets are available.
	# Example: _audio_streams["forest_ambience"] = load("res://assets/audio/forest_ambience.ogg")
	pass


func play_music(name: String) -> void:
	if not _audio_streams.has(name):
		return
	_music_player.stream = _audio_streams[name]
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()


func play_sfx(name: String) -> void:
	if not _audio_streams.has(name):
		return
	var player := _get_free_sfx_player()
	if player:
		player.stream = _audio_streams[name]
		player.play()


func _get_free_sfx_player() -> AudioStreamPlayer:
	for p in _sfx_players:
		if not p.playing:
			return p
	return _sfx_players[0]


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_volumes()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	apply_volumes()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	apply_volumes()


func apply_volumes() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),
		linear_to_db(master_volume))
	var music_idx := AudioServer.get_bus_index("Music")
	if music_idx != -1:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(music_volume))
	var sfx_idx := AudioServer.get_bus_index("SFX")
	if sfx_idx != -1:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(sfx_volume))


func _load_settings() -> void:
	var cfg := SaveSystem.load_config() if SaveSystem else ConfigFile.new()
	master_volume = cfg.get_value("audio", "master", 1.0)
	music_volume = cfg.get_value("audio", "music", 0.7)
	sfx_volume = cfg.get_value("audio", "sfx", 1.0)
	apply_volumes()
