extends StaticBody2D
class_name Interactable

## Base class for interactable objects

@export var interaction_hint: String = "Z - Interact"

func interact(_player: Node2D) -> void:
	pass  # Override in subclasses

func get_interaction_hint() -> String:
	return interaction_hint
