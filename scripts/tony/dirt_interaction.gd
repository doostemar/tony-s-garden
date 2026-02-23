# dirt_interaction.gd
extends Node2D
class_name Dirt_Interaction

@export var dirt_layer_bit: int = 2
@export var collision_offset: Vector2 = Vector2(0, 0)

@export var carry_manager: Carry_Manager
@export var context: Tony_Context # for asserts/logs?

var parent: Node2D
var planting_area: Area2D
var planting_collision: CollisionShape2D

const EMPTY = -1
const ADULT = 2

const ITEM_RADISH: StringName = &"radish"

func init(collision_shape_radius: float) -> void:
	parent = get_parent()

	planting_area = Area2D.new()
	planting_area.monitoring = true
	planting_area.monitorable = false
	add_child(planting_area)

	planting_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = collision_shape_radius
	planting_collision.shape = shape
	planting_collision.position = collision_offset
	planting_area.add_child(planting_collision)

	planting_collision.debug_color = Color(.9, 0 , 0, .5)

	planting_area.collision_layer = 1 << 0
	planting_area.collision_mask  = 1 << dirt_layer_bit

func interact() -> void:
	# defer so overlaps are up-to-date this frame
	call_deferred("_do_action")

func _do_action() -> void:
	if carry_manager == null:
		push_warning("Dirt_Interaction: carry_manager is not assigned")
		return
	
	if not carry_manager.is_hand_empty():
		return
	
	var tiles: Array[Area2D] = planting_area.get_overlapping_areas()
	if tiles.is_empty():
		return
	
	# we check plant, then we check harvest
	# this might not be optimal, we might want to just check any
	var target_empty := _nearest_tile_with_state(tiles, EMPTY)
	if target_empty:
		_do_plant(target_empty)
		return
	
	var target_adult := _nearest_tile_with_state(tiles, ADULT)
	if target_adult:
		_do_harvest(target_adult)
		return
	# else, no action

func _do_plant(tile: Node) -> void:
	if not tile.has_method("make_plant"):
		push_warning("dirt script is missing make_plant")
		return
	tile.make_plant()

func _do_harvest(tile: Node) -> void:
	if not tile.has_method("pick_radish"): # Changed from remove_radish
		push_warning("dirt script is missing pick_radish")
		return

	var radish = tile.pick_radish() # Changed from remove_radish
	if radish:
		carry_manager.set_carry_item( ITEM_RADISH, Tony_Context.CarryState.RADISH, radish )
		# Store reference to the actual radish object for throwing
		# You'll need to add this to carry_manager or tony


# finds the closest tile with the state that we want (called in _do_action)
# uses distance_squared_to because it's cheaper for comparing distances than
# distance_to which uses sqare roots
func _nearest_tile_with_state(tiles: Array, desired_state: int) -> Node:
	var best: Node = null
	var best_d2 := INF
	var origin := ( parent as Node2D ).global_position if parent else global_position
	for t in tiles:
		if not t.has_method("get_radish_state"):
			continue
		if t.get_radish_state() != desired_state:
			continue
		# distance sqrd is cheaper than sqrt
		var d2 := origin.distance_squared_to(t.global_position)
		if d2 < best_d2:
			best_d2 = d2
			best = t
	return best
