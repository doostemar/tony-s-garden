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
	_throw_velocity = direction * throw_speed
	_throw_distance_remaining = base_strength

	_thrown_radish.global_position = global_position + Vector2(0, -10)

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

	var movement = _throw_velocity * delta
	_thrown_radish.global_position += movement

	_throw_distance_remaining -= movement.length()

	if _throw_distance_remaining <= 0:
		_land_radish()

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
