# box_deposit.gd
class_name Box_Deposit
extends Node2D

@export var box_layer_bit: int = 3
@export var collision_offset: Vector2 = Vector2(0, 0)

@export var carry_manager: Carry_Manager
@export var context: Tony_Context # for asserts/logs?

var deposit_area: Area2D
var deposit_collision: CollisionShape2D

func init(deposit_collision_radius: float):
	
	deposit_area = Area2D.new()
	deposit_area.monitoring = true
	deposit_area.monitorable = true
	add_child(deposit_area)

	deposit_collision = CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = deposit_collision_radius
	deposit_collision.shape = shape
	deposit_collision.position = collision_offset
	deposit_area.add_child(deposit_collision)
	
	deposit_collision.debug_color = Color(0, 0, 0.9, .5)

	deposit_area.collision_layer = 1 << 0
	deposit_area.collision_mask  = 1 << box_layer_bit
	
func interact() -> bool:
	var bodies: Array[Node2D] = deposit_area.get_overlapping_bodies()
	print("Overlapping bodies: ", bodies.size())
	
	if !bodies.is_empty():
		print("found the box!")
		carry_manager.clear_hand()
		event_bus.harvested.emit(1)
		return true
	return false
