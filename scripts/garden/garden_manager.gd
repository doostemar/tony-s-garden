# garden_manager.gd
class_name Garden_Manager
extends Node

@export var side_length: int = 9
@export var fill_factor: float = 0.35
@export var offset: Vector2 = Vector2(75, 100)
@export var testing: bool

const CELL_SIZE := 16

var regen: Button
var cell_grid: Cell_Grid

func _ready():
	cell_grid = Cell_Grid.new()
	add_child(cell_grid)
	event_bus.grid_ready.connect(_on_cell_grid_ready)
	cell_grid.init(side_length, fill_factor, offset, CELL_SIZE, testing)

func _on_cell_grid_ready():
	event_bus.garden_regenerated.emit(side_length)

func regenerate_garden():
	cell_grid.regenerate(side_length)
	event_bus.garden_regenerated.emit(side_length)

func get_center() -> Vector2:
	var x_val = side_length / 2 * CELL_SIZE + offset.x
	var y_val = side_length / 2 * CELL_SIZE + offset.y
	return Vector2(x_val, y_val)

# --- utilities --- #
func get_cell_grid() -> Cell_Grid:
	return cell_grid

func get_side_length() -> int:
	return side_length

func get_offset() -> Vector2:
	return offset

func get_cell_size() -> int:
	return CELL_SIZE
