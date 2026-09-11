# adjacent_grass_finder.gd
class_name Adjacent_Grass_Finder
extends Node


func find_tiles(
	context: Animal_Context,
	radish: Radish
) -> Array[Cell]:
	if context == null:
		push_warning(
			"Adjacent_Grass_Finder: missing Animal_Context"
		)
		return []

	if not is_instance_valid(radish):
		return []

	var cell_grid := context.get_cell_grid()

	if cell_grid == null:
		return []

	var garden_len = cell_grid.get_grid_len()
	var grid_coords := radish.get_grid_coords()

	var directions := [
		Vector2i(0, -1),
		Vector2i(1, 0),
		Vector2i(0, 1),
		Vector2i(-1, 0)
	]

	var found_grass_tiles: Array[Cell] = []

	for direction in directions:
		var check = grid_coords + direction

		if (
			check.x < 0
			or check.x >= garden_len
			or check.y < 0
			or check.y >= garden_len
		):
			continue

		var cell: Cell = context.get_cell_local(check)

		if cell == null:
			continue

		if cell.get_terrain_type() == 0:
			found_grass_tiles.append(cell)
			_highlight_grass_tile(cell)

	return found_grass_tiles


func _highlight_grass_tile(cell: Cell) -> void:
	var grass_node = cell.terrain_node

	if not grass_node:
		return

	var collision_shape: CollisionShape2D = (
		grass_node.get_node_or_null(
			"CollisionShape2D"
		)
	)

	if collision_shape:
		collision_shape.debug_color = Color.RED
