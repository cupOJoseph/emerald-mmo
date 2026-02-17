extends CanvasLayer

@onready var map_label: Label = $MapLabel
@onready var player_label: Label = $PlayerLabel
@onready var chat_container: VBoxContainer = $ChatContainer
@onready var chat_input: LineEdit = $ChatContainer/ChatInput
@onready var chat_log: RichTextLabel = $ChatContainer/ChatLog
@onready var gold_display: Label = $GoldDisplay
@onready var hints_label: Label = $HintsLabel
@onready var context_hint: Label = $ContextHint

var chat_visible: bool = false

func _ready() -> void:
	add_to_group("hud")
	chat_container.visible = false
	chat_input.visible = false
	var map_name: String = GameManager.map_names.get(GameManager.current_map_id, "Unknown")
	map_label.text = map_name
	player_label.text = GameManager.player_username
	context_hint.text = ""
	context_hint.modulate.a = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("chat"):
		if GameManager.is_input_blocked():
			return
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

func set_gold(amount: int) -> void:
	gold_display.text = "Gold: %d" % amount

func set_context_hint(hint: String) -> void:
	if hint == "":
		if context_hint.modulate.a > 0:
			var tw := create_tween()
			tw.tween_property(context_hint, "modulate:a", 0.0, 0.2)
	else:
		context_hint.text = hint
		if context_hint.modulate.a < 1:
			var tw := create_tween()
			tw.tween_property(context_hint, "modulate:a", 1.0, 0.2)
