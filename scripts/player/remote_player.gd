extends Node2D

## Remote player with sprite animation

const INTERPOLATION_SPEED: float = 10.0
const ANIM_SPEED: float = 8.0

var target_pos: Vector2 = Vector2.ZERO
var current_direction: int = 0
var is_moving: bool = false
var player_username: String = ""
var sprite_variant: int = 0
var anim_timer: float = 0.0
var walk_cycle: Array[int] = [0, 1, 0, 2]
var walk_index: int = 0
var anim_frame: int = 0

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $NameLabel

func _ready() -> void:
	target_pos = position
	name_label.text = player_username
	_update_sprite_frame()

func _process(delta: float) -> void:
	if position.distance_to(target_pos) > 0.5:
		position = position.lerp(target_pos, INTERPOLATION_SPEED * delta)
		is_moving = true
		anim_timer += delta
		if anim_timer >= 1.0 / ANIM_SPEED:
			anim_timer = 0.0
			walk_index = (walk_index + 1) % walk_cycle.size()
			anim_frame = walk_cycle[walk_index]
			_update_sprite_frame()
	else:
		position = target_pos
		if is_moving:
			is_moving = false
			anim_frame = 0
			walk_index = 0
			_update_sprite_frame()

func _update_sprite_frame() -> void:
	var row := sprite_variant * 4 + current_direction
	sprite.frame = row * 3 + anim_frame

func update_remote_state(new_pos: Vector2, direction: int, moving: bool) -> void:
	target_pos = new_pos
	current_direction = direction
	_update_sprite_frame()

func set_player_name(username: String) -> void:
	player_username = username
	if name_label:
		name_label.text = username

func set_sprite_variant(variant: int) -> void:
	sprite_variant = variant
	_update_sprite_frame()
