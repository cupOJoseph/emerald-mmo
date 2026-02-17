extends CharacterBody2D

## Pokemon Emerald-style grid movement controller with sprite animation

signal movement_completed(new_position: Vector2, direction: int)

const TILE_SIZE: int = 16
const WALK_SPEED: float = 4.0
const RUN_SPEED: float = 8.0
const ANIM_SPEED: float = 8.0  # frames per second

enum Direction { DOWN = 0, UP = 1, LEFT = 2, RIGHT = 3 }

var current_direction: int = Direction.DOWN
var is_moving: bool = false
var target_position: Vector2 = Vector2.ZERO
var sprite_variant: int = 0  # 0=blue, 1=red, 2=green, 3=yellow
var anim_timer: float = 0.0
var anim_frame: int = 0  # 0=stand, 1=step_left, 2=step_right
var walk_cycle: Array[int] = [0, 1, 0, 2]  # stand, left, stand, right
var walk_index: int = 0

# Systems
var interaction_system: InteractionSystem
var emote_system: EmoteSystem

@onready var sprite: Sprite2D = $Sprite2D
@onready var ray: RayCast2D = $RayCast2D
@onready var name_label: Label = $NameLabel
@onready var camera: Camera2D = $Camera2D
@onready var interact_ray: RayCast2D = $InteractRay

var tween: Tween = null

func _ready() -> void:
	target_position = position
	if GameManager.player_username != "":
		name_label.text = GameManager.player_username
	sprite_variant = GameManager.player_sprite_id
	_update_sprite_frame()
	GameManager.player_node = self

	# Set up interaction system
	interaction_system = InteractionSystem.new(self, interact_ray)
	add_child(interaction_system)

	# Set up emote system
	emote_system = EmoteSystem.new(self)
	add_child(emote_system)
	emote_system._ready()

	# Set collision layer for warp detection
	collision_layer = 2
	collision_mask = 1

	# Update interact ray direction
	_update_interact_ray()

func _physics_process(delta: float) -> void:
	if is_moving:
		# Animate walk cycle
		anim_timer += delta
		if anim_timer >= 1.0 / ANIM_SPEED:
			anim_timer = 0.0
			walk_index = (walk_index + 1) % walk_cycle.size()
			anim_frame = walk_cycle[walk_index]
			_update_sprite_frame()
		return

	# Reset to standing frame
	if anim_frame != 0:
		anim_frame = 0
		walk_index = 0
		_update_sprite_frame()

	# Check for blocked input
	if GameManager.is_input_blocked():
		return

	# Emotes
	emote_system.check_input()

	# Interaction
	if Input.is_action_just_pressed("interact"):
		if interaction_system.try_interact():
			return

	var input_dir := _get_input_direction()
	if input_dir != Vector2i.ZERO:
		_try_move(input_dir)

	# Update hint based on what's in front
	_update_interaction_hint()

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
	if input == Vector2i(0, -1): return Direction.UP
	elif input == Vector2i(0, 1): return Direction.DOWN
	elif input == Vector2i(-1, 0): return Direction.LEFT
	elif input == Vector2i(1, 0): return Direction.RIGHT
	return current_direction

func _try_move(input_dir: Vector2i) -> void:
	current_direction = _direction_from_input(input_dir)
	_update_sprite_frame()
	_update_interact_ray()

	ray.target_position = Vector2(input_dir) * TILE_SIZE
	ray.force_raycast_update()

	if ray.is_colliding():
		return

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

func _update_sprite_frame() -> void:
	# Spritesheet layout: 3 cols (frames) x 16 rows (4 variants x 4 directions)
	var row := sprite_variant * 4 + current_direction
	var col := anim_frame
	sprite.frame = row * 3 + col

func _update_interact_ray() -> void:
	if not interact_ray:
		return
	match current_direction:
		Direction.DOWN:
			interact_ray.target_position = Vector2(0, TILE_SIZE)
		Direction.UP:
			interact_ray.target_position = Vector2(0, -TILE_SIZE)
		Direction.LEFT:
			interact_ray.target_position = Vector2(-TILE_SIZE, 0)
		Direction.RIGHT:
			interact_ray.target_position = Vector2(TILE_SIZE, 0)

func _update_interaction_hint() -> void:
	var interactable := interaction_system.check_facing()
	var hud := _get_hud()
	if hud and hud.has_method("set_context_hint"):
		if interactable:
			hud.set_context_hint(interactable.get_interaction_hint())
		else:
			hud.set_context_hint("")

func _get_hud() -> Node:
	var nodes = get_tree().get_nodes_in_group("hud")
	if nodes.size() > 0:
		return nodes[0]
	return null

func set_player_name(username: String) -> void:
	name_label.text = username

func set_sprite_variant(variant: int) -> void:
	sprite_variant = variant
	_update_sprite_frame()
