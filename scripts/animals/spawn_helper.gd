# spawn_helper.gd
class_name Spawn_Helper
extends Node

@export var context: Animal_Context
@export var factory: Enemy_Factory

# -- find spawn location (reads from context only) -- #
func find_adjacent_grass_tiles( radish: Radish ) -> Array:
	if context == null: 
		push_warning( "animal_manager.enemy_spawner._find_adjacent_grass_tiles ERROR: missing context" )
	var garden_len = context.get_cell_grid().get_grid_len()
	var grid_coords = radish.get_grid_coords()

	var directions := [
		Vector2i( 0, -1 ),  # north
		Vector2i( 1, 0 ),   # east
		Vector2i( 0, 1 ),   # south
		Vector2i( -1, 0 )   # west
	]

	var found_grass_tiles: Array = []
	
	for dir in directions:
		var check = grid_coords + dir
		if check.x >= 0 and check.x < garden_len and check.y >= 0 and check.y < garden_len:
			var cell: Cell = context.get_cell_local( Vector2i( check.x, check.y ))
			if cell.get_terrain_type() == 0: # GRASS
				found_grass_tiles.append( cell )
				_highlight_grass_tile( cell )
	
	return found_grass_tiles

func _highlight_grass_tile( cell: Cell ):
	var grass_node := cell.terrain_node
	if not grass_node:
		return
	var collision_shape: CollisionShape2D = grass_node.get_node_or_null( "CollisionShape2D" )
	if collision_shape:
		collision_shape.debug_color = Color.RED

# -- spawn attempt -- #
func spawn_request( candidates: Array, spawn_chance: float ) -> Cell:
	if candidates.is_empty(): return null
	var spawn_cell = candidates.pick_random()
	if spawn_cell and randf() > spawn_chance:
		# await get_tree().physics_frame
		if !spawn_cell.check_overlapping_bodies(): return spawn_cell
	return null
