class_name Rabbit_Chew_State
extends Rabbit_State

@export_group("Transitions")
@export var chase_state: Rabbit_State
@export var idle_state: Rabbit_State

@export_group("Chewing")
@export var chew_duration: float = 3.0

var _chew_timer: float = 0.0
var _chewed_radish: Radish


func enter() -> void:
	rabbit.velocity = Vector2.ZERO

	_chewed_radish = targeting.get_target()

	if not is_instance_valid(_chewed_radish):
		return

	_chewed_radish.pause_growth()
	_chew_timer = chew_duration


func exit() -> void:
	if is_instance_valid(_chewed_radish):
		_chewed_radish.resume_growth()

	_chewed_radish = null
	_chew_timer = 0.0


func process_physics(
	delta: float
) -> Rabbit_State:
	if not targeting.is_target_valid():
		_abandon_target()

		if targeting.acquire_random_sprout():
			return chase_state

		return idle_state

	_chew_timer -= delta

	if _chew_timer > 0.0:
		return null

	_eat_target()

	if targeting.acquire_random_sprout():
		return chase_state

	return idle_state


func _abandon_target() -> void:
	if is_instance_valid(_chewed_radish):
		_chewed_radish.resume_growth()

	_chewed_radish = null
	_chew_timer = 0.0

	targeting.release_target()


func _eat_target() -> void:
	var radish := targeting.get_target()

	targeting.release_target()

	# don't resume growth when the radish
	# has actually been eaten
	_chewed_radish = null
	_chew_timer = 0.0

	event_bus.emit_signal(
		"animal_stealing",
		rabbit
	)

	if targeting.context:
		targeting.context.forget_radish(
			radish
		)

	event_bus.emit_signal(
		"radish_destroy_requested",
		radish
	)
