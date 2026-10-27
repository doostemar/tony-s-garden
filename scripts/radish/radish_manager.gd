# radish_manager.gd
class_name Radish_Manager
extends Node2D

## seconds a radish spends in a growth state before advancing to the next one
## 0 = instant, higher = longer
const DEFAULT_GROWTH_TIME: float = 5

## seconds a radish stays a SEED before becoming a SPROUT
@export var seed_growth_time: float = DEFAULT_GROWTH_TIME:
	set(value):
		seed_growth_time = maxf(value, 0.0)

## seconds a radish stays a SPROUT before becoming an ADULT
@export var sprout_growth_time: float = DEFAULT_GROWTH_TIME:
	set(value):
		sprout_growth_time = maxf(value, 0.0)

var _radish_scene: PackedScene = preload("res://scenes/radish.tscn")

var _radishes: Array[Radish] = []

# Inspector values captured at load time; used by the debug module's "Default" button.
var _default_growth_times: Dictionary = {}


func _ready() -> void:
	_default_growth_times = {
		Radish.RadishState.SEED: seed_growth_time,
		Radish.RadishState.SPROUT: sprout_growth_time,
	}

	if event_bus.has_signal("radish_spawn_requested"):
		event_bus.radish_spawn_requested.connect(_on_radish_spawn_requested)

	if event_bus.has_signal("radish_destroy_requested"):
		event_bus.radish_destroy_requested.connect(_on_radish_destroy_requested)


# --- growth times --- #


func set_growth_time(state: int, seconds: float) -> void:
	match state:
		Radish.RadishState.SEED:
			seed_growth_time = seconds
		Radish.RadishState.SPROUT:
			sprout_growth_time = seconds
		_:
			push_warning("Radish_Manager: state %d has no growth time" % state)


func get_growth_time(state: int) -> float:
	match state:
		Radish.RadishState.SEED:
			return seed_growth_time
		Radish.RadishState.SPROUT:
			return sprout_growth_time
		_:
			return 0.0


func get_default_growth_time(state: int) -> float:
	return float(_default_growth_times.get(state, DEFAULT_GROWTH_TIME))


func reset_growth_time(state: int) -> void:
	set_growth_time(state, get_default_growth_time(state))


# --- spawning / removal --- #


func _on_radish_spawn_requested(dirt, grid_coords: Vector2i, pos) -> void:
	if dirt == null or not is_instance_valid(dirt):
		return

	if dirt.has_method("has_radish") and dirt.has_radish():
		return

	var radish: Radish = _radish_scene.instantiate()

	add_child(radish)
	_radishes.append(radish)

	radish.tree_exited.connect(func(): _radishes.erase(radish))

	if dirt.has_method("assign_radish"):
		dirt.assign_radish(radish)
	else:
		push_warning("Radish_System: Dirt missing assign_radish(radish)")

	radish.global_position = pos
	radish.init(grid_coords, dirt, self)


func _on_radish_destroy_requested(radish) -> void:
	if radish == null or not is_instance_valid(radish):
		return

	_radishes.erase(radish)
	radish.queue_free()


func get_all_radishes() -> Array[Radish]:
	return _radishes


func remove_radish(radish: Radish) -> void:
	if radish == null or not is_instance_valid(radish):
		return

	if radish.holder and is_instance_valid(radish.holder) and radish.holder.has_method("clear_radish"):
		radish.holder.clear_radish()

	radish.queue_free()


func reset() -> void:
	print("radish_manager.reset(): clearing ", _radishes.size(), " radishes")

	var radishes_to_remove: Array[Radish] = _radishes.duplicate()

	_radishes.clear()

	for radish: Radish in radishes_to_remove:
		if not is_instance_valid(radish):
			continue

		if radish.holder and is_instance_valid(radish.holder) and radish.holder.has_method("clear_radish"):
			radish.holder.clear_radish()

		radish.queue_free()
