# animal_context.gd
class_name Animal_Context
extends Node

enum Difficulty { CHILL, HUNGRY, RAVENOUS }

signal difficulty_changed( difficulty: int )
signal spawn_chance_changed( chance: float )

var spawn_chance_modifier: float = .2  : set = set_spawn_chance_modifier
var difficulty: int = Difficulty.CHILL : set = set_difficulty

var _cell_grid

func set_difficulty( new_difficulty: int ) -> void:
	if difficulty != new_difficulty:
		set_spawn_chance_modifier( ( new_difficulty - difficulty ) * spawn_chance_modifier )
		difficulty = new_difficulty
		difficulty_changed.emit( difficulty )

func set_spawn_chance_modifier( new_modifier: float ) -> void:
	if spawn_chance_modifier != new_modifier:
		spawn_chance_modifier = new_modifier
		spawn_chance_changed.emit( spawn_chance_modifier )

func set_grid( grid: Cell_Grid ) -> void:
	_cell_grid = grid

func get_cell_world( world_pos: Vector2 ) -> Cell:
	return _cell_grid.find_cell_world( world_pos )

func get_cell_local( idx: Vector2i ) -> Cell:
	if _cell_grid == null:
		push_error( "Animal_Context.cell_grid is null; grid not ready yet." )
		return null
	return _cell_grid.find_cell_local( idx )

func get_grid_pos( world_pos: Vector2i ) -> Vector2i:
	return _cell_grid.find_local_pos( world_pos )

func get_cell_grid() -> Cell_Grid:
	return _cell_grid
