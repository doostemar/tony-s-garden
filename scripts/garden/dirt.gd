class_name Dirt
extends Area2D

@export var planting_collision: CollisionShape2D

var grid_coords: Vector2i
var radish: Radish

func set_grid_coords(coords: Vector2i) -> void:
	grid_coords = coords

func _get_radish_manager() -> Radish_Manager:
	var managers = get_tree().get_nodes_in_group("radish_manager")
	if not managers.is_empty():
		return managers[0] as Radish_Manager
	push_warning("Dirt: no radish_manager found in group")
	return null

func make_plant() -> void:
	var manager = _get_radish_manager()
	if not manager:
		return
	radish = manager.create_radish(grid_coords, self, global_position)

func clear_radish() -> void:
	radish = null

func pick_radish() -> Radish:
	if radish and is_instance_valid(radish):
		var picked = radish
		radish = null
		return picked
	return null

func remove_radish() -> void:
	if radish and is_instance_valid(radish):
		radish.queue_free()
		radish = null

func accept_radish(incoming_radish: Radish) -> bool:
	if radish != null:
		return false
	radish = incoming_radish
	incoming_radish.set_holder(self)
	event_bus.radish_landed.emit(radish, radish.global_position, grid_coords)
	return true

func get_radish_state() -> int:
	if radish and is_instance_valid(radish):
		return radish.get_current_state()
	radish = null
	return -1
