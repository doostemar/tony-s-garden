# cell.gd
class_name Cell
extends Node2D

enum { GRASS, DIRT }

var terrain: int
var terrain_node: Area2D
var collider: CollisionShape2D
var grid_coords: Vector2i

const GRASS_SCENE = preload("res://scenes/grass.tscn")
const DIRT_SCENE = preload("res://scenes/dirt.tscn")

func _init(type: int, _size: int, world_pos: Vector2, grid_coords_in: Vector2i) -> void:
	grid_coords = grid_coords_in
	global_position = world_pos
	load_terrain(type)

func get_terrain_type() -> int:
	return terrain

func load_terrain(type: int) -> void:
	match type:
		GRASS:
			terrain = GRASS
			terrain_node = GRASS_SCENE.instantiate()
		DIRT:
			terrain = DIRT
			terrain_node = DIRT_SCENE.instantiate()
			terrain_node.set_grid_coords(grid_coords)
	terrain_node.monitoring = true
	add_child(terrain_node)

	# find a CollisionShape2D for convenience/debug
	collider = terrain_node.get_node_or_null("CollisionShape2D")
	if collider == null:
		for c in terrain_node.get_children():
			if c is CollisionShape2D:
				collider = c
				break

func disable_collision() -> void:
	if collider: collider.set_deferred("disabled", true)

func check_overlapping_bodies() -> bool:
	if terrain_node == null: push_warning( "no terrain node to check bodies" )
	var has_bodies = terrain_node.has_overlapping_bodies()
	if has_bodies: 
		print("@%s: there's already a body" % [grid_coords])
	return has_bodies

func reset_collision() -> void:
	terrain_node.monitoring = false
	terrain_node.monitoring = true
