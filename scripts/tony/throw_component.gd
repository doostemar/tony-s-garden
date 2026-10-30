# throw_component.gd
class_name Throw_Component
extends Node2D

@export var carry_manager: Carry_Manager
@export var context: Tony_Context
@export var throw_speed: float = 150.0
@export var base_strength: float = 100.0

# one entry per radish currently in the air
class Thrown_Radish:
	var radish: Radish = null
	var velocity: Vector2 = Vector2.ZERO
	var distance_remaining: float = 0.0

var _throws: Array = []

const DIRECTION_VECTORS = {
	Tony_Context.Direction.UP: Vector2.UP,
	Tony_Context.Direction.DOWN: Vector2.DOWN,
	Tony_Context.Direction.LEFT: Vector2.LEFT,
	Tony_Context.Direction.RIGHT: Vector2.RIGHT
}


func _ready() -> void:
	set_physics_process(false)


# throws exactly one radish from the stack
func throw() -> bool:
	if not carry_manager or not context:
		push_warning("Throw_Component: Missing required references")
		return false

	if carry_manager.is_hand_empty():
		return false

	var radish = carry_manager.take_held_item()

	if not is_instance_valid(radish):
		return false

	if radish.is_queued_for_deletion():
		return false

	var entry := Thrown_Radish.new()
	entry.radish = radish

	var direction = DIRECTION_VECTORS.get(
		context.last_dir,
		Vector2.DOWN
	)

	# thrown from tony's hands, not the top of the stack
	radish.global_position = global_position + direction * 10

	var speed_mult := context.throw_speed_mult

	entry.velocity = direction * (throw_speed * speed_mult)
	entry.distance_remaining = base_strength

	radish.change_state(Radish.RadishState.AIRBORNE)
	radish.set_holder(null)

	_throws.append(entry)
	set_physics_process(true)

	if event_bus.has_signal("radish_thrown"):
		event_bus.radish_thrown.emit(
			radish,
			global_position,
			direction
		)

	return true


func _physics_process(delta: float) -> void:
	# iterate backwards so entries can be removed in place
	for i in range(_throws.size() - 1, -1, -1):
		var entry: Thrown_Radish = _throws[i]

		# untyped to avoid assigning a freed object directly
		# into a typed radish variable
		var radish = entry.radish

		if not is_instance_valid(radish):
			_throws.remove_at(i)
			continue

		if radish.is_queued_for_deletion():
			_throws.remove_at(i)
			continue

		var old_pos: Vector2 = radish.global_position
		var movement: Vector2 = entry.velocity * delta

		radish.global_position += movement
		entry.distance_remaining -= movement.length()

		# swept deposit check
		if _try_deposit_hit(
			radish,
			old_pos,
			radish.global_position
		):
			_throws.remove_at(i)
			continue

		if entry.distance_remaining <= 0:
			_land_radish(radish)
			_throws.remove_at(i)

	if _throws.is_empty():
		set_physics_process(false)


func _try_deposit_hit(
	radish: Radish,
	seg_from: Vector2,
	seg_to: Vector2
) -> bool:
	var r := radish.pickup_collision_radius

	for box in get_tree().get_nodes_in_group("deposit_boxes"):
		if not is_instance_valid(box):
			continue

		var center: Vector2 = box.deposit_area.global_position
		var dr: float = _effective_radius(box.deposit_area)
		var closest := _closest_point_on_segment(
			center,
			seg_from,
			seg_to
		)

		if closest.distance_to(center) <= dr + r:
			box.try_deposit(radish)

			if not is_instance_valid(radish):
				return true

			if radish.is_queued_for_deletion() or radish.deposited:
				return true

	return false


func _effective_radius(area: Area2D) -> float:
	for child in area.get_children():
		if child is CollisionShape2D and child.shape:
			if child.shape is CircleShape2D:
				return child.shape.radius

			if child.shape is RectangleShape2D:
				var s = child.shape.size
				return min(s.x, s.y) * 0.5

	return 8.0


static func _closest_point_on_segment(
	p: Vector2,
	a: Vector2,
	b: Vector2
) -> Vector2:
	var ab := b - a
	var len_sq := ab.length_squared()

	if len_sq < 0.001:
		return a

	var t := clampf(
		(p - a).dot(ab) / len_sq,
		0.0,
		1.0
	)

	return a + ab * t


func _land_radish(radish: Radish) -> void:
	if not is_instance_valid(radish):
		return

	if radish.is_queued_for_deletion():
		return

	radish.change_state(Radish.RadishState.LANDED)

	if event_bus.has_signal("radish_landed_on_ground"):
		event_bus.radish_landed_on_ground.emit(
			radish,
			radish.global_position
		)


# forget all in-flight radishes during a day reset
# Radish_Manager is responsible for destroying the objects
func cancel_all_throws() -> void:
	_throws.clear()
	set_physics_process(false)


# preserve the original method for compatibility
func _end_throw() -> void:
	cancel_all_throws()


func is_throwing() -> bool:
	return not _throws.is_empty()


func get_airborne_count() -> int:
	return _throws.size()


func set_strength(new_strength: float) -> void:
	base_strength = new_strength
