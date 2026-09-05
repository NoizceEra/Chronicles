# network_manager.gd
# Autoload singleton ("Network") — Chronicles of Midgard real multiplayer foundation.
# Godot 4 high-level multiplayer (ENetMultiplayerPeer). One host acts as the
# authoritative server; every other participant is a client peer. Supports up
# to MAX_PLAYERS concurrent connections on one shared world.
extends Node

const PORT: int = 7777
const MAX_PLAYERS: int = 100

signal player_registered(peer_id: int, info: Dictionary)
signal player_removed(peer_id: int)
signal player_list_changed
signal connection_failed_signal(reason: String)
signal connected_to_server

# peer_id -> {"name": String, "class_id": String}
var players: Dictionary = {}

var local_name: String = "Adventurer"
var local_class_id: String = "knight"

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func host_game(player_name: String, class_id: String, port: int = PORT) -> bool:
	local_name = player_name
	local_class_id = class_id

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(port, MAX_PLAYERS)
	if err != OK:
		emit_signal("connection_failed_signal", "Could not start server (error %d). Is the port already in use?" % err)
		return false

	multiplayer.multiplayer_peer = peer
	# The host is always peer id 1 and is its own "player_connected" event.
	players[1] = {"name": player_name, "class_id": class_id}
	emit_signal("player_registered", 1, players[1])
	emit_signal("player_list_changed")
	return true

func join_game(address: String, player_name: String, class_id: String, port: int = PORT) -> bool:
	local_name = player_name
	local_class_id = class_id

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(address, port)
	if err != OK:
		emit_signal("connection_failed_signal", "Could not reach %s:%d (error %d)." % [address, port, err])
		return false

	multiplayer.multiplayer_peer = peer
	return true

func leave_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	players.clear()

func _on_peer_connected(peer_id: int) -> void:
	if multiplayer.is_server():
		# Ask the new peer who they are; they'll call register_player back.
		pass

func _on_peer_disconnected(peer_id: int) -> void:
	if players.has(peer_id):
		players.erase(peer_id)
	emit_signal("player_removed", peer_id)
	emit_signal("player_list_changed")

func _on_connected_to_server() -> void:
	# Tell the server who we are; it will broadcast back the full roster.
	rpc_id(1, "register_player", local_name, local_class_id)
	emit_signal("connected_to_server")

func _on_connection_failed() -> void:
	emit_signal("connection_failed_signal", "Failed to connect to the host.")

func _on_server_disconnected() -> void:
	emit_signal("connection_failed_signal", "Lost connection to the host.")
	players.clear()

## Called by a joining client on the server (rpc_id(1, ...)).
@rpc("any_peer", "reliable")
func register_player(player_name: String, class_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	players[sender_id] = {"name": player_name, "class_id": class_id}
	emit_signal("player_registered", sender_id, players[sender_id])
	emit_signal("player_list_changed")
	# Send the full roster to everyone so late joiners see who's already here.
	_broadcast_roster()

@rpc("authority", "reliable")
func _receive_roster(roster: Dictionary) -> void:
	players = roster.duplicate(true)
	emit_signal("player_list_changed")

func _broadcast_roster() -> void:
	if multiplayer.is_server():
		rpc("_receive_roster", players)

func get_local_peer_id() -> int:
	return multiplayer.get_unique_id()

func is_host() -> bool:
	return multiplayer.multiplayer_peer != null and multiplayer.is_server()
