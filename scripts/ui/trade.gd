extends Control

signal trade_accepted(trade_id: int)
signal trade_cancelled(trade_id: int)
signal gold_set(trade_id: int, amount: int)
signal item_added(trade_id: int, item_id: int, quantity: int)

@onready var status_label: Label = $Panel/StatusLabel
@onready var your_items: ItemList = $Panel/Columns/YourSide/YourItems
@onready var their_items: ItemList = $Panel/Columns/TheirSide/TheirItems
@onready var gold_input: SpinBox = $Panel/Columns/YourSide/GoldBox/GoldInput
@onready var their_gold: Label = $Panel/Columns/TheirSide/TheirGold
@onready var accept_btn: Button = $Panel/Buttons/AcceptBtn
@onready var cancel_btn: Button = $Panel/Buttons/CancelBtn
@onready var warning_label: Label = $Panel/WarningLabel

var current_trade_id: int = -1
var my_trade_items: Array = []
var their_trade_items: Array = []
var item_definitions: Dictionary = {}
var my_gold_offer: int = 0
var their_gold_offer: int = 0

func _ready() -> void:
	visible = false
	accept_btn.pressed.connect(func(): trade_accepted.emit(current_trade_id))
	cancel_btn.pressed.connect(func(): trade_cancelled.emit(current_trade_id))
	gold_input.value_changed.connect(_on_gold_changed)

func _on_gold_changed(value: float) -> void:
	gold_set.emit(current_trade_id, int(value))

func refresh() -> void:
	your_items.clear()
	for item in my_trade_items:
		var def: Dictionary = item_definitions.get(item.get("item_def_id", 0), {})
		your_items.add_item("%s x%d" % [def.get("name", "???"), item.get("quantity", 0)])

	their_items.clear()
	for item in their_trade_items:
		var def: Dictionary = item_definitions.get(item.get("item_def_id", 0), {})
		their_items.add_item("%s x%d" % [def.get("name", "???"), item.get("quantity", 0)])

	their_gold.text = "Gold: %d" % their_gold_offer

	# Value warning
	var my_val := my_gold_offer
	var their_val := their_gold_offer
	for item in my_trade_items:
		var def: Dictionary = item_definitions.get(item.get("item_def_id", 0), {})
		my_val += def.get("value", 0) * item.get("quantity", 0)
	for item in their_trade_items:
		var def: Dictionary = item_definitions.get(item.get("item_def_id", 0), {})
		their_val += def.get("value", 0) * item.get("quantity", 0)
	if my_val > their_val * 2 and their_val > 0:
		warning_label.text = "Warning: Uneven trade!"
	else:
		warning_label.text = ""

func set_trade(trade_id: int, my_items: Array, their_items_arr: Array, defs: Dictionary, my_gold: int, their_gold_amt: int, status: String) -> void:
	current_trade_id = trade_id
	my_trade_items = my_items
	their_trade_items = their_items_arr
	item_definitions = defs
	my_gold_offer = my_gold
	their_gold_offer = their_gold_amt
	status_label.text = "Status: %s" % status
	refresh()

func show_trade() -> void:
	visible = true
	refresh()

func toggle() -> void:
	visible = !visible
	if visible:
		refresh()
