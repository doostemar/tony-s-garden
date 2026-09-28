# rabbit_flee_state.gd
class_name Rabbit_Flee_State
extends Rabbit_State

@export_group("Movement")
@export var flee_speed: float = 60.0

@export_group("Fleeing")
@export var flee_margin: float = 16.0
@export var flee_arrival_distance: float = 2.0

var _flee_point: Vector2


func enter() -> void:
	var released := targeting.release_target()

	rabbit.velocity = Vector2.ZERO

	if rabbit.garden_bounds and rabbit.garden_bounds.is_valid():
		_flee_point = rabbit.garden_bounds.get_exit_point(
			rabbit.global_position,
			flee_margin
		)
	else:
		_flee_point = rabbit.global_position

	rabbit.offer_to_idle_rabbit(released)


func process_physics(_delta: float) -> Rabbit_State:
	var to_exit := _flee_point - rabbit.global_position

	if to_exit.length() <= flee_arrival_distance:
		_despawn()
		return null

	rabbit.velocity = to_exit.normalized() * flee_speed

	rabbit.move_and_slide()

	return null


func _despawn() -> void:
	event_bus.emit_signal("animal_despawned", rabbit)

	rabbit.queue_free()
