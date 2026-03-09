extends Node2D
class_name Pickup_Component

@export var radish_layer_bit: int = 3
@export var collision_offset: Vector2 = Vector2(0, 0)
@export var carry_manager: Carry_Manager

var parent: Node2D
var pickup_area: Area2D
var pickup_collision: CollisionShape2D

const ITEM_RADISH: StringName = &"radish"

func init(collision_shape_radius: float) -> void:
	parent = get_parent()

	pickup_area = Area2D.new()
	pickup_area.monitoring = true
	pickup_area.monitorable = false
	add_child(pickup_area)

	pickup_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = collision_shape_radius
	pickup_collision.shape = shape
	pickup_collision.position = collision_offset
	pickup_area.add_child(pickup_collision)

	pickup_collision.debug_color = Color(0, .9, 0, .5)

	pickup_area.collision_layer = 1 << 0
	pickup_area.collision_mask  = 1 << radish_layer_bit

func pickup() -> bool:
	if carry_manager == null:
		push_warning("Pickup_Component: carry_manager not assigned")
		return false

	if not carry_manager.is_hand_empty():
		return false

	var overlaps: Array[Area2D] = pickup_area.get_overlapping_areas()
	if overlaps.is_empty():
		return false

	var radish := _nearest_pickable_radish(overlaps)
	if radish:
		return _do_pickup(radish)
	return false

func _do_pickup(radish: Radish) -> bool:
	event_bus.radish_picked.emit(radish, radish.global_position, radish.get_grid_coords())
	radish.set_holder( parent, Vector2(0, -10) )
	carry_manager.set_carry_item(ITEM_RADISH, Tony_Context.CarryState.RADISH, radish)
	return true

func _nearest_pickable_radish(areas: Array) -> Radish:
	var best: Radish = null
	var best_d2 := INF
	var origin := (parent as Node2D).global_position if parent else global_position
	for area in areas:
		var radish = area.get_parent()
		if not radish is Radish:
			continue
		if not radish.is_pickable():
			continue
		var d2 := origin.distance_squared_to(radish.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = radish
	return best
