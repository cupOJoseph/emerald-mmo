extends Area2D
class_name WarpZone

## Warp zone that transitions player to another map

@export var target_map: String = ""  # e.g. "town_start" or "route_1"
@export var target_scene: String = ""  # e.g. "res://scenes/world/route_1.tscn"
@export var spawn_x: float = 0.0
@export var spawn_y: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 0
	collision_mask = 2  # Player layer

func _on_body_entered(body: Node2D) -> void:
	if body == GameManager.player_node:
		GameManager.go_to_map(target_map, spawn_x, spawn_y, target_scene)
