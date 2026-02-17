extends Interactable
class_name NPC

@export var npc_name: String = "NPC"
@export var dialog_lines: PackedStringArray = []
@export var sprite_variant: int = 1  # Different from player default
@export var facing_direction: int = 0  # 0=down, 1=up, 2=left, 3=right

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	interaction_hint = "Z - Talk"
	if sprite:
		_update_sprite_frame()

func interact(player: Node2D) -> void:
	# Face toward the player
	var dir_to_player := player.global_position - global_position
	if abs(dir_to_player.x) > abs(dir_to_player.y):
		facing_direction = 3 if dir_to_player.x > 0 else 2
	else:
		facing_direction = 0 if dir_to_player.y > 0 else 1
	_update_sprite_frame()

	var dialog = GameManager.get_dialog_box()
	if dialog and dialog_lines.size() > 0:
		var lines: Array[String] = []
		for line in dialog_lines:
			lines.append(line)
		dialog.show_dialog(npc_name, lines)

func _update_sprite_frame() -> void:
	if sprite:
		var row := sprite_variant * 4 + facing_direction
		sprite.frame = row * 3  # Standing frame (col 0)
