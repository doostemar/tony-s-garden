# rabbit_idle_state.gd
class_name Rabbit_Idle_State
extends Rabbit_State

@export_group("Transitions")
@export var chase_state: Rabbit_State

@export_group("Movement")
@export var idle_speed: float = 10.0

@export_group("Idle")
@export var idle_wander_radius: float = 24.0
@export var idle_arrival_distance: float = 2.0
@export var idle_pause_min: float = 0.5
@export var idle_pause_max: float = 2.0
@export var idle_bounds_inset: float = 4.0

var _anchor: Vector2
var _destination: Vector2
var _has_destination: bool = false
var _pause_timer: float = 0.0


func enter() -> void:
	rabbit.velocity = Vector2.ZERO

	_anchor = rabbit.global_position

	if rabbit.garden_bounds and rabbit.garden_bounds.is_valid():
		_anchor = rabbit.garden_bounds.clamp_inside(
			rabbit.global_position,
			idle_bounds_inset
		)

	_has_destination = false

	_pause_timer = randf_range(idle_pause_min, idle_pause_max)


func process_physics(delta: float) -> Rabbit_State:
	# this also acts as the fallback scan if the
	# radish_sprouted signal isn't what claimed
	# the target
	if targeting.get_target():
		if targeting.is_target_valid():
			return chase_state

		targeting.release_target()

	if targeting.acquire_random_sprout():
		return chase_state

	if _pause_timer > 0.0:
		_pause_timer -= delta
		rabbit.velocity = Vector2.ZERO
		return null

	if not _has_destination:
		_pick_destination()

	var to_destination := _destination - rabbit.global_position

	if to_destination.length() <= idle_arrival_distance:
		_has_destination = false

		_pause_timer = randf_range(idle_pause_min, idle_pause_max)

		rabbit.velocity = Vector2.ZERO
		return null

	rabbit.velocity = to_destination.normalized() * idle_speed

	rabbit.move_and_slide()

	return null


func try_claim_sprout(radish: Radish) -> bool:
	if not targeting.is_sprout_available(radish, targeting.get_other_rabbits()):
		return false

	targeting.set_target(radish)
	return true


func _pick_destination() -> void:
	var offset := Vector2.from_angle(randf() * TAU) * randf_range(
		idle_wander_radius * 0.25,
		idle_wander_radius
	)

	var destination := _anchor + offset

	if rabbit.garden_bounds and rabbit.garden_bounds.is_valid():
		destination = rabbit.garden_bounds.clamp_inside(
			destination,
			idle_bounds_inset
		)

	_destination = destination
	_has_destination = true
