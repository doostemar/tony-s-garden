# cell_grid.gd
class_name Cell_Grid
extends Node2D

var grid: Array[Array] = []
var cell_dict: Dictionary = {}
var array_gen: Array_Generator

var _side_length: int
var _fill_factor: float
var _offset: Vector2
var _cell_size: int

func init(side_length: int, fill_factor: float, offset: Vector2, cell_size: int, _testing: bool):
	_side_length = side_length
	_fill_factor = fill_factor
	_offset.x = offset.x
	_offset.y = offset.y
	_cell_size = cell_size

	array_gen = Array_Generator.new(side_length, fill_factor)
	array_gen.print_grid()

	draw_grid()
	event_bus.emit_signal("grid_ready")

	z_index = 0
	z_as_relative = true
	y_sort_enabled = true

func draw_grid():
	grid.clear()
	grid.resize(_side_length)
	var grid_guide = array_gen.get_grid()

	for y in _side_length:
		grid[y] = []
		grid[y].resize(_side_length)
		for x in _side_length:
			var world_pos := Vector2(_cell_size * x + _offset.x, _cell_size * y + _offset.y)
			var type = grid_guide[y][x]
			var grid_coords := Vector2i(x, y)
			var cell := create_cell(type, world_pos, grid_coords)
			grid[y][x] = cell

# cell_dict is now cleared here alongside grid so no
# stale references survive a regeneration.
func clear_grid():
	for row in grid:
		for cell in row:
			if is_instance_valid(cell):
				cell.queue_free()
	grid.clear()
	cell_dict.clear()

func create_cell(ground_type: int, world_pos: Vector2, grid_coords: Vector2i) -> Cell:
	var cell := Cell.new(ground_type, _cell_size, world_pos, grid_coords)
	add_child(cell)
	cell_dict[grid_coords] = cell
	return cell

func find_cell_world(world_pos: Vector2i) -> Cell:
	var x := (world_pos.x - _offset.x) / _cell_size
	var y := (world_pos.y - _offset.y) / _cell_size
	return grid[y][x]

func find_cell_local(idx: Vector2i) -> Cell:
	return grid[idx.y][idx.x]

func find_local_pos(world_pos: Vector2i) -> Vector2i:
	var x := (world_pos.x - _offset.x) / _cell_size
	var y := (world_pos.y - _offset.y) / _cell_size
	return Vector2i(x, y)

func regenerate(new_side_length: int = -1):
	if new_side_length > 0 and new_side_length != _side_length:
		_side_length = new_side_length
		array_gen = Array_Generator.new(_side_length, _fill_factor)

	array_gen.create_empty_grid()
	array_gen.fill_grid()
	array_gen.print_grid()
	clear_grid()
	draw_grid()

func get_grid_len() -> int:
	return _side_length
