class_name Radish_Manager
extends Node2D

var _radish_scene: PackedScene = preload(
	"res://scenes/radish.tscn"
)

var _radishes: Array[Radish] = []


func _ready() -> void:
	if event_bus.has_signal("radish_spawn_requested"):
		event_bus.radish_spawn_requested.connect(
			_on_radish_spawn_requested
		)

	if event_bus.has_signal("radish_destroy_requested"):
		event_bus.radish_destroy_requested.connect(
			_on_radish_destroy_requested
		)


func _on_radish_spawn_requested(
	dirt,
	grid_coords: Vector2i,
	pos
) -> void:
	if dirt == null or not is_instance_valid(dirt):
		return

	if (
		dirt.has_method("has_radish")
		and dirt.has_radish()
	):
		return

	var radish: Radish = _radish_scene.instantiate()

	add_child(radish)
	_radishes.append(radish)

	radish.tree_exited.connect(
		func():
			_radishes.erase(radish)
	)

	if dirt.has_method("assign_radish"):
		dirt.assign_radish(radish)
	else:
		push_warning(
			"Radish_System: Dirt missing "
			+ "assign_radish(radish)"
		)

	radish.global_position = pos
	radish.init(grid_coords, dirt)


func _on_radish_destroy_requested(radish) -> void:
	if (
		radish == null
		or not is_instance_valid(radish)
	):
		return

	_radishes.erase(radish)
	radish.queue_free()


func get_all_radishes() -> Array[Radish]:
	return _radishes


func remove_radish(radish: Radish) -> void:
	if (
		radish == null
		or not is_instance_valid(radish)
	):
		return

	if (
		radish.holder
		and is_instance_valid(radish.holder)
		and radish.holder.has_method("clear_radish")
	):
		radish.holder.clear_radish()

	radish.queue_free()


func reset() -> void:
	print(
		"radish_manager.reset(): clearing ",
		_radishes.size(),
		" radishes"
	)

	# Work from a copy because leaving the tree triggers
	# each radish's tree_exited callback.
	var radishes_to_remove: Array[Radish] = (
		_radishes.duplicate()
	)

	_radishes.clear()

	for radish: Radish in radishes_to_remove:
		if not is_instance_valid(radish):
			continue

		# Clear the reverse relationship first.
		if (
			radish.holder
			and is_instance_valid(radish.holder)
			and radish.holder.has_method("clear_radish")
		):
			radish.holder.clear_radish()

		if not is_instance_valid(radish):
			continue

		# Remove it from active gameplay immediately.
		var parent: Node = radish.get_parent()

		if parent:
			parent.remove_child(radish)

		# Memory deletion itself can remain safely deferred.
		radish.queue_free()
