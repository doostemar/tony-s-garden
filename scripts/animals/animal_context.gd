# animal_context.gd
class_name Animal_Context
extends Node

enum Difficulty {
	CHILL,
	HUNGRY,
	RAVENOUS
}

signal difficulty_changed(difficulty: int)
signal spawn_chance_changed(chance: float)

var spawn_chance_modifier: float = 0.2:
	set = set_spawn_chance_modifier

var difficulty: int = Difficulty.CHILL:
	set = set_difficulty

var _cell_grid
var _radishes: Array[Radish] = []


func _ready() -> void:
	if event_bus.has_signal("radish_planted"):
		event_bus.radish_planted.connect(
			_on_radish_added
		)

	if event_bus.has_signal("radish_landed"):
		event_bus.radish_landed.connect(
			_on_radish_added
		)

	if event_bus.has_signal("radish_picked"):
		event_bus.radish_picked.connect(
			_on_radish_removed
		)


func set_difficulty(new_difficulty: int) -> void:
	if difficulty != new_difficulty:
		set_spawn_chance_modifier(
			(new_difficulty - difficulty)
			* spawn_chance_modifier
		)

		difficulty = new_difficulty
		difficulty_changed.emit(difficulty)


func set_spawn_chance_modifier(
	new_modifier: float
) -> void:
	if spawn_chance_modifier != new_modifier:
		spawn_chance_modifier = new_modifier
		spawn_chance_changed.emit(
			spawn_chance_modifier
		)


func set_grid(grid: Cell_Grid) -> void:
	_cell_grid = grid


func get_cell_world(world_pos: Vector2) -> Cell:
	return _cell_grid.find_cell_world(world_pos)


func get_cell_local(idx: Vector2i) -> Cell:
	if _cell_grid == null:
		push_error(
			"Animal_Context.cell_grid is null; "
			+ "grid not ready yet."
		)
		return null

	return _cell_grid.find_cell_local(idx)


func get_grid_pos(world_pos: Vector2i) -> Vector2i:
	return _cell_grid.find_local_pos(world_pos)


func get_cell_grid() -> Cell_Grid:
	return _cell_grid


func get_radishes() -> Array[Radish]:
	_cleanup_radishes()
	return _radishes.duplicate()


func forget_radish(radish: Radish) -> void:
	_radishes.erase(radish)


func clear_radishes() -> void:
	_radishes.clear()


func _on_radish_added(
	radish: Radish,
	_world_pos: Vector2,
	_grid_coords: Vector2i
) -> void:
	if not _radishes.has(radish):
		_radishes.append(radish)


func _on_radish_removed(
	radish: Radish,
	_world_pos: Vector2,
	_grid_coords: Vector2i
) -> void:
	_radishes.erase(radish)


func _cleanup_radishes() -> void:
	for i in range(_radishes.size() - 1, -1, -1):
		if not is_instance_valid(_radishes[i]):
			_radishes.remove_at(i)
