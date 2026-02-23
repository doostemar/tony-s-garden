# dirt.gd
class_name Dirt
extends Area2D

@export var planting_collision: CollisionShape2D

var grid_coords: Vector2i

@onready var _radish_scene: PackedScene = preload("res://scenes/radish.tscn")
var radish: Radish

func set_grid_coords(coords: Vector2i) -> void:
	grid_coords = coords

func make_plant():
	# construct radish with injected grid coords (no lookups)
	radish = _radish_scene.instantiate()
	add_child( radish )
	radish.init( grid_coords )

func pick_radish() -> Radish:
	if radish and is_instance_valid( radish ):
		event_bus.radish_picked.emit( radish, radish.global_position, grid_coords )
		remove_child( radish ) # remove from dirt's scene tree, but don't free
		var temp_radish = radish
		radish = null
		print("dirt at coords ", grid_coords, ": radish picked up")
		return temp_radish
	return null

func remove_radish() -> void:
	if radish and is_instance_valid(radish):
		radish.queue_free()
		radish = null
		print("dirt at coords ", grid_coords, ": radish removed")

func accept_radish(incoming_radish: Radish) -> bool:
	if radish != null:
		return false # already has a radish
	radish = incoming_radish
	add_child(radish)
	radish.position = Vector2.ZERO # center it on the dirt
	event_bus.radish_landed.emit(radish, radish.global_position, grid_coords)
	return true

func get_radish_state() -> int:
	if radish:
		return radish.get_current_state()
	return -1
