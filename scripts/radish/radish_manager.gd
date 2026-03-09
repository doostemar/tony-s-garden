class_name Radish_Manager
extends Node2D

var _radish_scene: PackedScene = preload("res://scenes/radish.tscn")

var _radishes: Array[Radish] = []

func _ready() -> void:
	if event_bus.has_signal("radish_spawn_requested"):
		event_bus.radish_spawn_requested.connect(_on_radish_spawn_requested)
	if event_bus.has_signal("radish_destroy_requested"):
		event_bus.radish_destroy_requested.connect(_on_radish_destroy_requested)

func _on_radish_spawn_requested(dirt, grid_coords: Vector2i, pos) -> void:
	if dirt == null or not is_instance_valid(dirt):
		return

	# if the dirt already has a radish, do nothing
	if dirt.has_method("has_radish") and dirt.has_radish():
		return

	var r = _radish_scene.instantiate()
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
	r.global_position = pos
	r.init(grid_coords, dirt)

func _on_radish_destroy_requested(radish) -> void:
	if radish == null or not is_instance_valid(radish):
		return

	_radishes.erase( radish )
	radish.queue_free()

func get_all_radishes() -> Array[Radish]:
	return _radishes

func remove_radish(radish: Radish) -> void:
	if radish and is_instance_valid(radish):
		if radish.holder and is_instance_valid(radish.holder) and radish.holder.has_method("clear_radish"):
			radish.holder.clear_radish()
		radish.queue_free()

func reset() -> void:
	print("radish_manager.reset(): clearing ", _radishes.size(), " radishes")
	for radish in _radishes:
		radish.queue_free()
	_radishes.clear()
