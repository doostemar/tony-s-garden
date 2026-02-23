# radish_system.gd
# currently not used
class_name Radish_System
extends Node2D

@export var radish_scene: PackedScene = preload("res://scenes/radish.tscn")

var _radishes: Array[Radish] = []

func _ready() -> void:
	if event_bus.has_signal("radish_spawn_requested"):
		event_bus.radish_spawn_requested.connect(_on_radish_spawn_requested)
	if event_bus.has_signal("radish_destroy_requested"):
		event_bus.radish_destroy_requested.connect(_on_radish_destroy_requested)

func _on_radish_spawn_requested(dirt, grid_coords: Vector2i) -> void:
	if dirt == null or not is_instance_valid(dirt):
		return

	# if the dirt already has a radish, do nothing
	if dirt.has_method("has_radish") and dirt.has_radish():
		return

	var r := radish_scene.instantiate() as Radish
	add_child(r)
	_radishes.append(r)

	# keep registry clean even if someone frees the node elsewhere
	r.tree_exited.connect(func():
		_radishes.erase(r)
	)

	# initialize radish as planted on this dirt
	# dirt receives the reference (reverse dependency)
	if dirt.has_method("assign_radish"):
		dirt.assign_radish(r)
	else:
		push_warning("Radish_System: Dirt missing assign_radish(radish)")

	# radish sets its own initial state/ownership
	# we pass dirt as owner reference (no parenting)
	r.init_planted(grid_coords, dirt)

func _on_radish_destroy_requested(radish) -> void:
	if radish == null or not is_instance_valid(radish):
		return

	_radishes.erase(radish)
	radish.queue_free()

func get_all_radishes() -> Array[Radish]:
	return _radishes
