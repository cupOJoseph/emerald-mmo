extends Node2D

## Route 1 - procedural setup on first load

func _ready() -> void:
	var ground: TileMapLayer = $Ground
	var collision: TileMapLayer = $Collision

	# Fill ground - 20 wide, 40 tall
	for y in range(40):
		for x in range(20):
			# Default: grass
			var atlas := Vector2i(0, 0)

			# Central path (cols 8-11)
			if x >= 8 and x <= 11:
				atlas = Vector2i(4, 0)

			# Tall grass patches
			if (x >= 2 and x <= 6) or (x >= 13 and x <= 17):
				if (y >= 5 and y <= 14) or (y >= 22 and y <= 31):
					atlas = Vector2i(1, 0)

			ground.set_cell(Vector2i(x, y), 0, atlas)

	# Trees/rocks as collision obstacles on edges
	for y in range(40):
		# Left and right border trees
		collision.set_cell(Vector2i(0, y), 0, Vector2i(10, 1))
		collision.set_cell(Vector2i(19, y), 0, Vector2i(10, 1))

	# Water feature - small pond (rows 25-28, cols 3-6)
	for y in range(25, 29):
		for x in range(3, 7):
			ground.set_cell(Vector2i(x, y), 0, Vector2i(0, 7))
			collision.set_cell(Vector2i(x, y), 0, Vector2i(0, 7))

	# Fence segments along path edges
	for y in range(3, 38):
		if y % 5 == 0:
			collision.set_cell(Vector2i(7, y), 0, Vector2i(5, 3))
			collision.set_cell(Vector2i(12, y), 0, Vector2i(5, 3))

	# Some scattered rocks
	collision.set_cell(Vector2i(5, 18), 0, Vector2i(0, 2))
	collision.set_cell(Vector2i(14, 18), 0, Vector2i(0, 2))
	collision.set_cell(Vector2i(3, 35), 0, Vector2i(0, 2))
	collision.set_cell(Vector2i(16, 35), 0, Vector2i(0, 2))
