extends Node

## Global game state manager

signal player_spawned(player_node: CharacterBody2D)
signal map_changed(map_id: String)
signal player_connected(player_id: int)
signal player_disconnected(player_id: int)

# Current player info
var player_username: String = ""
var player_sprite_id: int = 0
var player_node: CharacterBody2D = null
var current_map_id: String = "town_start"

# Connected players {id: {username, x, y, direction, sprite_id, node}}
var connected_players: Dictionary = {}

# Spawn point for current map
var spawn_position: Vector2 = Vector2(10 * 16, 7 * 16)

func _ready() -> void:
	print("[GameManager] Ready")

func set_player_info(username: String, sprite_id: int) -> void:
	player_username = username
	player_sprite_id = sprite_id

func register_remote_player(id: int, username: String, x: float, y: float, direction: int, sprite_id: int) -> void:
	if id in connected_players:
		return
	connected_players[id] = {
		"username": username,
		"x": x,
		"y": y,
		"direction": direction,
		"sprite_id": sprite_id,
		"node": null
	}
	player_connected.emit(id)

func remove_remote_player(id: int) -> void:
	if id in connected_players:
		var data = connected_players[id]
		if data["node"] != null:
			data["node"].queue_free()
		connected_players.erase(id)
		player_disconnected.emit(id)

func update_remote_player(id: int, x: float, y: float, direction: int, is_moving: bool) -> void:
	if id in connected_players:
		connected_players[id]["x"] = x
		connected_players[id]["y"] = y
		connected_players[id]["direction"] = direction
		var node = connected_players[id]["node"]
		if node != null and node.has_method("update_remote_state"):
			node.update_remote_state(Vector2(x, y), direction, is_moving)

func go_to_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
