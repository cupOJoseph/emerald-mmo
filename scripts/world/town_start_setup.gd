extends Node2D

## Adds NPCs and warp zone to town_start at runtime

func _ready() -> void:
	_add_warp_zone()
	_add_npcs()

func _add_warp_zone() -> void:
	# South exit warp to Route 1
	var warp := Area2D.new()
	warp.name = "WarpToRoute1"
	warp.collision_layer = 0
	warp.collision_mask = 2
	warp.position = Vector2(15 * 16, 37 * 16)  # Bottom of map

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(64, 16)
	shape.shape = rect
	warp.add_child(shape)

	var script = load("res://scripts/world/warp_zone.gd")
	warp.set_script(script)
	warp.target_map = "route_1"
	warp.target_scene = "res://scenes/world/route_1.tscn"
	warp.spawn_x = 152.0
	warp.spawn_y = 16.0

	add_child(warp)

func _add_npcs() -> void:
	var spritesheet = load("res://assets/sprites/player/player_spritesheet.png")

	# NPC 1: Welcome NPC near spawn
	_create_npc(
		"Guide",
		Vector2(12 * 16, 8 * 16),
		0,  # facing down
		1,  # red variant
		["Welcome to Emerald Town!", "Use WASD to move and Shift to run.", "Press Z to talk to people and read signs."],
		spritesheet
	)

	# NPC 2: Near building
	_create_npc(
		"Banker",
		Vector2(18 * 16, 12 * 16),
		2,  # facing left
		2,  # green variant
		["The bank is inside this building.", "Press B to access your items anytime!"],
		spritesheet
	)

	# NPC 3: Near south exit
	_create_npc(
		"Ranger",
		Vector2(14 * 16, 33 * 16),
		0,  # facing down
		3,  # yellow variant
		["Route 1 lies ahead to the south.", "Be careful in the tall grass!", "Wild Pokemon may appear... eventually."],
		spritesheet
	)

func _create_npc(npc_name: String, pos: Vector2, facing: int, variant: int, lines: Array, tex: Texture2D) -> void:
	var npc := StaticBody2D.new()
	npc.name = npc_name
	npc.position = pos
	npc.collision_layer = 1
	npc.collision_mask = 0

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	col.shape = rect
	npc.add_child(col)

	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.hframes = 3
	sprite.vframes = 16
	sprite.frame = variant * 4 * 3 + facing * 3  # standing frame
	npc.add_child(sprite)

	var label := Label.new()
	label.text = npc_name
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-20, -18)
	label.size = Vector2(40, 10)
	label.add_theme_font_size_override("font_size", 6)
	npc.add_child(label)

	# Apply NPC script
	var script = load("res://scripts/world/npc.gd")
	npc.set_script(script)
	npc.npc_name = npc_name
	npc.dialog_lines = PackedStringArray(lines)
	npc.sprite_variant = variant
	npc.facing_direction = facing
	npc.interaction_hint = "Z - Talk"

	add_child(npc)
