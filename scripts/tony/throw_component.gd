class_name Throw_Component
extends Node2D

@export var carry_manager: Carry_Manager
@export var context: Tony_Context
@export var throw_speed: float = 150.0
@export var base_strength: float = 100.0

var _thrown_radish: Radish = null
var _throw_velocity: Vector2 = Vector2.ZERO
var _throw_distance_remaining: float = 0.0

const DIRECTION_VECTORS = {
	Tony_Context.Direction.UP: Vector2.UP,
	Tony_Context.Direction.DOWN: Vector2.DOWN,
	Tony_Context.Direction.LEFT: Vector2.LEFT,
	Tony_Context.Direction.RIGHT: Vector2.RIGHT
}

func _ready() -> void:
	set_physics_process(false)

func throw() -> bool:
	if not carry_manager or not context:
		push_warning("Throw_Component: Missing required references")
		return false

	if carry_manager.is_hand_empty():
		return false

	var radish = carry_manager.get_held_item()
	if not radish or not is_instance_valid(radish):
		return false

	carry_manager.clear_hand()
	_thrown_radish = radish

	var direction = DIRECTION_VECTORS.get(context.last_dir, Vector2.DOWN)
	_thrown_radish.global_position = global_position + direction * 10  # was Vector2(0, -10)

	var speed_mult := context.throw_speed_mult if context else 1.0
	_throw_velocity = direction * (throw_speed * speed_mult)

	_throw_distance_remaining = base_strength

	_thrown_radish.change_state(Radish.RadishState.AIRBORNE)
	_thrown_radish.set_holder(null)

	set_physics_process(true)

	if event_bus.has_signal("radish_thrown"):
		event_bus.radish_thrown.emit(_thrown_radish, global_position, direction)

	return true

func _physics_process(delta: float) -> void:
	if not _thrown_radish or not is_instance_valid(_thrown_radish):
		_end_throw()
		return

	var old_pos  := _thrown_radish.global_position
	var movement := _throw_velocity * delta
	_thrown_radish.global_position += movement
	_throw_distance_remaining -= movement.length()

	# Swept deposit check — runs *before* the physics server gets a chance
	if _try_deposit_hit(old_pos, _thrown_radish.global_position):
		return

	if _throw_distance_remaining <= 0:
		_land_radish()

func _try_deposit_hit(seg_from: Vector2, seg_to: Vector2) -> bool:
	var r := _thrown_radish.pickup_collision_radius
	for box in get_tree().get_nodes_in_group("deposit_boxes"):
		var center  : Vector2 = box.deposit_area.global_position
		var dr      : float   = _effective_radius(box.deposit_area)
		var closest := _closest_point_on_segment(center, seg_from, seg_to)
		if closest.distance_to(center) <= dr + r:
			box.try_deposit(_thrown_radish)
			if not is_instance_valid(_thrown_radish) or _thrown_radish.deposited:
				_end_throw()
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
	return 8.0   # safe fallback


static func _closest_point_on_segment(
		p: Vector2, a: Vector2, b: Vector2) -> Vector2:
	var ab     := b - a
	var len_sq := ab.length_squared()
	if len_sq < 0.001:
		return a
	var t := clampf((p - a).dot(ab) / len_sq, 0.0, 1.0)
	return a + ab * t
	
func _land_radish() -> void:
	if not _thrown_radish:
		_end_throw()
		return

	_thrown_radish.change_state(Radish.RadishState.LANDED)

	if event_bus.has_signal("radish_landed_on_ground"):
		event_bus.radish_landed_on_ground.emit(_thrown_radish, _thrown_radish.global_position)

	_end_throw()

func _end_throw() -> void:
	_thrown_radish = null
	_throw_velocity = Vector2.ZERO
	_throw_distance_remaining = 0.0
	set_physics_process(false)

func is_throwing() -> bool:
	return _thrown_radish != null

func set_strength(new_strength: float) -> void:
	base_strength = new_strength
