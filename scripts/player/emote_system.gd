extends Node
class_name EmoteSystem

## Shows emoji bubbles above the player

var emotes: Dictionary = {
	"emote_1": "👋",
	"emote_2": "❤️",
	"emote_3": "😂",
	"emote_4": "❓"
}

var player: Node2D
var emote_label: Label
var fade_tween: Tween

func _init(p: Node2D) -> void:
	player = p

func _ready() -> void:
	emote_label = Label.new()
	emote_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emote_label.position = Vector2(-8, -28)
	emote_label.z_index = 10
	emote_label.visible = false
	emote_label.add_theme_font_size_override("font_size", 10)
	player.add_child(emote_label)

func show_emote(emote_key: String) -> void:
	if emote_key not in emotes:
		return
	emote_label.text = emotes[emote_key]
	emote_label.visible = true
	emote_label.modulate = Color.WHITE

	if fade_tween:
		fade_tween.kill()
	fade_tween = player.create_tween()
	fade_tween.tween_interval(1.5)
	fade_tween.tween_property(emote_label, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(func(): emote_label.visible = false)

func check_input() -> void:
	for key in emotes:
		if Input.is_action_just_pressed(key):
			show_emote(key)
			break
