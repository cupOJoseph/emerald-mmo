extends Camera2D

## Camera that clamps to map bounds

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 5.0
	# Defer so the map is ready
	call_deferred("_calculate_bounds")

func _calculate_bounds() -> void:
	var map_node := _find_tilemap()
	if not map_node:
		return
	var rect := map_node.get_used_rect()
	var tile_size := map_node.tile_set.tile_size if map_node.tile_set else Vector2i(16, 16)
	limit_left = rect.position.x * tile_size.x
	limit_top = rect.position.y * tile_size.y
	limit_right = (rect.position.x + rect.size.x) * tile_size.x
	limit_bottom = (rect.position.y + rect.size.y) * tile_size.y

func _find_tilemap() -> TileMapLayer:
	# Walk up to find the map root, then find a TileMapLayer named "Ground"
	var root := get_tree().current_scene
	if not root:
		return null
	# Look for Ground TileMapLayer in the scene
	return _search_tilemap(root)

func _search_tilemap(node: Node) -> TileMapLayer:
	if node is TileMapLayer and node.name == "Ground":
		return node
	for child in node.get_children():
		var result := _search_tilemap(child)
		if result:
			return result
	return null
