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

# UI state flags
var dialog_active: bool = false
var menu_active: bool = false
var transitioning: bool = false

# Map registry
var map_scenes: Dictionary = {
	"town_start": "res://scenes/world/town_start.tscn",
	"route_1": "res://scenes/world/route_1.tscn"
}

var map_names: Dictionary = {
	"town_start": "Emerald Town",
	"route_1": "Route 1"
}

# Dialog box reference
var _dialog_box: Node = null

func _ready() -> void:
	print("[GameManager] Ready")

func set_player_info(username: String, sprite_id: int) -> void:
	player_username = username
	player_sprite_id = sprite_id

func is_input_blocked() -> bool:
	return dialog_active or menu_active or transitioning

func get_dialog_box() -> Node:
	if _dialog_box:
		return _dialog_box
	var nodes := get_tree().get_nodes_in_group("dialog_box")
	if nodes.size() > 0:
		_dialog_box = nodes[0]
		return _dialog_box
	return null

func register_dialog_box(db: Node) -> void:
	_dialog_box = db

func go_to_map(map_id: String, sx: float, sy: float, scene_path: String = "") -> void:
	if transitioning:
		return
	transitioning = true
	current_map_id = map_id
	spawn_position = Vector2(sx, sy)

	var path: String = scene_path if scene_path != "" else str(map_scenes.get(map_id, ""))
	if path == "":
		transitioning = false
		return

	# Fade out
	var canvas := CanvasLayer.new()
	canvas.layer = 100
	var fade := ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.anchors_preset = Control.PRESET_FULL_RECT
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fade)
	get_tree().root.add_child(canvas)

	var tween := create_tween()
	tween.tween_property(fade, "color:a", 1.0, 0.3)
	tween.tween_callback(func():
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		# Fade in after scene loads
		get_tree().create_timer(0.1).timeout.connect(func():
			canvas.queue_free()
			transitioning = false
			map_changed.emit(map_id)
		)
	)

	# TODO: SpacetimeDB change_map reducer call
	#call_change_map_reducer(map_id, sx, sy)

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
