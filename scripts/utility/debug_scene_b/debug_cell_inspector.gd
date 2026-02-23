# debug_cell_inspector.gd
class_name DebugCellInspector
extends DebugModule

## handles cell clicking and inspection

var cell_grid: Cell_Grid
var highlight: ColorRect
var selected_cell: Cell = null

func setup() -> void:
	var garden := debug_manager.get_garden_manager()
	if garden == null:
		push_error("DebugCellInspector: No garden manager available")
		return
	
	cell_grid = garden.get_cell_grid()
	
	# Connect to regeneration
	event_bus.garden_regenerated.connect(_on_garden_regenerated)
	
	_create_highlight()
	log_message("Cell Inspector ready - click tiles to inspect")

func _create_highlight() -> void:
	var garden := debug_manager.get_garden_manager()
	if garden == null:
		return
	
	highlight = ColorRect.new()
	highlight.name = "CellHighlight"
	highlight.color = Color(1.0, 1.0, 0.0, 0.3)
	highlight.size = Vector2(garden.get_cell_size(), garden.get_cell_size())
	highlight.visible = false
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	highlight.z_index = 100
	garden.add_child(highlight)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_handle_click(event.global_position)

func _handle_click(click_pos: Vector2) -> void:
	if cell_grid == null:
		return
	
	var garden := debug_manager.get_garden_manager()
	var cell_size := garden.get_cell_size()
	var offset := garden.get_offset()
	var side_length := garden.get_side_length()
	
	var grid_x := int((click_pos.x - offset.x) / cell_size + 0.5)
	var grid_y := int((click_pos.y - offset.y) / cell_size + 0.5)
	
	if grid_x < 0 or grid_x >= side_length or grid_y < 0 or grid_y >= side_length:
		log_message("[color=gray]Clicked outside grid bounds[/color]")
		_hide_highlight()
		selected_cell = null
		return
	
	var grid_coords := Vector2i(grid_x, grid_y)
	selected_cell = cell_grid.find_cell_local(grid_coords)
	
	if selected_cell == null:
		log_message("[color=red]No cell found at " + str(grid_coords) + "[/color]")
		_hide_highlight()
		return
	
	_display_cell_info(selected_cell)
	_show_highlight(selected_cell)

func _display_cell_info(cell: Cell) -> void:
	log_message("─────────────────────")
	log_message("[color=cyan]Cell Selected[/color]")
	log_message("Grid Coords: [color=yellow]" + str(cell.grid_coords) + "[/color]")
	
	var terrain_name := "UNKNOWN"
	match cell.get_terrain_type():
		Cell.GRASS:
			terrain_name = "[color=green]GRASS[/color]"
		Cell.DIRT:
			terrain_name = "[color=orange]DIRT[/color]"
	log_message("Terrain: " + terrain_name)
	
	if cell.terrain_node != null:
		var overlapping := cell.terrain_node.get_overlapping_bodies()
		var count := overlapping.size()
		var color := "white" if count == 0 else "red"
		log_message("Overlapping Bodies: [color=" + color + "]" + str(count) + "[/color]")
		
		for body in overlapping:
			log_message("  • " + body.name)
	else:
		log_message("[color=red]No terrain node![/color]")
	
	log_message("World Pos: " + str(cell.global_position))

func _show_highlight(cell: Cell) -> void:
	var garden := debug_manager.get_garden_manager()
	var cell_size := garden.get_cell_size()
	highlight.global_position = cell.global_position - Vector2(cell_size / 2.0, cell_size / 2.0)
	highlight.visible = true

func _hide_highlight() -> void:
	if highlight:
		highlight.visible = false

func _on_garden_regenerated(_side_length: int) -> void:
	var garden := debug_manager.get_garden_manager()
	if garden:
		cell_grid = garden.get_cell_grid()
	selected_cell = null
	_hide_highlight()
	log_message("[color=magenta]Garden regenerated[/color]")

func cleanup() -> void:
	if highlight:
		highlight.queue_free()
