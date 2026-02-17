extends Control

@onready var username_input: LineEdit = $VBoxContainer/UsernameInput
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var sprite_selector: HBoxContainer = $VBoxContainer/SpriteSelector

var selected_sprite: int = 0
var sprite_colors: Array[Color] = [
	Color(0.3, 0.6, 1.0),   # Blue
	Color(1.0, 0.3, 0.3),   # Red
	Color(0.3, 0.9, 0.3),   # Green
	Color(0.9, 0.8, 0.2),   # Yellow
]

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	_setup_sprite_selector()

func _setup_sprite_selector() -> void:
	for i in range(4):
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(32, 32)
		var style := StyleBoxFlat.new()
		style.bg_color = sprite_colors[i]
		btn.add_theme_stylebox_override("normal", style)
		btn.pressed.connect(_on_sprite_selected.bind(i))
		sprite_selector.add_child(btn)

func _on_sprite_selected(index: int) -> void:
	selected_sprite = index

func _on_start_pressed() -> void:
	var username := username_input.text.strip_edges()
	if username == "":
		username = "Player"
	GameManager.set_player_info(username, selected_sprite)
	GameManager.go_to_scene("res://scenes/main.tscn")
