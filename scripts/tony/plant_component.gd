extends Node2D
class_name Plant_Component

@export var dirt_layer_bit: int = 2
@export var collision_offset: Vector2 = Vector2(0, 0)

@export var context: Tony_Context

var parent: Node2D
var plant_area: Area2D
var plant_collision: CollisionShape2D

const EMPTY = -1

var _base_radius: float = 0.0

func init(collision_shape_radius: float) -> void:
	parent = get_parent()
	_base_radius = collision_shape_radius

	plant_area = Area2D.new()
	plant_area.monitoring = true
	plant_area.monitorable = false
	add_child(plant_area)

	plant_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = _base_radius
	plant_collision.shape = shape
	plant_collision.position = collision_offset
	plant_area.add_child(plant_collision)

	plant_collision.debug_color = Color(.9, 0, 0, .5)

	plant_area.collision_layer = 1 << 0
	plant_area.collision_mask  = 1 << dirt_layer_bit

	if context:
		context.plant_radius_mult_changed.connect(_on_plant_radius_mult_changed)
		_apply_radius_from_context()

func plant() -> bool:
	var tiles: Array[Area2D] = plant_area.get_overlapping_areas()
	var empties: Array = []
	for t in tiles:
		if t.has_method("has_radish") and t.has_method("make_plant") and not t.has_radish():
			empties.append(t)
	if empties.is_empty():
		return false
	var origin := (parent as Node2D).global_position if parent else global_position
	empties.sort_custom(func(a, b):
		return origin.distance_squared_to(a.global_position) < origin.distance_squared_to(b.global_position))
	for t in empties:
		t.make_plant()
	return true

func _on_plant_radius_mult_changed(_new_mult: float) -> void:
	_apply_radius_from_context()

func _apply_radius_from_context() -> void:
	if plant_collision == null:
		return
	var shape := plant_collision.shape as CircleShape2D
	if shape == null:
		return

	var mult := 1.0
	if context:
		mult = context.plant_radius_mult

	shape.radius = _base_radius * mult
