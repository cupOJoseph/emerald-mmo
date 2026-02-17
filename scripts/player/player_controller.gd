extends CharacterBody2D

## Pokemon Emerald-style grid movement controller

signal movement_completed(new_position: Vector2, direction: int)

const TILE_SIZE: int = 16
const WALK_SPEED: float = 4.0  # tiles per second
const RUN_SPEED: float = 8.0   # tiles per second

enum Direction { DOWN = 0, UP = 1, LEFT = 2, RIGHT = 3 }

var current_direction: int = Direction.DOWN
var is_moving: bool = false
var input_buffered: Vector2i = Vector2i.ZERO
var target_position: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D
@onready var ray: RayCast2D = $RayCast2D
@onready var name_label: Label = $NameLabel
@onready var camera: Camera2D = $Camera2D

var tween: Tween = null

func _ready() -> void:
	target_position = position
	if GameManager.player_username != "":
		name_label.text = GameManager.player_username
	GameManager.player_node = self

func _physics_process(_delta: float) -> void:
	if is_moving:
		return

	var input_dir := _get_input_direction()
	if input_dir != Vector2i.ZERO:
		_try_move(input_dir)

func _get_input_direction() -> Vector2i:
	if Input.is_action_pressed("move_up"):
		return Vector2i(0, -1)
	elif Input.is_action_pressed("move_down"):
		return Vector2i(0, 1)
	elif Input.is_action_pressed("move_left"):
		return Vector2i(-1, 0)
	elif Input.is_action_pressed("move_right"):
		return Vector2i(1, 0)
	return Vector2i.ZERO

func _direction_from_input(input: Vector2i) -> int:
	if input == Vector2i(0, -1):
		return Direction.UP
	elif input == Vector2i(0, 1):
		return Direction.DOWN
	elif input == Vector2i(-1, 0):
		return Direction.LEFT
	elif input == Vector2i(1, 0):
		return Direction.RIGHT
	return current_direction

func _try_move(input_dir: Vector2i) -> void:
	current_direction = _direction_from_input(input_dir)
	_update_sprite_direction()

	# Check collision with raycast
	ray.target_position = Vector2(input_dir) * TILE_SIZE
	ray.force_raycast_update()

	if ray.is_colliding():
		return

	# Start movement tween
	is_moving = true
	target_position = position + Vector2(input_dir) * TILE_SIZE

	var is_running := Input.is_action_pressed("run")
	var speed := RUN_SPEED if is_running else WALK_SPEED
	var duration := 1.0 / speed

	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "position", target_position, duration)
	tween.tween_callback(_on_movement_finished)

func _on_movement_finished() -> void:
	is_moving = false
	position = target_position.snapped(Vector2(TILE_SIZE, TILE_SIZE))
	movement_completed.emit(position, current_direction)

func _update_sprite_direction() -> void:
	# Update sprite color/appearance based on direction
	# With real sprites, this would change animation frame
	match current_direction:
		Direction.DOWN:
			sprite.modulate = Color(0.3, 0.6, 1.0)
		Direction.UP:
			sprite.modulate = Color(0.3, 0.8, 1.0)
		Direction.LEFT:
			sprite.modulate = Color(0.2, 0.5, 0.9)
		Direction.RIGHT:
			sprite.modulate = Color(0.4, 0.7, 1.0)

func set_player_name(username: String) -> void:
	name_label.text = username
