extends Node2D
class_name Pickup_Component

@export var dirt_layer_bit: int = 2
@export var collision_offset: Vector2 = Vector2(0, 0)

@export var carry_manager: Carry_Manager

var parent: Node2D
var pickup_area: Area2D
var pickup_collision: CollisionShape2D

const ADULT = 2
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
	pickup_area.collision_mask  = 1 << dirt_layer_bit

func pickup() -> bool:
	if carry_manager == null:
		push_warning("Pickup_Component: carry_manager is not assigned")
		return false

	if not carry_manager.is_hand_empty():
		return false

	var tiles: Array[Area2D] = pickup_area.get_overlapping_areas()
	if tiles.is_empty():
		return false

	var target := _nearest_tile_with_state(tiles, ADULT)
	if target:
		return _do_harvest(target)
	return false

func _do_harvest(tile: Node) -> bool:
	if not tile.has_method("pick_radish"):
		push_warning("Pickup_Component: target is missing pick_radish")
		return false

	var radish = tile.pick_radish()
	if radish:
		carry_manager.set_carry_item(ITEM_RADISH, Tony_Context.CarryState.RADISH, radish)
		return true
	return false

func _nearest_tile_with_state(tiles: Array, desired_state: int) -> Node:
	var best: Node = null
	var best_d2 := INF
	var origin := (parent as Node2D).global_position if parent else global_position
	for t in tiles:
		if not t.has_method("get_radish_state"):
			continue
		if t.get_radish_state() != desired_state:
			continue
		var d2 := origin.distance_squared_to(t.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = t
	return best
