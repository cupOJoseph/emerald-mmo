extends CanvasLayer
class_name DialogBox

## Pokemon-style dialog box with typewriter effect

signal dialog_finished

const CHAR_DELAY: float = 0.03
const FAST_CHAR_DELAY: float = 0.005

@onready var panel: PanelContainer = $Panel
@onready var name_label: Label = $Panel/VBox/NameLabel
@onready var text_label: Label = $Panel/VBox/TextLabel
@onready var indicator: Label = $Panel/VBox/Indicator

var pages: Array[String] = []
var current_page: int = 0
var current_char: int = 0
var full_text: String = ""
var typing: bool = false
var char_timer: float = 0.0
var is_active: bool = false

func _ready() -> void:
	panel.visible = false
	set_process(false)

func show_dialog(speaker: String, lines: Array[String]) -> void:
	if lines.is_empty():
		return
	pages = lines
	current_page = 0
	name_label.text = speaker
	is_active = true
	panel.visible = true
	GameManager.dialog_active = true
	_show_page(0)

func _show_page(index: int) -> void:
	current_page = index
	full_text = pages[index]
	text_label.text = ""
	current_char = 0
	typing = true
	indicator.visible = false
	set_process(true)

func _process(delta: float) -> void:
	if not typing:
		return
	char_timer += delta
	var delay := FAST_CHAR_DELAY if Input.is_action_pressed("interact") else CHAR_DELAY
	while char_timer >= delay and current_char < full_text.length():
		char_timer -= delay
		current_char += 1
		text_label.text = full_text.substr(0, current_char)
	if current_char >= full_text.length():
		typing = false
		text_label.text = full_text
		indicator.visible = true
		indicator.text = "▼" if current_page < pages.size() - 1 else "■"

func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if typing:
			# Skip to end of page
			typing = false
			current_char = full_text.length()
			text_label.text = full_text
			indicator.visible = true
			indicator.text = "▼" if current_page < pages.size() - 1 else "■"
		elif current_page < pages.size() - 1:
			_show_page(current_page + 1)
		else:
			_close()
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_close()

func _close() -> void:
	panel.visible = false
	is_active = false
	typing = false
	set_process(false)
	GameManager.dialog_active = false
	dialog_finished.emit()
