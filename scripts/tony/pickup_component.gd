# pickup_component.gd
extends Node2D
class_name Pickup_Component

@export var radish_layer_bit: int = 6
@export var collision_offset: Vector2 = Vector2(0, 0)
@export var carry_manager: Carry_Manager
@export var context: Tony_Context

# where a held radish sits relative to tony,
# and how far apart stacked radishes are
@export var hold_offset: Vector2 = Vector2(0, -10)
@export var stack_spacing: float = 5.0

var parent: Node2D
var pickup_area: Area2D
var pickup_collision: CollisionShape2D

var _base_radius: float = 0.0
var _shape: CircleShape2D

const ITEM_RADISH: StringName = &"radish"


func init(collision_shape_radius: float) -> void:
	parent = get_parent()
	_base_radius = collision_shape_radius

	pickup_area = Area2D.new()
	pickup_area.monitoring = true
	pickup_area.monitorable = false
	add_child(pickup_area)

	pickup_collision = CollisionShape2D.new()
	_shape = CircleShape2D.new()
	_shape.radius = collision_shape_radius
	pickup_collision.shape = _shape
	pickup_collision.position = collision_offset
	pickup_area.add_child(pickup_collision)

	pickup_collision.debug_color = Color(0, .9, 0, .5)
	pickup_area.collision_layer = 1 << 0
	pickup_area.collision_mask = 1 << radish_layer_bit

	# scale the radius with the pickup buff
	if context:
		context.pickup_radius_mult_changed.connect(
			_on_pickup_radius_mult_changed
		)
		_apply_radius_mult(context.pickup_radius_mult)
	else:
		push_warning(
			"Pickup_Component: context not assigned. "
			+ "Pickup radius upgrades will not apply."
		)


func _on_pickup_radius_mult_changed(mult: float) -> void:
	_apply_radius_mult(mult)


func _apply_radius_mult(mult: float) -> void:
	if _shape:
		_shape.radius = _base_radius * maxf(mult, 0.01)


func get_current_radius() -> float:
	return _shape.radius if _shape else _base_radius


# picks up all pickable radishes currently inside the area
func pickup() -> bool:
	if carry_manager == null:
		push_warning("Pickup_Component: carry_manager not assigned")
		return false

	if not is_instance_valid(pickup_area):
		return false

	var overlaps: Array[Area2D] = (
		pickup_area.get_overlapping_areas()
	)

	if overlaps.is_empty():
		return false

	var radishes := _pickable_radishes_sorted(overlaps)
	var picked_any := false

	for radish in radishes:
		if _do_pickup(radish):
			picked_any = true

	return picked_any


func _do_pickup(radish: Radish) -> bool:
	# revalidate immediately before interacting
	if not _can_pick(radish):
		return false

	var stack_index := carry_manager.get_held_count()
	var old_position := radish.global_position
	var grid_coords := radish.get_grid_coords()

	# first make sure the carry manager accepts the item.
	if not carry_manager.add_carry_item(
		ITEM_RADISH,
		Tony_Context.CarryState.RADISH,
		radish
	):
		return false

	# transfer ownership only after successful registration
	event_bus.radish_picked.emit(
		radish,
		old_position,
		grid_coords
	)

	radish.set_holder(
		parent,
		hold_offset + Vector2(
			0,
			-stack_spacing * stack_index
		)
	)

	return true


func _can_pick(radish) -> bool:
	if not is_instance_valid(radish):
		return false

	if not radish is Radish:
		return false

	if radish.is_queued_for_deletion():
		return false

	if not radish.is_inside_tree():
		return false

	if radish.deposited:
		return false

	if not radish.is_pickable():
		return false

	if carry_manager.is_holding(radish):
		return false

	return true


# all pickable radishes in the overlap list, closest first
func _pickable_radishes_sorted(
	areas: Array
) -> Array[Radish]:
	var result: Array[Radish] = []
	var origin := (
		(parent as Node2D).global_position
		if parent else global_position
	)

	for area in areas:
		if not is_instance_valid(area):
			continue

		var radish = area.get_parent()

		if not _can_pick(radish):
			continue

		if result.has(radish):
			continue

		result.append(radish)

	result.sort_custom(
		func(a: Radish, b: Radish) -> bool:
			return (
				origin.distance_squared_to(a.global_position)
				< origin.distance_squared_to(b.global_position)
			)
	)

	return result


func _nearest_pickable_radish(areas: Array) -> Radish:
	var best: Radish = null
	var best_d2 := INF
	var origin := (
		(parent as Node2D).global_position
		if parent else global_position
	)

	for area in areas:
		if not is_instance_valid(area):
			continue

		var radish = area.get_parent()

		if not _can_pick(radish):
			continue

		var d2 := origin.distance_squared_to(
			radish.global_position
		)

		if d2 < best_d2:
			best_d2 = d2
			best = radish

	return best
