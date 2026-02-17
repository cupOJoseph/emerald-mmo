extends CanvasLayer
class_name GameMenu

@onready var overlay: ColorRect = $Overlay
@onready var menu_panel: PanelContainer = $MenuPanel
@onready var items_container: VBoxContainer = $MenuPanel/VBox

var menu_items: Array[String] = ["Player", "Inventory", "Map", "Settings", "Save", "Exit"]
var selected_index: int = 0
var is_open: bool = false
var item_labels: Array[Label] = []

func _ready() -> void:
	overlay.visible = false
	menu_panel.visible = false
	_build_menu()

func _build_menu() -> void:
	for child in items_container.get_children():
		child.queue_free()
	item_labels.clear()
	for item_name in menu_items:
		var label := Label.new()
		label.text = "  " + item_name
		label.add_theme_font_size_override("font_size", 8)
		items_container.add_child(label)
		item_labels.append(label)
	_update_selection()

func _update_selection() -> void:
	for i in item_labels.size():
		if i == selected_index:
			item_labels[i].text = "▶ " + menu_items[i]
			item_labels[i].modulate = Color.YELLOW
		else:
			item_labels[i].text = "  " + menu_items[i]
			item_labels[i].modulate = Color.WHITE

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	is_open = true
	selected_index = 0
	overlay.visible = true
	menu_panel.visible = true
	GameManager.menu_active = true
	_update_selection()

func close() -> void:
	is_open = false
	overlay.visible = false
	menu_panel.visible = false
	GameManager.menu_active = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_menu"):
		get_viewport().set_input_as_handled()
		toggle()
		return

	if not is_open:
		return

	if event.is_action_pressed("move_up"):
		get_viewport().set_input_as_handled()
		selected_index = (selected_index - 1 + menu_items.size()) % menu_items.size()
		_update_selection()
	elif event.is_action_pressed("move_down"):
		get_viewport().set_input_as_handled()
		selected_index = (selected_index + 1) % menu_items.size()
		_update_selection()
	elif event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_select_item(selected_index)
	elif event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		close()

func _select_item(index: int) -> void:
	match menu_items[index]:
		"Player":
			pass  # TODO: show player stats
		"Inventory":
			close()
			# Toggle inventory via input simulation
		"Map":
			pass  # TODO: show map
		"Settings":
			pass  # TODO
		"Save":
			pass  # SpacetimeDB auto-saves
		"Exit":
			close()
			GameManager.go_to_scene("res://scenes/ui/login_screen.tscn")
