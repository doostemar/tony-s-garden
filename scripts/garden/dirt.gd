class_name Dirt
extends Area2D

@export var planting_collision: CollisionShape2D

var grid_coords: Vector2i
var radish: Radish

func _ready():
	radish = null
	
func set_grid_coords(coords: Vector2i) -> void:
	grid_coords = coords

func make_plant() -> void:
	event_bus.radish_spawn_requested.emit( self, grid_coords, global_position )

func assign_radish(r: Radish) -> void:
	radish = r
	
func has_radish() -> bool:
	if radish: return true
	return false
