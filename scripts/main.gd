extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD
@onready var dialog_box: DialogBox = $DialogBox
@onready var game_menu: GameMenu = $GameMenu

var current_map: Node2D = null

func _ready() -> void:
	# Register dialog box
	GameManager.register_dialog_box(dialog_box)

	# Load the current map
	_load_map(GameManager.current_map_id)

	# Position player at spawn
	player.position = GameManager.spawn_position
	if GameManager.player_username != "":
		player.set_player_name(GameManager.player_username)

func _load_map(map_id: String) -> void:
	# Remove old map
	if current_map:
		current_map.queue_free()
		current_map = null

	var scene_path: String = GameManager.map_scenes.get(map_id, "")
	if scene_path == "":
		return
	var scene := load(scene_path)
	if scene:
		current_map = scene.instantiate()
		add_child(current_map)
		move_child(current_map, 0)  # Behind player
