extends CanvasLayer

@onready var map_label: Label = $MapLabel
@onready var player_label: Label = $PlayerLabel
@onready var chat_container: VBoxContainer = $ChatContainer
@onready var chat_input: LineEdit = $ChatContainer/ChatInput
@onready var chat_log: RichTextLabel = $ChatContainer/ChatLog

var chat_visible: bool = false

func _ready() -> void:
	chat_container.visible = false
	chat_input.visible = false
	map_label.text = "Starting Town"
	player_label.text = GameManager.player_username

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("chat"):
		if not chat_visible:
			chat_visible = true
			chat_container.visible = true
			chat_input.visible = true
			chat_input.grab_focus()
			get_viewport().set_input_as_handled()
		elif chat_input.has_focus():
			_send_chat()
			get_viewport().set_input_as_handled()

func _send_chat() -> void:
	var text := chat_input.text.strip_edges()
	if text != "":
		add_chat_message(GameManager.player_username, text)
		# TODO: send via SpacetimeDB
	chat_input.text = ""
	chat_input.release_focus()
	chat_visible = false
	chat_container.visible = false
	chat_input.visible = false

func add_chat_message(username: String, message: String) -> void:
	chat_log.append_text("[b]%s:[/b] %s\n" % [username, message])

func set_map_name(map_name: String) -> void:
	map_label.text = map_name
