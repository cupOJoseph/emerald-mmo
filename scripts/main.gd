extends Node2D

@onready var town: Node2D = $TownStart
@onready var player: CharacterBody2D = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	# Position player at spawn
	player.position = GameManager.spawn_position
	if GameManager.player_username != "":
		player.set_player_name(GameManager.player_username)
