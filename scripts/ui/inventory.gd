extends Control

signal item_selected(item_data: Dictionary)
signal item_dropped(item_id: int, quantity: int)
signal item_banked(item_id: int, quantity: int)

@onready var slot_grid: GridContainer = $Panel/SlotGrid
@onready var gold_label: Label = $Panel/GoldLabel
@onready var context_menu: PopupMenu = $ContextMenu
@onready var inventory_tab: Button = $Panel/TabBar/InventoryTab
@onready var bank_tab: Button = $Panel/TabBar/BankTab
@onready var close_button: Button = $Panel/CloseButton

var showing_bank: bool = false
var selected_slot: int = -1
var inventory_items: Array = []
var bank_items: Array = []
var item_definitions: Dictionary = {}
var player_gold: int = 0

const SLOT_COUNT := 32
const COLS := 8
const ROWS := 4

func _ready() -> void:
	visible = false
	inventory_tab.pressed.connect(_show_inventory)
	bank_tab.pressed.connect(_show_bank)
	close_button.pressed.connect(func(): visible = false)
	context_menu.id_pressed.connect(_on_context_action)
	_create_slots()

func _create_slots() -> void:
	for child in slot_grid.get_children():
		child.queue_free()
	for i in SLOT_COUNT:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(30, 18)
		slot.text = ""
		slot.pressed.connect(_on_slot_clicked.bind(i))
		slot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		slot_grid.add_child(slot)

func _show_inventory() -> void:
	showing_bank = false
	inventory_tab.button_pressed = true
	bank_tab.button_pressed = false
	refresh()

func _show_bank() -> void:
	showing_bank = true
	bank_tab.button_pressed = true
	inventory_tab.button_pressed = false
	refresh()

func refresh() -> void:
	gold_label.text = "Gold: %d" % player_gold
	var items: Array = bank_items if showing_bank else inventory_items
	var slots := slot_grid.get_children()
	for i in SLOT_COUNT:
		if i >= slots.size():
			break
		var slot: Button = slots[i]
		var item := _find_item_at_slot(items, i)
		if item.is_empty():
			slot.text = ""
			slot.tooltip_text = ""
		else:
			var def: Dictionary = item_definitions.get(item.get("item_def_id", 0), {})
			var qty: int = item.get("quantity", 0)
			var name: String = def.get("name", "???")
			slot.text = "%s\n%d" % [name.left(4), qty] if qty > 1 else name.left(5)
			slot.tooltip_text = "%s (x%d)\n%s" % [name, qty, def.get("description", "")]

func _find_item_at_slot(items: Array, slot_idx: int) -> Dictionary:
	for item in items:
		if item.get("slot", -1) == slot_idx:
			return item
	return {}

func _on_slot_clicked(slot_idx: int) -> void:
	selected_slot = slot_idx
	var items: Array = bank_items if showing_bank else inventory_items
	var item := _find_item_at_slot(items, slot_idx)
	if item.is_empty():
		return
	item_selected.emit(item)

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var items: Array = bank_items if showing_bank else inventory_items
		if selected_slot >= 0:
			var item := _find_item_at_slot(items, selected_slot)
			if not item.is_empty():
				_show_context(event.position, item)

func _show_context(pos: Vector2, _item: Dictionary) -> void:
	context_menu.clear()
	if showing_bank:
		context_menu.add_item("Withdraw", 0)
	else:
		context_menu.add_item("Drop", 1)
		context_menu.add_item("Bank", 2)
	context_menu.position = Vector2i(pos)
	context_menu.popup()

func _on_context_action(id: int) -> void:
	var items: Array = bank_items if showing_bank else inventory_items
	var item := _find_item_at_slot(items, selected_slot)
	if item.is_empty():
		return
	match id:
		0: # Withdraw
			item_banked.emit(item.get("id", 0), item.get("quantity", 1))
		1: # Drop
			item_dropped.emit(item.get("id", 0), item.get("quantity", 1))
		2: # Bank
			item_banked.emit(item.get("id", 0), item.get("quantity", 1))

func set_gold(amount: int) -> void:
	player_gold = amount
	if gold_label:
		gold_label.text = "Gold: %d" % amount

func set_items(inv: Array, bank: Array, defs: Dictionary) -> void:
	inventory_items = inv
	bank_items = bank
	item_definitions = defs
	refresh()

func toggle() -> void:
	visible = !visible
	if visible:
		refresh()
