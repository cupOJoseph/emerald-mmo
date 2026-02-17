extends Interactable
class_name SignPost

@export var sign_text: String = "..."

func _ready() -> void:
	interaction_hint = "Z - Read"

func interact(_player: Node2D) -> void:
	var dialog = GameManager.get_dialog_box()
	if dialog:
		dialog.show_dialog("Sign", [sign_text])
