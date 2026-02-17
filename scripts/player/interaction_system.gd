extends Node
class_name InteractionSystem

## Checks for interactable objects in front of the player using RayCast2D

var player: CharacterBody2D
var ray: RayCast2D
var current_interactable: Interactable = null

func _init(p: CharacterBody2D, r: RayCast2D) -> void:
	player = p
	ray = r

func check_facing() -> Interactable:
	if not ray:
		return null
	ray.force_raycast_update()
	if ray.is_colliding():
		var collider = ray.get_collider()
		if collider is Interactable:
			current_interactable = collider
			return collider
	current_interactable = null
	return null

func try_interact() -> bool:
	var interactable := check_facing()
	if interactable:
		interactable.interact(player)
		return true
	return false
