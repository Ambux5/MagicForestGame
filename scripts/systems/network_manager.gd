extends Node
## LAN multiplayer manager – autoloaded as NetworkManager.
## Creates / joins ENet sessions, tracks player names, signals game events.

signal server_created
signal connected_to_server
signal connection_failed
signal peer_joined(peer_id: int, player_name: String)
signal peer_left(peer_id: int)
signal game_starting

const DEFAULT_PORT := 7777
const MAX_CLIENTS  := 3   # server + 3 clients = 4 players max

var local_player_name: String = "Wizard"
var players:  Dictionary = {}   # peer_id (int) → player_name (String)
var is_host:  bool = false
var is_active: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_connected.connect(_on_mp_peer_connected)
	multiplayer.peer_disconnected.connect(_on_mp_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_mp_connected)
	multiplayer.connection_failed.connect(_on_mp_failed)
	multiplayer.server_disconnected.connect(_on_mp_server_disconnected)


# ── Public API ─────────────────────────────────────────────────────────────────

func host_game(port: int, p_name: String) -> Error:
	local_player_name = p_name
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_CLIENTS)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_host   = true
	is_active = true
	players[1] = local_player_name   # server is always peer_id = 1
	server_created.emit()
	return OK


func join_game(ip: String, port: int, p_name: String) -> Error:
	local_player_name = p_name
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, port)
	if err != OK:
		return err
	multiplayer.multiplayer_peer = peer
	is_active = true
	return OK


## Tell all peers to start the game (server only).
func start_game_for_all() -> void:
	if multiplayer.is_server():
		_rpc_start_game.rpc()


func disconnect_network() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	players.clear()
	is_host   = false
	is_active = false


func get_local_peer_id() -> int:
	if not is_active:
		return 1
	return multiplayer.get_unique_id()


# ── Multiplayer callbacks ──────────────────────────────────────────────────────

func _on_mp_peer_connected(_id: int) -> void:
	pass   # server waits for the peer's name registration RPC


func _on_mp_peer_disconnected(id: int) -> void:
	if players.has(id):
		players.erase(id)
	peer_left.emit(id)


func _on_mp_connected() -> void:
	_register_peer.rpc_id(1, multiplayer.get_unique_id(), local_player_name)
	connected_to_server.emit()


func _on_mp_failed() -> void:
	multiplayer.multiplayer_peer = null
	is_active = false
	connection_failed.emit()


func _on_mp_server_disconnected() -> void:
	disconnect_network()


# ── RPCs ───────────────────────────────────────────────────────────────────────

## Client → Server: announce name.
@rpc("any_peer", "reliable")
func _register_peer(peer_id: int, p_name: String) -> void:
	if not multiplayer.is_server():
		return
	players[peer_id] = p_name
	peer_joined.emit(peer_id, p_name)
	_broadcast_players.rpc(players)   # push full list to all peers


## Server → all: sync authoritative player dictionary.
@rpc("authority", "call_local", "reliable")
func _broadcast_players(player_dict: Dictionary) -> void:
	var old_players := players.duplicate()
	players = player_dict
	for pid: int in player_dict:
		if not old_players.has(pid):
			peer_joined.emit(pid, player_dict[pid])


## Server → all: start the game.
@rpc("authority", "call_local", "reliable")
func _rpc_start_game() -> void:
	game_starting.emit()
