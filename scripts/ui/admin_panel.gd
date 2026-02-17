extends Control

signal create_item_requested(data: Dictionary)
signal give_gold_requested(player_id: int, amount: int)
signal spawn_item_requested(player_id: int, item_def_id: int, quantity: int)

@onready var items_tab: Button = $Panel/TabBar/ItemsTab
@onready var players_tab: Button = $Panel/TabBar/PlayersTab
@onready var item_creator: VBoxContainer = $Panel/ItemCreator
@onready var player_panel: VBoxContainer = $Panel/PlayerPanel
@onready var close_btn: Button = $Panel/CloseBtn

# Item creator fields
@onready var name_input: LineEdit = $Panel/ItemCreator/NameInput
@onready var desc_input: LineEdit = $Panel/ItemCreator/DescInput
@onready var type_option: OptionButton = $Panel/ItemCreator/Row1/TypeOption
@onready var rarity_option: OptionButton = $Panel/ItemCreator/Row1/RarityOption
@onready var stack_check: CheckBox = $Panel/ItemCreator/Row2/StackCheck
@onready var max_stack: SpinBox = $Panel/ItemCreator/Row2/MaxStack
@onready var value_input: SpinBox = $Panel/ItemCreator/Row3/ValueInput
@onready var icon_input: SpinBox = $Panel/ItemCreator/Row3/IconInput
@onready var create_btn: Button = $Panel/ItemCreator/CreateBtn

# Player panel fields
@onready var search_input: LineEdit = $Panel/PlayerPanel/SearchInput
@onready var player_list: ItemList = $Panel/PlayerPanel/PlayerList
@onready var gold_amount: SpinBox = $Panel/PlayerPanel/ActionRow/GoldAmount
@onready var give_gold_btn: Button = $Panel/PlayerPanel/ActionRow/GiveGoldBtn
@onready var item_id_input: SpinBox = $Panel/PlayerPanel/SpawnRow/ItemId
@onready var item_qty_input: SpinBox = $Panel/PlayerPanel/SpawnRow/ItemQty
@onready var spawn_btn: Button = $Panel/PlayerPanel/SpawnRow/SpawnBtn

var players: Array = []

func _ready() -> void:
	visible = false
	items_tab.pressed.connect(_show_items)
	players_tab.pressed.connect(_show_players)
	close_btn.pressed.connect(func(): visible = false)
	create_btn.pressed.connect(_on_create_item)
	give_gold_btn.pressed.connect(_on_give_gold)
	spawn_btn.pressed.connect(_on_spawn_item)

	# Populate dropdowns
	for t in ["consumable", "equipment", "key", "material", "currency"]:
		type_option.add_item(t)
	for r in ["Common", "Uncommon", "Rare", "Epic", "Legendary"]:
		rarity_option.add_item(r)

func _show_items() -> void:
	item_creator.visible = true
	player_panel.visible = false
	items_tab.button_pressed = true
	players_tab.button_pressed = false

func _show_players() -> void:
	item_creator.visible = false
	player_panel.visible = true
	players_tab.button_pressed = true
	items_tab.button_pressed = false
	_refresh_players()

func _refresh_players() -> void:
	player_list.clear()
	var query := search_input.text.to_lower()
	for p in players:
		var name: String = p.get("username", "")
		if query.is_empty() or query in name.to_lower():
			player_list.add_item("%s (id:%d) %s" % [name, p.get("id", 0), "●" if p.get("online", false) else "○"])

func _on_create_item() -> void:
	var data := {
		"name": name_input.text,
		"description": desc_input.text,
		"item_type": type_option.get_item_text(type_option.selected),
		"rarity": rarity_option.selected,
		"stackable": stack_check.button_pressed,
		"max_stack": int(max_stack.value),
		"value": int(value_input.value),
		"icon_id": int(icon_input.value),
	}
	create_item_requested.emit(data)
	name_input.text = ""
	desc_input.text = ""

func _get_selected_player_id() -> int:
	var sel := player_list.get_selected_items()
	if sel.is_empty():
		return -1
	var text: String = player_list.get_item_text(sel[0])
	# Parse "name (id:123) ●"
	var start := text.find("id:") + 3
	var end := text.find(")", start)
	if start > 2 and end > start:
		return text.substr(start, end - start).to_int()
	return -1

func _on_give_gold() -> void:
	var pid := _get_selected_player_id()
	if pid < 0:
		return
	give_gold_requested.emit(pid, int(gold_amount.value))

func _on_spawn_item() -> void:
	var pid := _get_selected_player_id()
	if pid < 0:
		return
	spawn_item_requested.emit(pid, int(item_id_input.value), int(item_qty_input.value))

func set_players(p: Array) -> void:
	players = p
	if visible and player_panel.visible:
		_refresh_players()

func toggle() -> void:
	visible = !visible
