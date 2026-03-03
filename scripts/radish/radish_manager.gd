class_name Radish_Manager
extends Node2D

var _radish_scene: PackedScene = preload("res://scenes/radish.tscn")

func _ready() -> void:
	add_to_group("radish_manager")

func create_radish(grid_coords: Vector2i, holder: Node2D, pos: Vector2) -> Radish:
	var radish = _radish_scene.instantiate()
	add_child(radish)
	radish.global_position = pos
	radish.init(grid_coords, holder)
	return radish

func remove_radish(radish: Radish) -> void:
	if radish and is_instance_valid(radish):
		if radish.holder and is_instance_valid(radish.holder) and radish.holder.has_method("clear_radish"):
			radish.holder.clear_radish()
		radish.queue_free()
