class_name Rabbit_Chase_State
extends Rabbit_State

@export_group("Transitions")
@export var chew_state: Rabbit_State
@export var idle_state: Rabbit_State

@export_group("Movement")
@export var chase_speed: float = 30.0

@export_group("Chase Deviation")
@export_range(0.0, 89.0)
var deviation_max_degrees: float = 25.0

@export var deviation_interval: float = 0.4
@export var deviation_fade_distance: float = 24.0

@export_group("Chewing")
@export var chew_distance: float = 6.0

var _deviation_angle: float = 0.0
var _deviation_timer: float = 0.0


func enter() -> void:
	_deviation_timer = 0.0
	_deviation_angle = 0.0


func process_physics(
	delta: float
) -> Rabbit_State:
	if not targeting.is_target_valid():
		targeting.release_target()

		if targeting.acquire_random_sprout():
			return self

		return idle_state

	var target := targeting.get_target()

	var to_target := (
		target.global_position
		- rabbit.global_position
	)

	var distance := to_target.length()

	if distance <= chew_distance:
		return chew_state

	_update_deviation(
		delta,
		distance
	)

	var direction := (
		to_target.normalized()
		.rotated(_deviation_angle)
	)

	rabbit.velocity = (
		direction
		* chase_speed
	)

	rabbit.move_and_slide()

	return null


func _update_deviation(
	delta: float,
	distance: float
) -> void:
	_deviation_timer -= delta

	if _deviation_timer <= 0.0:
		_deviation_timer = deviation_interval

		_deviation_angle = deg_to_rad(
			randf_range(
				-deviation_max_degrees,
				deviation_max_degrees
			)
		)

	var fade := clampf(
		(distance - chew_distance)
		/ maxf(
			deviation_fade_distance,
			0.001
		),
		0.0,
		1.0
	)

	_deviation_angle *= fade
