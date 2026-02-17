extends Control

signal withdraw_requested(item_id: int, quantity: int)

@onready var item_list: ItemList = $Panel/ItemList
@onready var withdraw_btn: Button = $Panel/HBox/WithdrawBtn
@onready var close_btn: Button = $Panel/HBox/CloseBtn

var bank_items: Array = []
var item_definitions: Dictionary = {}

func _ready() -> void:
	visible = false
	withdraw_btn.pressed.connect(_on_withdraw)
	close_btn.pressed.connect(func(): visible = false)

func refresh() -> void:
	item_list.clear()
	for item in bank_items:
		var def: Dictionary = item_definitions.get(item.get("item_def_id", 0), {})
		var name: String = def.get("name", "Unknown")
		var qty: int = item.get("quantity", 0)
		var val: int = def.get("value", 0)
		item_list.add_item("%s x%d (val: %d)" % [name, qty, val])

func _on_withdraw() -> void:
	var sel := item_list.get_selected_items()
	if sel.is_empty():
		return
	var idx: int = sel[0]
	if idx < bank_items.size():
		var item: Dictionary = bank_items[idx]
		withdraw_requested.emit(item.get("id", 0), item.get("quantity", 1))

func set_data(items: Array, defs: Dictionary) -> void:
	bank_items = items
	item_definitions = defs
	refresh()

func toggle() -> void:
	visible = !visible
	if visible:
		refresh()
