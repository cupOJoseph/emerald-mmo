extends Node2D

## Remote player - smooth interpolation of other players

const INTERPOLATION_SPEED: float = 10.0

var target_pos: Vector2 = Vector2.ZERO
var current_direction: int = 0
var is_moving: bool = false
var player_username: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel

func _ready() -> void:
	target_pos = position
	name_label.text = player_username

func _process(delta: float) -> void:
	if position.distance_to(target_pos) > 0.5:
		position = position.lerp(target_pos, INTERPOLATION_SPEED * delta)
		is_moving = true
	else:
		position = target_pos
		is_moving = false

func update_remote_state(new_pos: Vector2, direction: int, moving: bool) -> void:
	target_pos = new_pos
	current_direction = direction
	is_moving = moving

func set_player_name(username: String) -> void:
	player_username = username
	if name_label:
		name_label.text = username
