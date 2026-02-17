extends Control

@onready var username_input: LineEdit = $VBoxContainer/UsernameInput
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var sprite_selector: HBoxContainer = $VBoxContainer/SpriteSelector
@onready var char_preview: Sprite2D = $VBoxContainer/PreviewContainer/CharPreview
@onready var anim_timer: Timer = $AnimTimer

var selected_sprite: int = 0
var preview_walk_index: int = 0
var walk_cycle: Array[int] = [0, 1, 0, 2]
var preview_direction: int = 0  # cycles through directions

var variant_names: Array[String] = ["Blue", "Red", "Green", "Yellow"]
var variant_colors: Array[Color] = [
	Color(0.3, 0.5, 0.9),
	Color(0.9, 0.3, 0.3),
	Color(0.3, 0.75, 0.4),
	Color(0.9, 0.8, 0.2),
]

func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	anim_timer.timeout.connect(_on_anim_tick)
	_setup_sprite_selector()
	_update_preview()

func _setup_sprite_selector() -> void:
	for i in range(4):
		var btn := Button.new()
		btn.text = variant_names[i]
		btn.custom_minimum_size = Vector2(40, 28)
		var style := StyleBoxFlat.new()
		style.bg_color = variant_colors[i]
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("normal", style)
		var hover_style := StyleBoxFlat.new()
		hover_style.bg_color = variant_colors[i].lightened(0.3)
		hover_style.corner_radius_top_left = 4
		hover_style.corner_radius_top_right = 4
		hover_style.corner_radius_bottom_left = 4
		hover_style.corner_radius_bottom_right = 4
		btn.add_theme_stylebox_override("hover", hover_style)
		btn.pressed.connect(_on_sprite_selected.bind(i))
		sprite_selector.add_child(btn)

func _on_sprite_selected(index: int) -> void:
	selected_sprite = index
	_update_preview()

func _on_anim_tick() -> void:
	preview_walk_index = (preview_walk_index + 1) % walk_cycle.size()
	# Change direction every full walk cycle
	if preview_walk_index == 0:
		preview_direction = (preview_direction + 1) % 4
	_update_preview()

func _update_preview() -> void:
	var row := selected_sprite * 4 + preview_direction
	var col := walk_cycle[preview_walk_index]
	char_preview.frame = row * 3 + col

func _on_start_pressed() -> void:
	var username := username_input.text.strip_edges()
	if username == "":
		username = "Trainer"
	GameManager.set_player_info(username, selected_sprite)
	GameManager.go_to_scene("res://scenes/main.tscn")
